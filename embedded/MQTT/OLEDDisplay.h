#ifndef OLED_DISPLAY_H
#define OLED_DISPLAY_H

#include <Arduino.h>

// เริ่มต้นการทำงานของจอ OLED
void initOLEDDisplay();

// ฟังก์ชันสำหรับอัปเดตข้อมูลขึ้นหน้าจอ
void updateDisplay(float dustDensity, float temp, float hum,
                   bool isBtConnected);

#endif
