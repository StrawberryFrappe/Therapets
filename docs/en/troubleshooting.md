---
title: Troubleshooting
parent: User Guide
lang: en
nav_order: 11
description: "Frequently asked questions and solutions to common problems."
---

# Troubleshooting & FAQ
{: .no_toc }

1. TOC
{:toc}

## BLE connection

**The sensor does not appear when scanning.**
Make sure it is powered on, has battery, and that your phone's Bluetooth is
active. Bring it closer to the phone and scan again.

**It connects but the status never reaches "Synced".**
"Synced" requires **human detected**. Wear the sensor in contact with your skin
(wrist/forearm) and wait a few seconds for the reading to stabilize.

**It disconnects when I turn off the screen.**
Grant the **battery optimization exemption** (System Settings → Battery).
On Xiaomi/Huawei/Samsung phones this is usually mandatory.

**After rebooting the phone it does not reconnect.**
The app resumes the service on system boot, but on some phones you need to
**open the app once** after rebooting.

## Pet and stats

**Happiness drops even though I am synced.**
If **hunger is below 25%**, happiness drops regardless.
Feed Bob.

**I was synced with the app closed — did I lose progress?**
No. Happiness accumulates in a background *buffer* and is applied when you reopen
the app. Mission progress is also recovered.

## Cloud

**I configured the cloud but no data is arriving.**
Check the base URL and token. The app **queues** events and sends them when
connected; if it fails 5 times, the event is discarded. See [Telemetry](telemetry.html).

## Updates

**I cannot install the update.**
Allow **installing apps from unknown sources** for the app/installer when
Android prompts you.

## Data

**Will I lose my pet when I update?**
No. Data persists locally with automatic migration.

---

Problem not listed here? Open an *issue* on
[GitHub](https://github.com/StrawberryFrappe/Therapets/issues).
