---
title: Minigames
parent: User Guide
lang: en
nav_order: 7
description: "The motion-controlled minigames and how to play them."
---

# Minigames
{: .no_toc }

1. TOC
{:toc}

Minigames use **sensor movement** (shakes and tilts) as controls. Playing grants
**silver** (for food) and counts toward the **Game Time** mission.

![Games menu]({{ '/assets/images/screenshots/05_game_menu.png' | relative_url }})
*The games menu: Flappy Bob, Orchestra, donut.dart, and SBR.*

## Flappy Bob

*Flappy Bird*-style. Bob jumps between pipes.

- **Control:** a **shake** of the sensor makes Bob jump (discrete movement event).
  Also responds to a tap on screen.
- **Reward:** **silver** coins based on how far you get.
- **Difficulty:** adjustable (Easy/Medium/Hard/Impossible) before you start.

![Flappy Bob]({{ '/assets/images/screenshots/09_flappy.png' | relative_url }})
*Flappy Bob start screen with the difficulty selector. With no sensor, "Tap to flap".*

## Orchestra

Creative theremin-style tool with musician-pets.

- **Control:** **tilt** the device continuously to vary pitch and volume
  (uses the sensor's continuous telemetry).
- No pressure: it's for experimenting with sound.

## Donut

Minigame with a 3D donut you can rotate.

- **Control:** 3D rotation (rendered with `flutter_cube`).

## SBR (brick breaker)

*Breakout*-style, motion-controlled.

- **Control:** move the paddle/ball by tilting.
- **Difficulty:** adjustable multiplier in [Settings](settings.html).

> No sensor connected? Some minigames are still playable with on-screen controls,
> but the full experience requires the M5 sensor.
{: .tip }
