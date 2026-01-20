/*
 * Smart Glasses ESP32-CAM Firmware
 *
 * Connects to mobile app via BLE and controls:
 * - Camera (OV2640)
 * - DFPlayer Mini (MP3 audio)
 * - Status LED
 *
 * BLE Protocol: JSON commands
 *
 * Author: Smart Glasses Project
 * Date: 2025
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "esp_camera.h"
#include "mbedtls/base64.h"  // Built-in ESP32 base64
#include <ArduinoJson.h>
#include "DFPlayerMini.h"

// ==================== BLE UUIDs (MUST MATCH APP!) ====================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define TX_CHAR_UUID        "beb5483e-36e1-4688-b7f5-ea07361b26a8"  // ESP32 -> Phone (Notify)
#define RX_CHAR_UUID        "beb5483f-36e1-4688-b7f5-ea07361b26a9"  // Phone -> ESP32 (Write)
#define STATUS_CHAR_UUID    "beb54840-36e1-4688-b7f5-ea07361b26aa"  // Status
#define BATTERY_CHAR_UUID   "beb54841-36e1-4688-b7f5-ea07361b26ab"  // Battery

// ==================== ESP32-CAM Pin Definitions ====================
// Camera pins (AI-Thinker ESP32-CAM)
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// DFPlayer pins (using available GPIOs)
#define DFPLAYER_RX_PIN   14  // ESP32 TX -> DFPlayer RX
#define DFPLAYER_TX_PIN   15  // ESP32 RX <- DFPlayer TX

// LED Flash
#define FLASH_LED_PIN      4

// Battery ADC (optional - connect voltage divider)
#define BATTERY_PIN       13

// ==================== Global Variables ====================
BLEServer* pServer = nullptr;
BLECharacteristic* pTxCharacteristic = nullptr;
BLECharacteristic* pRxCharacteristic = nullptr;
BLECharacteristic* pStatusCharacteristic = nullptr;
BLECharacteristic* pBatteryCharacteristic = nullptr;

DFPlayerMini dfPlayer;

bool deviceConnected = false;
bool oldDeviceConnected = false;
bool cameraInitialized = false;

String deviceStatus = "ready";
int batteryLevel = 100;

// ==================== BLE Callbacks ====================
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("[BLE] Device connected");
    updateStatus("connected");

    // Play connection sound
    dfPlayer.playTrack(1);  // Track 001 - connection sound
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("[BLE] Device disconnected");
    updateStatus("disconnected");

    // Restart advertising
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Advertising restarted");
  }
};

class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String rxValue = pCharacteristic->getValue().c_str();

    if (rxValue.length() > 0) {
      Serial.println("[BLE] Received: " + rxValue);
      processCommand(rxValue);
    }
  }
};

// ==================== Command Processing ====================
void processCommand(String jsonStr) {
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, jsonStr);

  if (error) {
    Serial.println("[JSON] Parse error: " + String(error.c_str()));
    sendResponse("error", "JSON parse failed");
    return;
  }

  String cmd = doc["cmd"].as<String>();
  JsonObject data = doc["data"];

  Serial.println("[CMD] Processing: " + cmd);

  // ===== Camera Commands =====
  if (cmd == "capture") {
    captureAndSendPhoto();
  }
  else if (cmd == "flash_on") {
    digitalWrite(FLASH_LED_PIN, HIGH);
    sendResponse("flash", "on");
  }
  else if (cmd == "flash_off") {
    digitalWrite(FLASH_LED_PIN, LOW);
    sendResponse("flash", "off");
  }

  // ===== Audio Commands =====
  else if (cmd == "play") {
    int track = data["track"] | 1;
    dfPlayer.playTrack(track);
    sendResponse("audio", "playing track " + String(track));
  }
  else if (cmd == "play_folder") {
    int folder = data["folder"] | 1;
    int track = data["track"] | 1;
    dfPlayer.playFromFolder(folder, track);
    sendResponse("audio", "playing folder " + String(folder) + " track " + String(track));
  }
  else if (cmd == "volume") {
    int vol = data["level"] | 20;
    dfPlayer.setVolume(vol);
    sendResponse("volume", String(vol));
  }
  else if (cmd == "stop") {
    dfPlayer.stop();
    sendResponse("audio", "stopped");
  }
  else if (cmd == "pause") {
    dfPlayer.pause();
    sendResponse("audio", "paused");
  }
  else if (cmd == "resume") {
    dfPlayer.resume();
    sendResponse("audio", "resumed");
  }

  // ===== Navigation Audio Cues =====
  else if (cmd == "nav_left") {
    dfPlayer.playFromFolder(2, 1);  // Folder 02, track 001 - "Turn left"
    sendResponse("nav", "left");
  }
  else if (cmd == "nav_right") {
    dfPlayer.playFromFolder(2, 2);  // Folder 02, track 002 - "Turn right"
    sendResponse("nav", "right");
  }
  else if (cmd == "nav_straight") {
    dfPlayer.playFromFolder(2, 3);  // Folder 02, track 003 - "Go straight"
    sendResponse("nav", "straight");
  }
  else if (cmd == "nav_arrived") {
    dfPlayer.playFromFolder(2, 4);  // Folder 02, track 004 - "You arrived"
    sendResponse("nav", "arrived");
  }
  else if (cmd == "nav_obstacle") {
    dfPlayer.playFromFolder(3, 1);  // Folder 03, track 001 - "Obstacle ahead"
    sendResponse("nav", "obstacle_warning");
  }

  // ===== Status Commands =====
  else if (cmd == "ping") {
    sendResponse("pong", "ok");
  }
  else if (cmd == "status") {
    sendStatusUpdate();
  }
  else if (cmd == "battery") {
    sendBatteryLevel();
  }

  // ===== TTS Commands (speak text via numbered tracks) =====
  else if (cmd == "speak") {
    // For pre-recorded phrases, use track numbers
    int phraseId = data["phrase_id"] | 0;
    if (phraseId > 0) {
      dfPlayer.playFromFolder(1, phraseId);  // Folder 01 - phrases
      sendResponse("speak", "phrase " + String(phraseId));
    }
  }

  // ===== Unknown Command =====
  else {
    sendResponse("error", "Unknown command: " + cmd);
  }
}

// ==================== Response Functions ====================
void sendResponse(String type, String message) {
  if (!deviceConnected) return;

  StaticJsonDocument<256> doc;
  doc["type"] = type;
  doc["message"] = message;
  doc["timestamp"] = millis();

  String jsonStr;
  serializeJson(doc, jsonStr);

  pTxCharacteristic->setValue(jsonStr.c_str());
  pTxCharacteristic->notify();

  Serial.println("[TX] Sent: " + jsonStr);
}

void sendStatusUpdate() {
  if (!deviceConnected) return;

  StaticJsonDocument<256> doc;
  doc["type"] = "status";
  doc["camera"] = cameraInitialized ? "ok" : "error";
  doc["dfplayer"] = dfPlayer.isOnline() ? "ok" : "error";
  doc["battery"] = batteryLevel;
  doc["uptime"] = millis() / 1000;

  String jsonStr;
  serializeJson(doc, jsonStr);

  pStatusCharacteristic->setValue(jsonStr.c_str());
  pStatusCharacteristic->notify();
}

void sendBatteryLevel() {
  // Read battery voltage (if connected via voltage divider)
  int rawValue = analogRead(BATTERY_PIN);
  // Convert to percentage (adjust based on your voltage divider)
  batteryLevel = map(rawValue, 0, 4095, 0, 100);
  batteryLevel = constrain(batteryLevel, 0, 100);

  String batteryStr = String(batteryLevel);
  pBatteryCharacteristic->setValue(batteryStr.c_str());
  pBatteryCharacteristic->notify();
}

void updateStatus(String status) {
  deviceStatus = status;
  if (pStatusCharacteristic != nullptr) {
    pStatusCharacteristic->setValue(status.c_str());
    pStatusCharacteristic->notify();
  }
}

// ==================== Camera Functions ====================
void initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  // Lower resolution for BLE transfer
  config.frame_size = FRAMESIZE_QVGA;  // 320x240
  config.jpeg_quality = 12;
  config.fb_count = 1;

  // Init camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("[CAM] Init failed: 0x%x\n", err);
    cameraInitialized = false;
    return;
  }

  cameraInitialized = true;
  Serial.println("[CAM] Initialized successfully");
}

void captureAndSendPhoto() {
  if (!cameraInitialized) {
    sendResponse("error", "Camera not initialized");
    return;
  }

  // Turn on flash briefly
  digitalWrite(FLASH_LED_PIN, HIGH);
  delay(100);

  camera_fb_t* fb = esp_camera_fb_get();

  digitalWrite(FLASH_LED_PIN, LOW);

  if (!fb) {
    sendResponse("error", "Capture failed");
    return;
  }

  Serial.printf("[CAM] Captured %d bytes\n", fb->len);

  // Send photo info first
  StaticJsonDocument<128> infoDoc;
  infoDoc["type"] = "photo_info";
  infoDoc["size"] = fb->len;
  infoDoc["width"] = fb->width;
  infoDoc["height"] = fb->height;

  String infoStr;
  serializeJson(infoDoc, infoStr);
  pTxCharacteristic->setValue(infoStr.c_str());
  pTxCharacteristic->notify();
  delay(50);

  // Send photo in chunks (BLE MTU is ~500 bytes)
  const int CHUNK_SIZE = 300;  // Smaller for base64 expansion
  int totalChunks = (fb->len + CHUNK_SIZE - 1) / CHUNK_SIZE;

  // Buffer for base64 encoding
  unsigned char base64Buf[512];
  size_t base64Len = 0;

  for (int i = 0; i < totalChunks; i++) {
    int offset = i * CHUNK_SIZE;
    int chunkLen = min(CHUNK_SIZE, (int)(fb->len - offset));

    // Encode chunk to base64 using mbedtls
    mbedtls_base64_encode(base64Buf, sizeof(base64Buf), &base64Len,
                          &fb->buf[offset], chunkLen);
    base64Buf[base64Len] = '\0';

    StaticJsonDocument<700> chunkDoc;
    chunkDoc["type"] = "photo_chunk";
    chunkDoc["chunk"] = i;
    chunkDoc["total"] = totalChunks;
    chunkDoc["data"] = (char*)base64Buf;

    String chunkStr;
    serializeJson(chunkDoc, chunkStr);

    pTxCharacteristic->setValue(chunkStr.c_str());
    pTxCharacteristic->notify();
    delay(30);  // Small delay between chunks
  }

  // Send completion
  sendResponse("photo", "complete");

  esp_camera_fb_return(fb);
  Serial.println("[CAM] Photo sent");
}

// ==================== BLE Setup ====================
void setupBLE() {
  Serial.println("[BLE] Initializing...");

  BLEDevice::init("SmartGlasses");

  // Create server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // TX Characteristic (ESP32 -> Phone, Notify)
  pTxCharacteristic = pService->createCharacteristic(
    TX_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTxCharacteristic->addDescriptor(new BLE2902());

  // RX Characteristic (Phone -> ESP32, Write)
  pRxCharacteristic = pService->createCharacteristic(
    RX_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pRxCharacteristic->setCallbacks(new RxCallbacks());

  // Status Characteristic
  pStatusCharacteristic = pService->createCharacteristic(
    STATUS_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pStatusCharacteristic->addDescriptor(new BLE2902());

  // Battery Characteristic
  pBatteryCharacteristic = pService->createCharacteristic(
    BATTERY_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pBatteryCharacteristic->addDescriptor(new BLE2902());

  // Start service
  pService->start();

  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Ready! Device name: SmartGlasses");
}

// ==================== Setup ====================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n=== Smart Glasses ESP32-CAM ===");

  // Init flash LED
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);

  // Init battery pin
  pinMode(BATTERY_PIN, INPUT);

  // Init DFPlayer
  Serial.println("[DFPLAYER] Initializing...");
  dfPlayer.begin(DFPLAYER_RX_PIN, DFPLAYER_TX_PIN);
  delay(1000);
  dfPlayer.setVolume(20);  // 0-30
  Serial.println("[DFPLAYER] Ready");

  // Init Camera
  Serial.println("[CAM] Initializing...");
  initCamera();

  // Init BLE
  setupBLE();

  // Startup sound
  dfPlayer.playTrack(1);

  Serial.println("\n=== Ready for connections! ===\n");
}

// ==================== Main Loop ====================
void loop() {
  // Handle connection state changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Restart advertising");
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Periodic battery update (every 30 seconds)
  static unsigned long lastBatteryUpdate = 0;
  if (deviceConnected && millis() - lastBatteryUpdate > 30000) {
    sendBatteryLevel();
    lastBatteryUpdate = millis();
  }

  delay(10);
}
