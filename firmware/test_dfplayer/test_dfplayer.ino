/*
 * DFPlayer Mini Test Sketch
 *
 * Простой тест DFPlayer без BLE
 * Используйте для проверки что DFPlayer работает
 *
 * Подключение:
 * ESP32-CAM IO14 -> DFPlayer RX
 * ESP32-CAM IO15 -> DFPlayer TX
 * ESP32-CAM GND  -> DFPlayer GND
 * ESP32-CAM 5V   -> DFPlayer VCC
 * DFPlayer SPK_1 -> Динамик +
 * DFPlayer SPK_2 -> Динамик -
 */

#include <HardwareSerial.h>

#define DFPLAYER_RX 14  // ESP32 TX -> DFPlayer RX
#define DFPLAYER_TX 15  // ESP32 RX <- DFPlayer TX

HardwareSerial dfSerial(2);  // Use Serial2

// Send command to DFPlayer
void sendCommand(uint8_t cmd, uint8_t param1 = 0, uint8_t param2 = 0) {
  uint8_t buffer[10];

  buffer[0] = 0x7E;  // Start
  buffer[1] = 0xFF;  // Version
  buffer[2] = 0x06;  // Length
  buffer[3] = cmd;   // Command
  buffer[4] = 0x00;  // No feedback
  buffer[5] = param1;
  buffer[6] = param2;

  int16_t checksum = 0 - (buffer[1] + buffer[2] + buffer[3] + buffer[4] + buffer[5] + buffer[6]);
  buffer[7] = (checksum >> 8) & 0xFF;
  buffer[8] = checksum & 0xFF;
  buffer[9] = 0xEF;  // End

  dfSerial.write(buffer, 10);
  delay(100);
}

void setVolume(uint8_t vol) {
  sendCommand(0x06, 0, vol);
  Serial.println("Volume set to: " + String(vol));
}

void playTrack(uint16_t track) {
  sendCommand(0x03, (track >> 8) & 0xFF, track & 0xFF);
  Serial.println("Playing track: " + String(track));
}

void playFolder(uint8_t folder, uint8_t track) {
  sendCommand(0x0F, folder, track);
  Serial.println("Playing folder " + String(folder) + " track " + String(track));
}

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== DFPlayer Mini Test ===\n");

  // Initialize DFPlayer serial
  dfSerial.begin(9600, SERIAL_8N1, DFPLAYER_TX, DFPLAYER_RX);
  delay(1000);

  // Reset DFPlayer
  Serial.println("Resetting DFPlayer...");
  sendCommand(0x0C);
  delay(2000);

  // Set volume (0-30)
  setVolume(20);
  delay(500);

  Serial.println("\nDFPlayer ready!");
  Serial.println("Commands:");
  Serial.println("  1 - Play track 1");
  Serial.println("  2 - Play track 2");
  Serial.println("  3 - Play track 3");
  Serial.println("  f - Play folder 02, track 01");
  Serial.println("  + - Volume up");
  Serial.println("  - - Volume down");
  Serial.println("  s - Stop");
  Serial.println("  p - Pause");
  Serial.println("");
}

uint8_t currentVolume = 20;

void loop() {
  if (Serial.available()) {
    char c = Serial.read();

    switch (c) {
      case '1':
        playTrack(1);
        break;
      case '2':
        playTrack(2);
        break;
      case '3':
        playTrack(3);
        break;
      case 'f':
        playFolder(2, 1);
        break;
      case '+':
        if (currentVolume < 30) {
          currentVolume++;
          setVolume(currentVolume);
        }
        break;
      case '-':
        if (currentVolume > 0) {
          currentVolume--;
          setVolume(currentVolume);
        }
        break;
      case 's':
        sendCommand(0x16);
        Serial.println("Stopped");
        break;
      case 'p':
        sendCommand(0x0E);
        Serial.println("Paused/Resumed");
        break;
    }
  }
}
