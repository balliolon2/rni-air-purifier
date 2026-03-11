#include "RelayControl.h"

// กำหนดขาที่ต่อกับพิน IN ของ Relay
#define RELAY_PIN 33

bool isRelayOn = false;

void initRelay() {
  // ตั้งค่าให้ขา 27 เป็น OUTPUT เพื่อส่งสัญญาณไฟออกไป

  // โมดูล Relay ส่วนใหญ่ทำงานแบบ Active Low (ส่ง LOW = ทำงาน, ส่ง HIGH = หยุดทำงาน)
  // ตั้งค่าเริ่มต้นให้มัน "ปิด" ไว้ก่อน
  digitalWrite(RELAY_PIN, HIGH);

  pinMode(RELAY_PIN, OUTPUT);

  Serial.println("Relay initialized (OFF).");
}

void turnOnRelay() {
  if (!isRelayOn) {
    digitalWrite(RELAY_PIN, LOW);
    Serial.println("Relay: ON");
    isRelayOn = true;
  }
}

void turnOffRelay() {
  if (isRelayOn) {
    digitalWrite(RELAY_PIN, HIGH);
    Serial.println("Relay: OFF");
    isRelayOn = false;
  }
}

bool toggleRelay() {
  // สลับสถานะของ Relay
  if (isRelayOn) {
    turnOffRelay();
  } else {
    turnOnRelay();
  }
  return isRelayOn;
}
