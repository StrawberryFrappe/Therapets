---
title: Minijuegos
parent: Guía del Usuario
lang: es
nav_order: 7
description: "Los minijuegos controlados por movimiento y cómo se juegan."
---

# Minijuegos
{: .no_toc }

1. TOC
{:toc}

Los minijuegos usan el **movimiento del sensor** (sacudidas e inclinación) como
control. Jugar otorga **plata** (para comida) y cuenta para la misión **Game Time**.

![Menú de juegos]({{ '/assets/images/screenshots/05_game_menu.png' | relative_url }})
*El menú de juegos: Flappy Bob, Orchestra, donut.dart y SBR.*

## Flappy Bob

Estilo *Flappy Bird*. Bob salta entre tuberías.

- **Control:** una **sacudida** del sensor hace saltar a Bob (evento discreto de
  movimiento). También responde al toque en pantalla.
- **Recompensa:** monedas de **plata** según lo lejos que llegues.
- **Dificultad:** ajustable (Fácil/Medio/Difícil/Imposible) antes de empezar.

![Flappy Bob]({{ '/assets/images/screenshots/09_flappy.png' | relative_url }})
*Pantalla de inicio de Flappy Bob con selector de dificultad. Sin sensor, "Toca para saltar".*

## Orchestra

Herramienta creativa tipo theremín con músicos-mascota.

- **Control:** **inclina** el dispositivo de forma continua para variar tono y
  volumen (usa la telemetría continua del sensor).
- Sin presión: es para experimentar con sonido.

## Donut

Minijuego de un dónut 3D que puedes rotar.

- **Control:** rotación 3D (renderizado con `flutter_cube`).

## SBR (rompe-ladrillos)

Estilo *Breakout* controlado por movimiento.

- **Control:** mueve la paleta/pelota con la inclinación.
- **Dificultad:** multiplicador ajustable en [Ajustes](ajustes.html).

> ¿Sin sensor conectado? Algunos minijuegos siguen jugables con controles en
> pantalla, pero la experiencia completa requiere el sensor M5.
{: .tip }
