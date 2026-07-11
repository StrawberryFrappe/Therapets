---
title: Misiones Diarias
parent: Guía del Usuario
lang: es
nav_order: 6
description: "Las tres misiones diarias, sus recompensas y el reinicio a medianoche."
---

# Misiones Diarias
{: .no_toc }

1. TOC
{:toc}

Cada día se generan **3 misiones**. Completarlas da **oro** (para ropa) y un poco
de **felicidad**. Se **reinician** cuando cambia el día (a medianoche, hora local).

![Misiones diarias]({{ '/assets/images/screenshots/06_missions.png' | relative_url }})
*Las tres misiones del día con su progreso y recompensa en oro.*

## Las tres misiones

| Misión | Objetivo | Recompensa |
|--------|----------|:----------:|
| **Sync Master** | Estar sincronizado **120 minutos** en el día | 🪙 50 oro + felicidad |
| **Game Time** | Jugar **3** minijuegos | 🪙 30 oro + felicidad |
| **Yummy Time** | Alimentar a Bob **3** veces | 🪙 20 oro + felicidad |

- **Sync Master** avanza solo mientras estás *Sincronizado* — incluso con la app
  en segundo plano (el progreso se recupera al volver a abrir).
- **Game Time** cuenta cada partida de cualquier minijuego.
- **Yummy Time** cuenta cada vez que alimentas a Bob.

## Reinicio diario

Al abrir la app en un día nuevo, las misiones del día anterior se reemplazan por
un set fresco. El progreso no completado se pierde; el oro ya ganado se conserva.

> El progreso de misiones se guarda de forma resistente (Hive + respaldo en
> SharedPreferences) para sobrevivir cierres del sistema. Detalle en
> [Modelo de Datos](modelo_datos.html).
{: .note }
