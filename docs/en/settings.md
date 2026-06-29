---
title: Settings
parent: User Guide
lang: en
nav_order: 9
description: "Configure the cloud, language, stat rates, and developer tools."
---

# Settings
{: .no_toc }

1. TOC
{:toc}

![Settings screen]({{ '/assets/images/screenshots/07_settings.png' | relative_url }})
*Settings: pet stats, economy (debug), language, device scanning, and advanced settings.*

## Device

- **Scan / connect / forget** the BLE sensor (**Scan for devices** button).
- Access to the [sensor screens](sensor_screens.html).

## Cloud (ThingsBoard)

To send telemetry to a ThingsBoard server:

1. Go to **Settings → Advanced configuration**.
2. Enter the **base URL** (e.g. `http://YOUR_THINGSBOARD_IP:8080`).
3. Enter the **device token** — you can **scan it by QR code** with the
   camera instead of typing it.
4. The app starts **queuing and sending** data automatically when connected.

![Advanced settings]({{ '/assets/images/screenshots/08_advanced.png' | relative_url }})
*Advanced settings: updates, stat rates, wellbeing threshold, cloud sync, and debug tools.*

> If you do not configure the cloud, the app works the same: it simply does not
> send telemetry. Format details in [Telemetry & Cloud](telemetry.html).
{: .note }

## Language

Therapets detects the device language (Spanish / English) and lets you
change it manually with the flag buttons.

## Stat rates and Dev Tools

The developer section lets you adjust the game pace and debug:

- **Rates** for hunger and happiness decay/gain.
- **Flappy** difficulty and **SBR** multiplier.
- **Reset** stats or missions.
- Enable/disable cloud sync.
- **Telemetry terminal** to view raw packets.

> Dev Tools are intended for testing. Changing the rates directly affects
> the speed of the game.
{: .warning }
