#pragma once
#include <stdint.h>

#define TRACK_COUNT 7

// Continuity check pins (LOW = connected to GND)
static const uint8_t TRACK_PINS[TRACK_COUNT] = {
    1, // IO1
    4, // IO4
    6, // IO6
    5, // IO5
    3, // IO3
    2, // IO2
    21 // IO21
};
        