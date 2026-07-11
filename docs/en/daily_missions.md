---
title: Daily Missions
parent: User Guide
lang: en
nav_order: 6
description: "The three daily missions, their rewards, and the midnight reset."
---

# Daily Missions
{: .no_toc }

1. TOC
{:toc}

Every day **3 missions** are generated. Completing them grants **gold** (for clothing)
and a bit of **happiness**. They **reset** when the day changes (at midnight, local time).

![Daily missions]({{ '/assets/images/screenshots/06_missions.png' | relative_url }})
*The day's three missions with their progress and gold reward.*

## The three missions

| Mission | Objective | Reward |
|---------|-----------|:------:|
| **Sync Master** | Be synced for **120 minutes** in a day | 🪙 50 gold + happiness |
| **Game Time** | Play **3** minigames | 🪙 30 gold + happiness |
| **Yummy Time** | Feed Bob **3** times | 🪙 20 gold + happiness |

- **Sync Master** advances on its own while you are *Synced* — even with the app
  in the background (progress is recovered when you reopen).
- **Game Time** counts every round of any minigame.
- **Yummy Time** counts each time you feed Bob.

## Daily reset

When you open the app on a new day, the previous day's missions are replaced by
a fresh set. Incomplete progress is lost; gold already earned is kept.

> Mission progress is saved resiliently (Hive + SharedPreferences backup) to
> survive system kills. Details in
> [Data Model](data_model.html).
{: .note }
