#include "RelayControl.h"

// กำหนดขาที่ต่อกับพิน IN ของ Relay
#define RELAY_PIN 33

void initRelay() {
  // ตั้งค่าให้ขา 27 เป็น OUTPUT เพื่อส่งสัญญาณไฟออกไป
  pinMode(RELAY_PIN, OUTPUT);

  // โมดูล Relay ส่วนใหญ่ทำงานแบบ Active Low (ส่ง LOW = ทำงาน, ส่ง HIGH = หยุดทำงาน)
  // ตั้งค่าเริ่มต้นให้มัน "ปิด" ไว้ก่อน
  digitalWrite(RELAY_PIN, HIGH);
  Serial.println("Relay initialized (OFF).");
}

void turnOnRelay() {
  digitalWrite(RELAY_PIN, LOW);
  Serial.println("Relay: ON");
}

void turnOffRelay() {
  digitalWrite(RELAY_PIN, HIGH);
  Serial.println("Relay: OFF");
}

void toggleRelay() {
  // สลับสถานะของ Relay โดยจำสถานะเดิมไว้
  static bool isRelayOn = false;

  if (isRelayOn) {
    turnOffRelay();
    isRelayOn = false;
  } else {
    turnOnRelay();
    isRelayOn = true;
  }
}
