# Настройка Arduino IDE для ESP32-CAM

## Шаг 1: Установите Arduino IDE

Скачайте и установите Arduino IDE:
https://www.arduino.cc/en/software

---

## Шаг 2: Добавьте ESP32 в Arduino IDE

1. Откройте Arduino IDE
2. Перейдите в **File → Preferences**
3. В поле **Additional Board Manager URLs** добавьте:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Нажмите **OK**
5. Перейдите в **Tools → Board → Boards Manager**
6. Найдите **esp32** и установите **esp32 by Espressif Systems**
7. Дождитесь завершения установки

---

## Шаг 3: Установите необходимые библиотеки

Перейдите в **Sketch → Include Library → Manage Libraries** и установите:

1. **ArduinoJson** by Benoit Blanchon (версия 6.x)

Библиотеки BLE, Camera и Base64 уже встроены в ESP32 core.

---

## Шаг 4: Выберите плату

1. **Tools → Board → ESP32 Arduino → AI Thinker ESP32-CAM**

Если не видите эту плату, выберите:
- **ESP32 Wrover Module**

---

## Шаг 5: Настройки платы

Установите следующие параметры в меню **Tools**:

| Параметр | Значение |
|----------|----------|
| Board | AI Thinker ESP32-CAM |
| CPU Frequency | 240MHz (WiFi/BT) |
| Flash Frequency | 80MHz |
| Flash Mode | QIO |
| Flash Size | 4MB (32Mb) |
| Partition Scheme | Huge APP (3MB No OTA/1MB SPIFFS) |
| Core Debug Level | None |
| PSRAM | Enabled |
| Port | Ваш COM порт |

---

## Шаг 6: Подключение для прошивки

### Схема подключения NodeMCU → ESP32-CAM:

```
NodeMCU          ESP32-CAM
-------          ---------
3V3     ─────────  3V3
GND     ─────────  GND
TX      ─────────  U0R
RX      ─────────  U0T
GND     ─────────  IO0    ← Важно для режима прошивки!

RST (NodeMCU) ─── GND (отключаем ESP8266)
```

### Фото распиновки ESP32-CAM:

```
         ┌─────────────────────────────────┐
         │  ┌─────┐      ┌───────────┐     │
         │  │CAM  │      │  ESP32-S  │     │
         │  │     │      │           │     │
         │  └─────┘      └───────────┘     │
         │                                 │
         │ 5V  GND  IO12 IO13 IO15 IO14 IO2│
         │ ○   ○    ○    ○    ○    ○    ○  │
  ─────────────────────────────────────────────
         │ ○   ○    ○    ○    ○    ○    ○  │
         │3V3 IO16 IO0  GND  VCC  U0R  U0T │
         │          ↑                      │
         │      Для прошивки              │
         │      подключить к GND          │
         └─────────────────────────────────┘
```

---

## Шаг 7: Прошивка

1. Подключите NodeMCU к компьютеру через USB
2. Выберите правильный COM порт в **Tools → Port**
3. Откройте файл `esp32cam_smartglasses.ino`
4. Нажмите кнопку **Upload** (→)
5. Когда появится `Connecting........_____`, нажмите кнопку **RST** на ESP32-CAM
6. Дождитесь завершения загрузки
7. **ВАЖНО**: Отключите провод IO0 от GND!
8. Нажмите RST для перезагрузки

---

## Шаг 8: Проверка

1. Откройте **Tools → Serial Monitor**
2. Установите скорость **115200 baud**
3. Нажмите RST на ESP32-CAM
4. Должны увидеть:

```
=== Smart Glasses ESP32-CAM ===
[DFPLAYER] Initializing...
[DFPLAYER] Ready
[CAM] Initializing...
[CAM] Initialized successfully
[BLE] Initializing...
[BLE] Ready! Device name: SmartGlasses

=== Ready for connections! ===
```

---

## Возможные ошибки

### Ошибка: "Failed to connect to ESP32"
**Решение:**
- Убедитесь что IO0 подключен к GND
- Нажмите RST когда увидите "Connecting..."
- Попробуйте другой USB кабель

### Ошибка: "A fatal error occurred: Timed out"
**Решение:**
- Проверьте подключение TX/RX (не перепутаны ли)
- Убедитесь что RST NodeMCU подключен к GND

### Ошибка: "Brownout detector was triggered"
**Решение:**
- Используйте более мощный источник питания
- Подключите напрямую к USB порту (не через хаб)

### Ошибка: "Camera init failed"
**Решение:**
- Проверьте шлейф камеры
- Переподключите шлейф
- Выберите правильную плату (AI Thinker ESP32-CAM)

---

## Альтернатива: Прошивка через USB-UART адаптер

Если у вас есть отдельный USB-UART адаптер (CP2102, CH340, FT232):

```
USB-UART         ESP32-CAM
--------         ---------
3V3     ─────────  3V3
GND     ─────────  GND
TX      ─────────  U0R
RX      ─────────  U0T
         GND ─────  IO0
```

Процесс прошивки такой же.
