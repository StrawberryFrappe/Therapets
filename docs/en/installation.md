---
title: Installation
parent: User Guide
lang: en
nav_order: 1
description: "Download, install, and grant permissions for Therapets on Android."
---

# Installation
{: .no_toc }

1. TOC
{:toc}

## Requirements

- Android (the app declares modern Bluetooth permissions for Android 12+; works
  on older versions with the location permission).
- The **M5-IMU** sensor (MAX30100 or GY906 variant).
- *(Optional)* Access to a ThingsBoard server if you plan to use the cloud.

## Download channels

Therapets is published as an APK on the
[GitHub Releases](https://github.com/StrawberryFrappe/Therapets/releases) page.
There are three channels:

| Channel | Type | Who it's for |
|---------|------|--------------|
| **Stable** | Production | Normal use. [Latest stable APK](https://github.com/StrawberryFrappe/Therapets/releases/latest/download/app-release.apk) |
| **Nightly** | Development (`dev`) | Testing the latest — may break. |
| **Unstable** | Experimental | Half-finished features. |

> Nightly and Unstable builds are *prereleases*. Only install them if you want
> to test new changes.
{: .warning }

## Installing the APK

1. Download the APK from your chosen channel to your phone.
2. Open it. Android will ask you to allow **installing apps from unknown sources**
   for your browser/file manager — enable it.
3. Confirm the installation.

> Therapets uses the `REQUEST_INSTALL_PACKAGES` permission to offer
> in-app updates. See [Updating the App](updating.html).
{: .note }

## Permissions on first launch

When you open the app for the first time, it will request several permissions.
All of them are required for BLE operation in the background:

| Permission | Purpose |
|------------|---------|
| **Bluetooth** (scan, connect) | Find and pair the M5 sensor. |
| **Location** | Required by Android to scan BLE on older versions. |
| **Notifications** | Persistent service notification + low-wellbeing alerts. |
| **Camera** | Scan the QR code for the cloud token (optional). |
| **Ignore battery optimization** | Prevents the system from killing the BLE background service. |

> On phones with aggressive battery management (Xiaomi, Huawei, Samsung, etc.)
> accept the battery optimization exemption; otherwise the sensor will disconnect
> when the screen turns off.
{: .warning }

## Next step

With the app installed and permissions granted, continue with
[BLE Connection](ble_setup.html).
