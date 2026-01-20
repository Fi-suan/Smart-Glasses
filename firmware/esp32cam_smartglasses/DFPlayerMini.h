/*
 * DFPlayerMini.h - Simple DFPlayer Mini library for ESP32
 *
 * Uses Software Serial for communication
 * Compatible with MP3-TF-16P module
 */

#ifndef DFPLAYERMINI_H
#define DFPLAYERMINI_H

#include <Arduino.h>
#include <HardwareSerial.h>

class DFPlayerMini {
private:
  HardwareSerial* serial;
  int rxPin;
  int txPin;
  uint8_t volume;
  bool online;

  // Command bytes
  static const uint8_t CMD_PLAY = 0x03;
  static const uint8_t CMD_PAUSE = 0x0E;
  static const uint8_t CMD_NEXT = 0x01;
  static const uint8_t CMD_PREV = 0x02;
  static const uint8_t CMD_VOLUME = 0x06;
  static const uint8_t CMD_PLAY_FOLDER = 0x0F;
  static const uint8_t CMD_STOP = 0x16;
  static const uint8_t CMD_RESET = 0x0C;
  static const uint8_t CMD_QUERY_STATUS = 0x42;

  void sendCommand(uint8_t cmd, uint8_t param1 = 0, uint8_t param2 = 0) {
    uint8_t buffer[10];

    buffer[0] = 0x7E;  // Start byte
    buffer[1] = 0xFF;  // Version
    buffer[2] = 0x06;  // Length
    buffer[3] = cmd;   // Command
    buffer[4] = 0x00;  // Feedback (no)
    buffer[5] = param1; // Param high byte
    buffer[6] = param2; // Param low byte

    // Calculate checksum
    int16_t checksum = 0 - (buffer[1] + buffer[2] + buffer[3] + buffer[4] + buffer[5] + buffer[6]);
    buffer[7] = (checksum >> 8) & 0xFF;
    buffer[8] = checksum & 0xFF;
    buffer[9] = 0xEF;  // End byte

    serial->write(buffer, 10);
    delay(30);  // Wait for command to process
  }

public:
  DFPlayerMini() : serial(nullptr), rxPin(0), txPin(0), volume(20), online(false) {}

  void begin(int rx, int tx) {
    rxPin = rx;
    txPin = tx;

    // Use Serial2 for DFPlayer
    serial = &Serial2;
    serial->begin(9600, SERIAL_8N1, rxPin, txPin);

    delay(500);  // Wait for DFPlayer to boot

    // Reset module
    sendCommand(CMD_RESET);
    delay(1000);

    // Set initial volume
    setVolume(volume);
    online = true;

    Serial.println("[DFPlayer] Initialized on pins RX:" + String(rxPin) + " TX:" + String(txPin));
  }

  bool isOnline() {
    return online;
  }

  void setVolume(uint8_t vol) {
    vol = constrain(vol, 0, 30);
    volume = vol;
    sendCommand(CMD_VOLUME, 0, vol);
    Serial.println("[DFPlayer] Volume set to: " + String(vol));
  }

  uint8_t getVolume() {
    return volume;
  }

  void playTrack(uint16_t track) {
    // Play track from root folder
    uint8_t high = (track >> 8) & 0xFF;
    uint8_t low = track & 0xFF;
    sendCommand(CMD_PLAY, high, low);
    Serial.println("[DFPlayer] Playing track: " + String(track));
  }

  void playFromFolder(uint8_t folder, uint8_t track) {
    // Play specific track from specific folder
    // Folders named 01, 02, 03...
    // Tracks named 001.mp3, 002.mp3...
    sendCommand(CMD_PLAY_FOLDER, folder, track);
    Serial.println("[DFPlayer] Playing folder " + String(folder) + " track " + String(track));
  }

  void pause() {
    sendCommand(CMD_PAUSE);
    Serial.println("[DFPlayer] Paused");
  }

  void resume() {
    // Send play command to resume
    sendCommand(CMD_PAUSE);  // Toggle pause/play
    Serial.println("[DFPlayer] Resumed");
  }

  void stop() {
    sendCommand(CMD_STOP);
    Serial.println("[DFPlayer] Stopped");
  }

  void next() {
    sendCommand(CMD_NEXT);
    Serial.println("[DFPlayer] Next track");
  }

  void prev() {
    sendCommand(CMD_PREV);
    Serial.println("[DFPlayer] Previous track");
  }

  void volumeUp() {
    if (volume < 30) {
      setVolume(volume + 1);
    }
  }

  void volumeDown() {
    if (volume > 0) {
      setVolume(volume - 1);
    }
  }
};

#endif
