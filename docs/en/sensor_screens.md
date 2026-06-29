---
title: Sensor Screens
parent: User Guide
lang: en
nav_order: 8
description: "How to read the pulse oximeter (MAX30100) and temperature (GY906) screens."
---

# Sensor Screens
{: .no_toc }

1. TOC
{:toc}

Depending on the paired sensor variant, the app provides a dedicated screen with
a live reading and a waveform. Accessed from **Settings**.

## Pulse oximeter (MAX30100)

Displays:

- **BPM** — beats per minute.
- **SpO₂** — blood oxygen saturation (%).
- **Waveform** — filtered IR signal, ECG-style.

For a valid reading:

- Place the sensor in firm contact with your **wrist or finger**.
- Wait a few seconds for it to stabilize (finger detection + sustained pulse).
- Human range considered: **40–200 BPM** and **SpO₂ ≥ 85%**.

## Temperature (GY906)

Displays:

- **Temperature** in °C.
- **Trend / waveform** of temperature.

For a valid reading:

- Rest the sensor against the skin of your **forearm**.
- Human detection range: **29.7°C – 41°C** (forearm skin, cooler than core temperature).
- A reading of 0 indicates the sensor is disconnected or has an error.

> These screens show the **last valid reading** during brief transmission pauses
> (up to ~60 s), so the value does not flicker.
{: .note }

> **Note about screenshots:** the images for these screens were taken in an
> emulator without a physical sensor, so they appear in the *disconnected /
> searching* state. With the real M5 sensor they would show live data.
{: .warning }
