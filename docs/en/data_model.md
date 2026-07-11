---
title: Data Model & Persistence
parent: Developer Docs
lang: en
nav_order: 6
description: "Hive boxes, adapters, SharedPreferences mirror, and migration."
---

# Data Model & Persistence
{: .no_toc }

1. TOC
{:toc}

Therapets uses **Hive** (local NoSQL) as the primary store and **SharedPreferences**
as a mirror/backup (required for the native service and for atomic rehydration
after system kills).

## Hive boxes

| Box | Contents | Keys |
|-----|----------|------|
| `pet_stats_box` | `PetStats` (index 0) | stats, coins, inventory, clothing |
| `missions_box` | daily missions | `missions`, `lastResetMs` |

## Adapters (typeId)

| Type | typeId | File |
|------|:------:|------|
| `PetStats` | 1 | `lib/game/pets/pet_stats.dart` (+ `.g.dart`) |
| `SyncDurationMission` | 2 | `lib/game/missions/daily_missions.dart` |
| `MinigamePlayMission` | 3 | `daily_missions.dart` |
| `FeedPetMission` | 4 | `daily_missions.dart` |

> `*.g.dart` files are generated with `build_runner` (see [Dev Environment](dev_environment.html)).
> Do not reuse a `typeId` for another type: it would break reading existing data.
{: .warning }

## PetStats model

Persisted fields (`@HiveField`): hunger, happiness, happiness buffer, rates
(hunger/happiness gain/decay), last-update timestamp, wellbeing threshold, gold,
silver, unlocked clothing, equipped clothing (slot→id map), food inventory
(id→quantity map).

Default rates:

| Rate | Value (per second) | Equivalent |
|------|--------------------|-----------|
| `hungerDecayRate` | `0.0000463` | ~6 h to drain |
| `happinessGainRate` | `0.0001389` | ~2 h to fill |
| `happinessDecayRate` | `0.0000463` | ~6 h to drain |
| `lowWellbeingThreshold` | `0.25` | alert threshold |

## SharedPreferences mirror

`PetStats._mirrorToPrefs()` writes **two** representations:

1. **Atomic bundle** `pet_stats_bundle` (full JSON) — preferred for
   rehydrating in a single write (lower risk of corruption from a mid-write kill).
2. **Individual keys** (`pet_hunger`, `pet_happiness`, `pet_last_update`, rates,
   threshold) — required by the **native Kotlin service**.

Missions: `MissionService` mirrors to `mission_bundle` (JSON) in addition to the
Hive box.

## Loading and migration

`PetStats.loadFromPrefs()`:

1. Tries to read `pet_stats_bundle`.
2. If it fails or does not exist, falls back to **legacy individual keys**
   (`pet_hunger`, etc.) and migrates to the bundle.
3. Applies **background updates** based on elapsed time and, if synced,
   applies the happiness buffer.

Missions: `MissionService._loadMissions()` reads Hive; if empty, migrates from
the legacy `mission_bundle`; if nothing is found, generates fresh missions.

## Serialized saving

Both `PetStats.save()` and `MissionService.save()` use a **save lock**
(chained `Future`) so that concurrent writes do not interleave, and `_canSave`/
`_isInitialized` flags to avoid overwriting good data with a partially loaded state.

## Other preferences

| Key | Service |
|-----|---------|
| `cloud_base_url`, `cloud_device_token` | `CloudService` |
| language | `LocaleService` |
| Flappy difficulty, SBR multiplier | `game_settings.dart` |
