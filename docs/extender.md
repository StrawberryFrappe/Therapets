---
title: Extender la App
parent: Para Desarrolladores
lang: es
nav_order: 8
description: "Guías prácticas: añadir comida, ropa, misiones, minijuegos y mascotas."
---

# Extender la App
{: .no_toc }

1. TOC
{:toc}

Recetas concretas para las extensiones más comunes. Indican el archivo a tocar.

## Añadir una comida

`lib/game/items/food_item.dart` → añade un `FoodItem` a `FoodMenu.items`:

```dart
FoodItem(
  id: 'taco',                       // único
  name: 'Taco',
  cost: 60,                         // plata
  hungerRestore: 0.3,              // 0.0–1.0
  happinessBonus: 0.15,           // 0.0–1.0
  assetPath: 'assets/images/food_taco.png',
),
```

Añade el PNG y decláralo si hace falta en `pubspec.yaml` (`assets/images/` ya está
incluido como carpeta).

## Añadir una prenda

`lib/game/items/clothing_item.dart` → añade un `ClothingItem` a
`ClothingCatalog.items`:

```dart
ClothingItem(
  id: 'hat_party',
  name: 'Party Hat',
  cost: 90,                         // oro
  slot: ClothingSlot.head,         // Bob solo tiene cabeza
  assetPath: 'assets/images/clothing_hat_party.png',
  happinessBonus: 0.05,
),
```

## Añadir un tipo de misión

1. Crea una subclase de `Mission` en `lib/game/missions/daily_missions.dart` con un
   **`typeId` Hive nuevo** (5, 6, …) y `@HiveField` para su estado.
2. Implementa `update(MissionContext)`, `toJson()`/`fromJson()`, `title`,
   `description`, `goldReward`, `happinessReward`.
3. Regenera adaptadores: `dart run build_runner build --delete-conflicting-outputs`.
4. Regístrala en `MissionService._generateDailyMissions()` (para que se genere) y en
   `_missionFromJson()` (para deserializar el bundle legacy).

> El `MissionContext` trae `dt`, `isDeviceSynced`, `minigameId`, `foodId`. Úsalo
> para decidir cuándo avanza tu misión.
{: .note }

## Añadir un minijuego

1. Crea una carpeta en `lib/game/minigames/<tu_juego>/` con su `FlameGame` y su
   pantalla (`*_screen.dart`), siguiendo el patrón de `flappy_bird/` u `orchestra/`.
2. Consume `DeviceService`: `events$` (gestos discretos como `ShakeEvent`) o
   `telemetry$` (inclinación continua).
3. Llama a `DeviceService.registerMinigameStart()` / `registerMinigameEnd()` para el
   estado de display y la misión *Game Time*.
4. Otorga plata vía `PetStats.addSilver()` y/o registra
   `CloudService.logMinigamePlayed()`.
5. Añade la entrada en el menú de juegos (`lib/screens/widgets/menus/game_menu.dart`).

## Añadir una mascota

1. Crea una subclase de `Pet` en `lib/game/pets/companions/` (mira
   `bob_the_blob.dart`): sprite/animación, `BodyType`, ranuras de ropa soportadas.
2. Conéctala en `VirtualPetGame` (`lib/game/virtual_pet_game.dart`).

> Si la nueva mascota soporta más ranuras de ropa que la cabeza, amplía
> `ClothingSlot` (`lib/game/pets/body_type.dart`) y la lógica de equipado en
> `PetStats`.
{: .note }

## Cambiar el endpoint de la nube por defecto

`lib/services/cloud/cloud_service.dart` — constante `_baseUrl` y el valor por
defecto en `_loadConfig()`. Mejor: deja el usuario configurarlo en Ajustes.
