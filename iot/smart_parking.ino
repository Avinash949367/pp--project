#define BLYNK_TEMPLATE_ID "TMPL38vmHWTXm"
#define BLYNK_TEMPLATE_NAME "Smart Parking"
#define BLYNK_AUTH_TOKEN "eK1DRkaX37-0o70h5TdQngSIMdRRj04x"
#include <WiFi.h>
#include <BlynkSimpleEsp32.h>
#include <ESP32Servo.h>

// WiFi Credentials
char ssid[] = "Pavan";
char pass[] = "99887755";

// Entry / Exit IR & Servos
#define ENTRY_IR_PIN 4
#define EXIT_IR_PIN 15
#define ENTRY_SERVO_PIN 5
#define EXIT_SERVO_PIN 18

// Parking Slot IR Sensors
#define SLOT1_PIN 26
#define SLOT2_PIN 27
#define SLOT3_PIN 14

Servo entryGate;
Servo exitGate;

void setup() {
  Serial.begin(115200);

  // IR Pins
  pinMode(ENTRY_IR_PIN, INPUT);
  pinMode(EXIT_IR_PIN, INPUT);
  pinMode(SLOT1_PIN, INPUT);
  pinMode(SLOT2_PIN, INPUT);
  pinMode(SLOT3_PIN, INPUT);

  // Gate Servos
  entryGate.attach(ENTRY_SERVO_PIN);
  exitGate.attach(EXIT_SERVO_PIN);
  entryGate.write(0);
  exitGate.write(0);

  // Start Blynk & WiFi
  Blynk.begin(BLYNK_AUTH_TOKEN, ssid, pass, "blynk.cloud", 80);

}

void loop() {
  Blynk.run();

  // ---------------- ENTRY GATE ----------------
  if (digitalRead(ENTRY_IR_PIN) == LOW) {
    entryGate.write(90);
    delay(3000);
  } else {
    entryGate.write(0);
  }

  // ---------------- EXIT GATE -----------------
  if (digitalRead(EXIT_IR_PIN) == LOW) {
    exitGate.write(90);
    delay(3000);

  } else {
    exitGate.write(0);
  }

  // ---------------- SLOT STATUS ----------------
  sendSlotStatus();
  delay(300);
}

void sendSlotStatus() {
  // Slot 1
  if (digitalRead(SLOT1_PIN) == LOW)
    Blynk.virtualWrite(V1, "Occupied");
  else
    Blynk.virtualWrite(V1, "Empty");

  // Slot 2
  if (digitalRead(SLOT2_PIN) == LOW)
    Blynk.virtualWrite(V2, "Occupied");
  else
    Blynk.virtualWrite(V2, "Empty");

  // Slot 3
  if (digitalRead(SLOT3_PIN) == LOW)
    Blynk.virtualWrite(V3, "Occupied");
  else
    Blynk.virtualWrite(V3, "Empty");
}