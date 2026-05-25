---
layout: default
title: BLE Setup
---

# Connecting Your Device (BLE Setup)

Therapets uses Bluetooth Low Energy (BLE) to securely connect to your sensor device. The sensor tracks your activity and translates it into daily mission progress.

## How to Connect

1. Ensure Bluetooth is enabled on your smartphone.
2. Open the Therapets app.
3. The app will automatically scan for your assigned device. Once found, the connection status will change to **Connected**.

## Understanding Connection States

The Therapets system is designed to handle brief interruptions in sensor readings seamlessly.

### The 15-Second Grace Window
If the device temporarily loses line of sight or readings are interrupted, you won't lose sync immediately. The app provides a **15-second grace window**. If readings resume within this time, your session continues uninterrupted.

### Temporary Disconnections
If you step away from the device and the BLE connection drops:
- The app history freezes for up to 30 seconds, showing a **"Waiting"** status.
- If you return within 30 seconds, the history resumes exactly where it left off.
- If the disconnection lasts longer than 30 seconds, the active session is reset.

**Note:** Time spent disconnected is not counted towards your daily missions, ensuring that only genuine activity is tracked in the cloud.
