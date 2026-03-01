# HydroNova Mobile (Flutter + GetX)

HydroNova Mobile is the companion app for the HydroNova smart hydroponics ecosystem.  
It connects to an Arduino Uno via Bluetooth (HC-05) to display live sensor readings, and provides an AI assistant for hydroponics and farming guidance.

## Features
- Firebase Authentication (Email/Password)
- Unified login with HydroNova Web (same credentials)
- Bluetooth pairing and connection (HC-05)
- Real-time sensor monitoring (JSON parsing)
- AI Assistant (via n8n webhook + OpenAI API)
- Plant recommendations page (seasonal suggestions)
- Profile page (view/update user info + change password)

## Tech Stack
- **Flutter**
- **GetX** (state management + routing)
- **Firebase Authentication**
- **Firebase Realtime Database** (optional sync if enabled)
- Bluetooth communication with **HC-05**
- AI assistant using **n8n + OpenAI API**
- JSON-based request/response handling

## Architecture
- Uses **MVC-style structure**:
  - Views (UI)
  - Controllers (GetX)
  - Services (Bluetooth, Firebase, API)

> Note: Arduino communicates **only with the mobile app** via Bluetooth (no direct Firebase connection).

---

## Setup & Run Locally

### 1) Clone & install dependencies
```bash
git clone <YOUR_REPO_URL>
cd <YOUR_PROJECT_FOLDER>
flutter pub get