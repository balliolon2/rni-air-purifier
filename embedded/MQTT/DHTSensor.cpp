#include "DHTSensor.h"
#include "DHT.h"

// กำหนดขาที่ต่อกับเซนเซอร์และประเภทของเซนเซอร์
#define DHTPIN 19     // Pin connected to the DHT sensor's DATA pin
#define DHTTYPE DHT22 // DHT 22 (AM2302)

// สร้างออบเจกต์ dht เพื่อเรียกใช้งาน
DHT dht(DHTPIN, DHTTYPE);

void initDHTSensor() {
  Serial.println("Starting DHT22 test...");

  // เริ่มต้นการทำงานของเซนเซอร์ DHT
  dht.begin();
}

float readHumidity() {
  // อ่านค่าความชื้น (Humidity)
  float h = dht.readHumidity();

  // ตรวจสอบว่าเซนเซอร์อ่านค่าสำเร็จหรือไม่
  if (isnan(h)) {
    Serial.println("Failed to read humidity from DHT sensor!");
    return 0.0;
  }

  Serial.print("Humidity: ");
  Serial.print(h);
  Serial.print(" %  |  ");

  return h;
}

float readTemperature() {
  // อ่านค่าอุณหภูมิในหน่วยเซลเซียส (Temperature)
  float t = dht.readTemperature();

  // ตรวจสอบว่าเซนเซอร์อ่านค่าสำเร็จหรือไม่
  if (isnan(t)) {
    Serial.println("Failed to read temperature from DHT sensor!");
    return 0.0;
  }

  Serial.print("Temperature: ");
  Serial.print(t);
  Serial.println(" °C");

  return t;
}
