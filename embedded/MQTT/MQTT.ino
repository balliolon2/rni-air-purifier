#include "DHTSensor.h"
#include "DustSensor.h"
#include "OLEDDisplay.h"
#include "RelayControl.h"
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <stdlib.h>

#define DEVICE_NAME "ESP32_BT"
#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" // Device UUID
#define CHARACTERISTIC_UUID_RX                                                 \
  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" // Read PM2.5 Characteristic
#define CHARACTERISTIC_UUID_TX                                                 \
  "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" // Write PM2.5 Characteristic

BLEServer *pServer = NULL;
BLECharacteristic *pTxCharacteristic;

bool deviceConnected = false;
bool wasConnected = false; // ← Track previous state

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("Client connected!");
  }
  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("Client disconnected. Restarting advertising...");
  }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue();
    if (rxValue.length() > 0) {
      Serial.print("Received: ");
      Serial.println(rxValue.c_str());

      // ตรวจสอบคำสั่งเพื่อควบคุม Relay
      if (rxValue == "ON") {
        turnOnRelay();
      } else if (rxValue == "OFF") {
        turnOffRelay();
      }
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Init BLE with your device name
  BLEDevice::init(DEVICE_NAME);

  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create BLE UART Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // TX Characteristic (ESP32 → Flutter)
  pTxCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
  pTxCharacteristic->addDescriptor(new BLE2902());

  // RX Characteristic (Flutter → ESP32)
  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE);
  pRxCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pServer->getAdvertising()->start();
  Serial.println("BLE UART ready! Waiting for connections...");

  // Initialize Dust Sensor
  initDustSensor();

  // Initialize DHT Sensor
  initDHTSensor();

  // Initialize OLED Display
  initOLEDDisplay();

  // Initialize Relay
  initRelay();
}

void loop() {
  // Device just disconnected — restart advertising
  if (!deviceConnected && wasConnected) {
    delay(500); // Give BLE stack time to settle
    pServer->startAdvertising();
    Serial.println("Restarting advertising...");
    wasConnected = false;
  }

  // Device just connected
  if (deviceConnected && !wasConnected) {
    wasConnected = true;
  }

  // Read sensor values
  float currentDust = readDustDensity();
  float currentTemp = readTemperature();
  float currentHum = readHumidity();

  if (deviceConnected) {
    // Create a message payload (e.g., comma separated: dust,temp,humidity)
    String msg = String(currentDust) + "," + String(currentTemp) + "," +
                 String(currentHum);
    pTxCharacteristic->setValue(msg.c_str());
    pTxCharacteristic->notify();
  }

  // Update OLED display
  updateDisplay(currentDust, currentTemp, currentHum, deviceConnected);

  // ทดสอบเปิด-ปิด Relay สลับกันทุกรอบการทำงาน
  toggleRelay();

  // เซนเซอร์ DHT22 ทำงานค่อนข้างช้า ควรหน่วงเวลาอย่างน้อย 2 วินาที (2000 ms)
  // แต่ปรับเป็น 500ms ตามที่ต้องการทดสอบ Relay
  delay(500);
}