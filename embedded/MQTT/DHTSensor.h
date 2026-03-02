#ifndef DHT_SENSOR_H
#define DHT_SENSOR_H

#include <Arduino.h>

// เริ่มต้นการทำงานของเซนเซอร์ DHT22
void initDHTSensor();

// อ่านค่าความชื้น (Humidity)
float readHumidity();

// อ่านค่าอุณหภูมิในหน่วยเซลเซียส (Temperature)
float readTemperature();

#endif
