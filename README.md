# 🧠🚗 Mind-Controlled Car using EEG and IoT

A smart **EEG-based Mind-Controlled Car** system that uses the **NeuroSky MindWave Mobile 2** headset to interpret brainwave signals and control an **ESP32-based robot car** via Bluetooth and HTTP protocols. The system also includes **manual control options** using IR remotes and physical buttons, making it a hybrid multi-input system.

---

## 🚀 Project Overview

This project demonstrates how **EEG (Electroencephalography) signals** can be used to control a robotic vehicle. The headset detects **attention, meditation, and blinks**, which are processed in a **Flutter app** to make real-time movement decisions. The car is then controlled via **Wi-Fi (ESP32 HTTP)** based on the detected mental commands.

---

## 🧩 Features

* 🔗 **Real-time EEG signal processing** from NeuroSky MindWave
* 📱 **Flutter mobile app** for Bluetooth communication and UI
* 🌐 **Wi-Fi-based car control** using ESP32 (HTTP GET/POST)
* 👀 **Blink detection** to trigger left/right movement
* 🧘 **Meditation level** to control reverse
* 🚘 Manual controls via:

  * 📡 IR Remote
  * 🔘 Push buttons on PCB
* 📈 Real-time brainwave data graph (Alpha, Beta, Gamma, etc.)
* 🔌 Power-efficient and multi-mode operation

---

## 🛠️ Hardware Components

| Component               | Description                     |
| ----------------------- | ------------------------------- |
| 🧠 NeuroSky MindWave    | EEG Headset                     |
| 🔲 ESP32-WROOM-32       | Microcontroller with Wi-Fi      |
| 📱 Android Phone        | For Flutter App and EEG parsing |
| 🛞 L298N Motor Driver   | For dual DC motor control       |
| 🔋 Battery              | For powering motors and board   |
| 🔘 IR Receiver + Remote | Manual car control              |
| 📟 16x2 I2C LCD         | (Optional) Display EEG/Status   |
| 💧 Moisture/pH Sensor   | (Optional extension)            |

---

## 📲 Flutter App Features

* Scan and connect to MindWave EEG device (BLE)
* Graphically display EEG metrics (attention, meditation, blink strength)
* Send movement commands to ESP32 via Wi-Fi
* Real-time feedback and alerts

---

## 🔧 How It Works

1. MindWave reads brain signals.
2. Flutter app parses EEG data over Bluetooth using `flutter_blue_plus`.
3. Based on blink or meditation thresholds:

   * Sends commands (e.g., `FORWARD`, `LEFT`, `REVERSE`) to ESP32 via HTTP.
4. ESP32 receives the command and sets motor pins HIGH/LOW using L298N.
5. Manual override is always available via IR or push buttons.

---

## 🧠 EEG Signal Mapping

| EEG Input      | Action Triggered   |
| -------------- | ------------------ |
| Blink Detected | Turn Left or Right |
| Meditation > X | Move in Reverse    |
| Attention > Y  | Move Forward       |
| Idle           | Stop               |

---

## 🔌 Pin Configuration (ESP32)

| Pin      | Description      |
| -------- | ---------------- |
| D5, D18  | Motor A (Front)  |
| D19, D21 | Motor B (Back)   |
| D22      | IR Sensor        |
| D23      | Button 1 (Left)  |
| D25      | Button 2 (Right) |
| 3V3, GND | Power Rails      |

---

## 📁 Project Structure

```
MindControlledCar/
├── flutter_app/           # EEG data processing & UI
├── esp32_code/            # Arduino code for ESP32
├── pcb_design/            # KiCad schematic & PCB layout
├── images/                # System architecture, demo screenshots
└── README.md              # Project documentation
```

---

## 📷 Demo

![PCB Design](images/pcb_design.png)
![Flutter UI](images/flutter_ui.png)
![Working Car](images/working_demo.jpg)

---

## 📦 Future Enhancements

* Voice commands as secondary control
* Real-time location tracking using GPS
* Web dashboard with EEG logs
* Adaptive control with ML-based pattern recognition

---

## 🤝 Credits

* **Developed by:** Nayan Parekh ,Ved Patel
* **EEG Hardware:** NeuroSky MindWave Mobile 2
* **Embedded System:** ESP32
* **Mobile App:** Flutter
