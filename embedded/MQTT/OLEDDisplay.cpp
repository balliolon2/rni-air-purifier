#include "OLEDDisplay.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

#define SCREEN_WIDTH 128 // ความกว้างจอ OLED (พิกเซล)
#define SCREEN_HEIGHT 64 // ความสูงจอ OLED (พิกเซล)

// กำหนดขา Reset เป็น -1 (สำหรับจอแบบ 4 ขาที่ไม่มีขา Reset)
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

void initOLEDDisplay() {
  // เริ่มต้นการเชื่อมต่อจอ OLED (Address 0x3C เป็นค่ามาตรฐานของจอส่วนใหญ่)
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("OLED initialization failed! กรุณาเช็กสาย SDA/SCL"));
    for (;;)
      ; // ถ้าหาจอไม่เจอ ให้โปรแกรมหยุดทำงานตรงนี้
  }

  // ล้างหน้าจอให้ว่าง และตั้งค่าสีข้อความเป็นสีขาว
  display.clearDisplay();
  display.setTextColor(WHITE);
  display.display();
  Serial.println("OLED is Ready!");
}

void updateDisplay(float dustDensity, float temp, float hum,
                   bool isBtConnected) {
  display.clearDisplay(); // ล้างข้อมูลเก่าทิ้งก่อนวาดใหม่

  // 1. แสดงสถานะ Bluetooth (บรรทัดบนสุด)
  display.setTextSize(1);
  display.setCursor(0, 0);
  if (isBtConnected) {
    display.print("BT : CONNECTED");
  } else {
    display.print("BT : DISCONNECTED");
  }
  // วาดเส้นคั่นบางๆ ด้านล่างแถบ Bluetooth
  display.drawLine(0, 10, 128, 10, WHITE);

  // 2. แสดงค่าฝุ่น PM2.5 (เน้นตัวใหญ่ให้อ่านง่าย)
  display.setCursor(0, 16);
  display.setTextSize(1);
  display.print("PM2.5: ");
  display.setTextSize(2);        // ขยายฟอนต์เป็นขนาด 2
  display.print(dustDensity, 1); // แสดงทศนิยม 1 ตำแหน่ง
  display.setTextSize(1);
  display.print(" ug/m3");

  // 3. แสดงอุณหภูมิและความชื้น (บรรทัดล่างสุด แบ่งเป็น 2 บรรทัดย่อย)
  display.setCursor(0, 40);
  display.setTextSize(1);
  display.print("Temp: ");
  display.print(temp, 1);
  display.print(" C");

  display.setCursor(0, 52);
  display.print("Hum : ");
  display.print(hum, 1);
  display.print(" %");

  // สั่งให้ข้อมูลทั้งหมดแสดงผลออกทางหน้าจอ
  display.display();
}
