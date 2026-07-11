---
title: Extending the App
parent: Developer Docs
lang: en
nav_order: 8
description: "Practical guides: adding food, clothing, missions, minigames, and pets."
---

# Extending the App
{: .no_toc }

1. TOC
{:toc}

Concrete recipes for the most common extensions. Each one points to the file to touch.

## Adding a food item

`lib/game/items/food_item.dart` → add a `FoodItem` to `FoodMenu.items`:

```dart
FoodItem(
  id: 'taco',                       // unique
  name: 'Taco',
  cost: 60,                         // silver
  hungerRestore: 0.3,              // 0.0–1.0
  happinessBonus: 0.15,           // 0.0–1.0
  assetPath: 'assets/images/food_taco.png',
),
```

Add the PNG and declare it if needed in `pubspec.yaml` (`assets/images/` is already
included as a folder).

## Adding a clothing item

`lib/game/items/clothing_item.dart` → add a `ClothingItem` to
`ClothingCatalog.items`:

```dart
ClothingItem(
  id: 'hat_party',
  name: 'Party Hat',
  cost: 90,                         // gold
  slot: ClothingSlot.head,         // Bob only has a head
  assetPath: 'assets/images/clothing_hat_party.png',
  happinessBonus: 0.05,
),
```

## Adding a mission type

1. Create a subclass of `Mission` in `lib/game/missions/daily_missions.dart` with a
   **new Hive `typeId`** (5, 6, …) and `@HiveField` for its state.
2. Implement `update(MissionContext)`, `toJson()`/`fromJson()`, `title`,
   `description`, `goldReward`, `happinessReward`.
3. Regenerate adapters: `dart run build_runner build --delete-conflicting-outputs`.
4. Register it in `MissionService._generateDailyMissions()` (so it gets generated)
   and in `_missionFromJson()` (to deserialize the legacy bundle).

> `MissionContext` provides `dt`, `isDeviceSynced`, `minigameId`, `foodId`. Use it
> to decide when your mission should advance.
{: .note }

## Adding a minigame

1. Create a folder at `lib/game/minigames/<your_game>/` with its `FlameGame` and its
   screen (`*_screen.dart`), following the pattern of `flappy_bird/` or `orchestra/`.
2. Consume `DeviceService`: `events$` (discrete gestures like `ShakeEvent`) or
   `telemetry$` (continuous tilt).
3. Call `DeviceService.registerMinigameStart()` / `registerMinigameEnd()` for the
   display status and the *Game Time* mission.
4. Grant silver via `PetStats.addSilver()` and/or log
   `CloudService.logMinigamePlayed()`.
5. Add the entry to the game menu (`lib/screens/widgets/menus/game_menu.dart`).

## Adding a pet

1. Create a subclass of `Pet` in `lib/game/pets/companions/` (see
   `bob_the_blob.dart`): sprite/animation, `BodyType`, supported clothing slots.
2. Wire it into `VirtualPetGame` (`lib/game/virtual_pet_game.dart`).

> If the new pet supports more clothing slots than just the head, extend
> `ClothingSlot` (`lib/game/pets/body_type.dart`) and the equip logic in
> `PetStats`.
{: .note }

## Changing the default cloud endpoint

`lib/services/cloud/cloud_service.dart` — the `_baseUrl` constant and the default
value in `_loadConfig()`. Better: let the user configure it in Settings.
