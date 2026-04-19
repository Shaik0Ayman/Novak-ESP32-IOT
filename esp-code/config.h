#pragma once

// WiFi Configuration
#define WIFI_SSID "Novak"
#define WIFI_PASS "test1234"

// TCP Server Configuration (Pi server address)
#define SERVER_IP "10.101.185.243"
#define SERVER_PORT 5001

// Node Identification
#define NODE_ID "node_02"
#define FW_VERSION "v2.0"

// Sleep Interval Settings (seconds)
#define MIN_INTERVAL_SEC 5
#define MAX_INTERVAL_SEC 86400
#define DEFAULT_INTERVAL_SEC 10 // Match server config.json
