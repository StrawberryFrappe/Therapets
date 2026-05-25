---
title: "Telemetry Config"
lang: en
---

# Telemetry Configuration (Developers)

To point the device's telemetry to your own server or cloud instance (like Thingsboard), you must configure the IP and Device ID.

## Manual Configuration

1. In the app, navigate to **Settings > Advanced Settings**.
2. Scroll down to the **Cloud** section.
3. Tap the scan button and scan the QR code of your physical device to get its **Device ID**.
4. In the text field below, manually type the **IP address** of the host server where the telemetry should be sent.
5. Save changes. From this moment on, all background HTTP/MQTT requests will use these parameters.

![Telemetry Config in Advanced Settings](/assets/images/telemetry_config_en.png)
