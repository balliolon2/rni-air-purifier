#ifndef DUST_SENSOR_H
#define DUST_SENSOR_H

#include <Arduino.h>

// Initialize the dust sensor (setup pins)
void initDustSensor();

// Read and calculate dust density
float readDustDensity();

#endif
