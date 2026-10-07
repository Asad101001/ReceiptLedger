<div align="center">

# ReceiptLedger / Mobile Client

**Cross-Platform Mobile Application for Guided Camera Capture and Image Ingestion.**

[![Framework](https://img.shields.io/badge/Framework-Flutter%203.x-02569B?style=flat-square&logo=flutter&logoColor=white)](#)
[![Language](https://img.shields.io/badge/Language-Dart%203.x-0175C2?style=flat-square&logo=dart&logoColor=white)](#)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=flat-square&logo=android&logoColor=white)](#)
[![Design System](https://img.shields.io/badge/Design-Google%20Stitch-EA4335?style=flat-square&logo=google&logoColor=white)](#)

</div>

---

## Overview

The `mobile` client provides a lightweight, guided camera interface enabling users to photograph single or batch paper receipts. It applies client-side edge detection indicators, crops, compresses images, and uploads payloads directly to the ReceiptLedger backend.

---

## UI/UX Design System

* **Mockups & Wireframes:** Designed using **Google Stitch** / Material 3 guidelines.
* **Key User Flows:**
  1. **Camera Viewfinder:** Visual bounding guide ensuring receipt edges are aligned before snap.
  2. **Preview & Confirm:** Instant client-side inspection for blur detection.
  3. **Batch Mode:** Rapid capture of multiple receipts in a single session.
  4. **Upload Status:** Real-time feedback with retry queuing for offline captures.

---

## Directory Structure

```text
mobile/
├── pubspec.yaml           # Flutter package dependencies
├── .env.example           # Endpoint configurations
├── lib/
│   ├── main.dart          # Application entrypoint
│   ├── screens/           # Camera, Preview, History screens
│   ├── services/          # Camera controller, Ingestion API client
│   └── widgets/           # Edge guides, Capture buttons
└── assets/                # App icons and mockups
```

---

## Development Setup

### 1. Prerequisites
* [Flutter SDK 3.x+](https://flutter.dev/)
* Android Studio (Android SDK API Level 26+) or Xcode (for iOS)

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
* **Android Emulator:** Set `API_BASE_URL=http://10.0.2.2:8000`
* **Physical Device:** Set `API_BASE_URL=http://192.168.1.X:8000` (your machine's LAN IP)

### 4. Run the Application

```bash
# Check connected devices
flutter devices

# Launch in debug mode
flutter run
```
