#include "DustSensor.h"

int measurePin = 35; // Pin connected to Vo (Analog read)
int ledPower = 32;   // Pin connected to LED (Toggle sensor LED)

// Timing configuration based on Sharp sensor datasheet
int samplingTime = 280;
int deltaTime = 40;
int sleepTime = 9680;

void initDustSensor() {
  pinMode(ledPower, OUTPUT);
  // Turn off LED initially (This sensor operates on Active Low)
  digitalWrite(ledPower, HIGH); 
  Serial.println("Dust sensor initialized.");
}

float readDustDensity() {
  // 1. Turn on the IR LED inside the sensor
  digitalWrite(ledPower, LOW); 
  delayMicroseconds(samplingTime);

  // 2. Read the dust value (reflected light)
  float voMeasured = analogRead(measurePin); 

  delayMicroseconds(deltaTime);
  
  // 3. Turn off the IR LED
  digitalWrite(ledPower, HIGH); 
  delayMicroseconds(sleepTime);

  // 4. Convert reading (0-4095) to voltage (0-3.3V) for ESP32
  float calcVoltage = voMeasured * (3.3 / 4095.0);

  // 5. Calculate dust density (ug/m3) using Sharp's standard equation
  float dustDensity = 170 * calcVoltage - 0.1;

  // Prevent negative values from voltage fluctuations
  if (dustDensity < 0) {
    dustDensity = 0.00;
  }

  // Display results on Serial Monitor
  Serial.print("Raw Signal (0-4095): ");
  Serial.print(voMeasured);
  Serial.print(" | Voltage: ");
  Serial.print(calcVoltage);
  Serial.print(" V | Dust Density: ");
  Serial.print(dustDensity);
  Serial.println(" ug/m3");

  return dustDensity;
}
