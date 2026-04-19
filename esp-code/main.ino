#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClient.h>
#include <Wire.h>
#include <Adafruit_MAX1704X.h>
#include <esp_sleep.h>
#include "mbedtls/base64.h"

#include "config.h"
#include "gpioinfo.h"
#include "crypto.h"

RTC_DATA_ATTR uint32_t boot_count = 0;
RTC_DATA_ATTR uint32_t report_interval = 10;

Adafruit_MAX17048 maxlipo;

// BATTERY PACK PARAMETERS (4x NCR18650B parallel)
#define PACK_USABLE_AH 10.0
#define PACK_NOMINAL_VOLTAGE 3.7

// Basic XOR encryption
void xorEncrypt(uint8_t *data, size_t len)
{
    for (size_t i = 0; i < len; i++)
    {
        data[i] ^= XOR_KEY[i % XOR_KEY_LEN];
    }
}

// Go to sleep code
void sleepSeconds(uint32_t sec)
{
    WiFi.disconnect(true);
    WiFi.mode(WIFI_OFF);
    esp_sleep_enable_timer_wakeup((uint64_t)sec * 1000000ULL); // sleep timer
    esp_deep_sleep_start();
}

// take the pins from the header file and iterate through them checking connectivity wrt to gnd
uint8_t readTracks()
{
    uint8_t mask = 0;
    for (int i = 0; i < TRACK_COUNT; i++)
    {
        pinMode(TRACK_PINS[i], INPUT_PULLUP); // int pullup
        if (digitalRead(TRACK_PINS[i]) == LOW)
        {                     // low = gnd
            mask |= (1 << i); // binary bit mask
        }
    }
    return mask;
}

bool readBattery(float &vbat, float &soc, float &energyWh)
{                 // default code from the library
    Wire.begin(); // i2c

    if (!maxlipo.begin())
    { // Fuel Gauge missing
        return false;
    }
    delay(200);
    maxlipo.quickStart();
    delay(200);
    vbat = maxlipo.cellVoltage();
    soc = maxlipo.cellPercent();

    if (soc > 100)
        soc = 100;
    if (soc < 0)
        soc = 0;

    if (vbat < 2.5 || vbat > 4.3)
    { // battery voltage out of range handler
        return false;
    }

    float remainingAh = (soc / 100.0) * PACK_USABLE_AH; // math
    energyWh = remainingAh * PACK_NOMINAL_VOLTAGE;

    return true;
}

void setup()
{
    Serial.begin(115200);
    delay(300);

    boot_count++;
    bool ack_received = false;

    // Battery code
    float vbat = 0, soc = 0, energyWh = 0;
    if (!readBattery(vbat, soc, energyWh))
    {
        vbat = 0;
        soc = 0;
        energyWh = 0;
    }
    // Tracks continuity check
    uint8_t tracks = readTracks();

    // WiFi connection
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    uint32_t wifi_start = millis();
    while (WiFi.status() != WL_CONNECTED)
    {
        if (millis() - wifi_start > 10000)
        {
            sleepSeconds(30); // sleep for 30 seconds then try again to connect to the network
        }
        delay(250);
    }
    Serial.println(WiFi.localIP()); // ip for debugging

    // Master JSON to be sent to the pi
    char json[256];
    snprintf(json, sizeof(json),
             "{\"type\":\"data\",\"id\":\"%s\",\"boot\":%lu,"
             "\"tracks\":%u,\"vbat\":%.3f,\"soc\":%.1f,\"wh\":%.2f}",
             NODE_ID, boot_count, tracks, vbat, soc, energyWh);

    size_t json_len = strlen(json);
    xorEncrypt((uint8_t *)json, json_len); // XOR encryption

    uint8_t b64[512];
    size_t b64_len = 0;
    mbedtls_base64_encode(b64, sizeof(b64), &b64_len, (uint8_t *)json, json_len); // base 64 encryption layer

    // TCP client setup
    WiFiClient client;
    if (!client.connect(SERVER_IP, SERVER_PORT))
    {                     // try connection to server
        sleepSeconds(30); // fall back to 30 sec sleep if error
    }

    client.print("{\"type\":\"cfg\"}\n"); // server side debugging
    client.flush();

    uint32_t cfg_start = millis();
    while (millis() - cfg_start < 3000)
    {
        if (client.available())
        {
            String line = client.readStringUntil('\n');
            int interval;
            if (sscanf(line.c_str(), "{\"interval\":%d}", &interval) == 1)
            { // get sleep interval from the server
                report_interval = interval;
            }
            break;
        }
    }

    client.write(b64, b64_len); // XOR + Base 64 encrypted data
    client.write('\n');
    client.flush();

    uint32_t ack_start = millis();
    while (millis() - ack_start < 7000)
    {
        if (client.available())
        {
            String line = client.readStringUntil('\n');
            if (line.indexOf("\"ack\":1") >= 0)
            { // get acknowledged from server that the data has been stored
                ack_received = true;
            }
            break;
        }
    }

    client.stop();
    WiFi.disconnect(true);
    WiFi.mode(WIFI_OFF); // turn off wifi save power

    if (!ack_received)
    {
        sleepSeconds(30); // acknowledgement fallback
    }

    esp_sleep_enable_timer_wakeup((uint64_t)report_interval * 1000000ULL); // Deep sleep timer
    esp_deep_sleep_start();
}

void loop() {}
