#ifndef RELAY_CONTROL_H
#define RELAY_CONTROL_H

#include <Arduino.h>

// เริ่มต้นการทำงานของ Relay
void initRelay();

// สั่งให้ Relay ทำงาน (พัดลมหมุน)
void turnOnRelay();

// สั่งให้ Relay หยุดทำงาน (พัดลมดับ)
void turnOffRelay();

// สลับสถานะ Relay (เปิด/ปิด สลับกัน)
void toggleRelay();

#endif
