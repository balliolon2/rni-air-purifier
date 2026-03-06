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
#define SERVICE_UUID \
  "6e400001-b5a3-f393-e0a9-e50e24dcca9e" // Device UUID
#define CHARACTERISTIC_UUID_RX \
  "6e400002-b5a3-f393-e0a9-e50e24dcca9e" // Read
#define CHARACTERISTIC_UUID_DUST \
  "6e400003-b5a3-f393-e0a9-e50e24dcca9e" // Write Dust
#define CHARACTERISTIC_UUID_TEMP \
  "6e400004-b5a3-f393-e0a9-e50e24dcca9e" // Write temperature
#define CHARACTERISTIC_UUID_HUM \
  "6e400005-b5a3-f393-e0a9-e50e24dcca9e" // Write Humidity
#define CHARACTERISTIC_UUID_RESPONSE \
  "6e400006-b5a3-f393-e0a9-e50e24dcca9e" // Write Flutter ACK response

BLEServer *pServer = NULL;
BLECharacteristic* pDustCharacteristic;
BLECharacteristic* pTempCharacteristic;
BLECharacteristic* pHumCharacteristic;
BLECharacteristic* pResponseCharacteristic;

bool deviceConnected = false;
bool wasConnected = false; // ← Track previous state

unsigned long lastDustSample = 0;
unsigned long lastDHTSample  = 0;

#define DUST_INTERVAL 500
#define DHT_INTERVAL  2000

float currentDust = 0;
float currentTemp = 0;
float currentHum  = 0;

// Mutex to prevent simultaneous BLE writes from different tasks
portMUX_TYPE bleMux = portMUX_INITIALIZER_UNLOCKED;

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
      } else if (rxValue == "Fan toggle") {
        bool relayState = toggleRelay();
        pResponseCharacteristic->setValue(relayState ? "Fan:ON" : "Fan:OFF");
        pResponseCharacteristic->notify();
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
  BLEService* pService = pServer->createService( BLEUUID(SERVICE_UUID), 100);   // Increased handler count to 100 for multiple characteristics

  // TX Characteristic (ESP32 → Flutter)
  // --- Dust Characteristic ---
  pDustCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_DUST,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pDustCharacteristic->addDescriptor(new BLE2902());

  // --- Temperature Characteristic ---
  pTempCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TEMP,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTempCharacteristic->addDescriptor(new BLE2902());

  // --- Humidity Characteristic ---
  pHumCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_HUM,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pHumCharacteristic->addDescriptor(new BLE2902());

  // Response Characteristic (ESP32 → Flutter)
  pResponseCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RESPONSE,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pResponseCharacteristic->addDescriptor(new BLE2902());

  // RX Characteristic (Flutter → ESP32)
  BLECharacteristic* pRxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE
  );
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
  unsigned long now = millis();

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

  // --- Dust Sensor: every 500ms ---
  if (now - lastDustSample >= DUST_INTERVAL) {
    lastDustSample = now;
    currentDust = readDustDensity();
    //currentDust = random(0,200);

    if (deviceConnected) {
      String msg = String(currentDust);
      pDustCharacteristic->setValue(msg.c_str());
      pDustCharacteristic->notify();
    }

    // Update OLED
    updateDisplay(currentDust, currentTemp, currentHum, deviceConnected);
  }

  // --- DHT Sensor: every 2000ms ---
  if (now - lastDHTSample >= DHT_INTERVAL) {
    lastDHTSample = now;
    currentTemp = readTemperature();
    currentHum  = readHumidity();
    //currentTemp = 20 + random(20,40)/10;
    //currentHum  = random(0,100);

    if (deviceConnected) {
      pTempCharacteristic->setValue(String(currentTemp).c_str());
      pTempCharacteristic->notify();

      pHumCharacteristic->setValue(String(currentHum).c_str());
      pHumCharacteristic->notify();
    }
  }
}