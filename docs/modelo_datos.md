---
title: Modelo de Datos y Persistencia
parent: Para Desarrolladores
lang: es
nav_order: 6
description: "Cajas Hive, adaptadores, espejo en SharedPreferences y migración."
---

# Modelo de Datos y Persistencia
{: .no_toc }

1. TOC
{:toc}

Therapets usa **Hive** (NoSQL local) como almacén principal y **SharedPreferences**
como espejo/respaldo (necesario para el servicio nativo y para rehidratación
atómica tras cierres del sistema).

## Cajas Hive

| Caja | Contenido | Claves |
|------|-----------|--------|
| `pet_stats_box` | `PetStats` (índice 0) | estadísticas, monedas, inventario, ropa |
| `missions_box` | misiones del día | `missions`, `lastResetMs` |

## Adaptadores (typeId)

| Tipo | typeId | Archivo |
|------|:------:|---------|
| `PetStats` | 1 | `lib/game/pets/pet_stats.dart` (+ `.g.dart`) |
| `SyncDurationMission` | 2 | `lib/game/missions/daily_missions.dart` |
| `MinigamePlayMission` | 3 | `daily_missions.dart` |
| `FeedPetMission` | 4 | `daily_missions.dart` |

> Los `*.g.dart` se generan con `build_runner` (ver [Entorno](entorno.html)). No
> reutilices un `typeId` para otro tipo: rompería la lectura de datos existentes.
{: .warning }

## Modelo PetStats

Campos persistidos (`@HiveField`): hambre, felicidad, buffer de felicidad, tasas
(hambre/felicidad gain/decay), timestamp de última actualización, umbral de
bienestar, oro, plata, ropa desbloqueada, ropa equipada (mapa ranura→id),
inventario de comida (mapa id→cantidad).

Tasas por defecto:

| Tasa | Valor (por segundo) | Equivale a |
|------|---------------------|-----------|
| `hungerDecayRate` | `0.0000463` | ~6 h a vaciarse |
| `happinessGainRate` | `0.0001389` | ~2 h a llenarse |
| `happinessDecayRate` | `0.0000463` | ~6 h a vaciarse |
| `lowWellbeingThreshold` | `0.25` | umbral de aviso |

## Espejo en SharedPreferences

`PetStats._mirrorToPrefs()` escribe **dos** representaciones:

1. **Bundle atómico** `pet_stats_bundle` (JSON completo) — preferido para
   rehidratar de una sola escritura (menos riesgo de corrupción por kill a mitad).
2. **Claves individuales** (`pet_hunger`, `pet_happiness`, `pet_last_update`, tasas,
   umbral) — requeridas por el **servicio nativo Kotlin**.

Misiones: `MissionService` espeja a `mission_bundle` (JSON) además de la caja Hive.

## Carga y migración

`PetStats.loadFromPrefs()`:

1. Intenta leer `pet_stats_bundle`.
2. Si falla o no existe, cae a **claves legacy** individuales (`pet_hunger`, etc.) y
   migra al bundle.
3. Aplica **actualizaciones en segundo plano** según el tiempo transcurrido y, si
   estaba sincronizado, aplica el buffer de felicidad.

Misiones: `MissionService._loadMissions()` lee Hive; si está vacío, migra desde el
`mission_bundle` legacy; si no hay nada, genera misiones frescas.

## Guardado serializado

Tanto `PetStats.save()` como `MissionService.save()` usan un **lock de guardado**
(`Future` encadenado) para que escrituras concurrentes no se entrelacen, y *flags*
`_canSave`/`_isInitialized` para no sobrescribir datos buenos con un estado a medio
cargar.

## Otras preferencias

| Clave | Servicio |
|-------|----------|
| `cloud_base_url`, `cloud_device_token` | `CloudService` |
| idioma | `LocaleService` |
| dificultad Flappy, multiplicador SBR | `game_settings.dart` |
