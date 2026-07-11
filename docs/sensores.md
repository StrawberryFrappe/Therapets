---
title: Pantallas de Sensores
parent: Guía del Usuario
lang: es
nav_order: 8
description: "Cómo leer las pantallas del oxímetro (MAX30100) y de temperatura (GY906)."
---

# Pantallas de Sensores
{: .no_toc }

1. TOC
{:toc}

Según la variante de sensor enlazada, la app ofrece una pantalla dedicada con la
lectura en vivo y una forma de onda. Se accede desde **Ajustes**.

## Oxímetro de pulso (MAX30100)

Muestra:

- **BPM** — pulsaciones por minuto.
- **SpO₂** — saturación de oxígeno (%).
- **Forma de onda** — señal IR filtrada, tipo electrocardiograma.

Para una lectura válida:

- Coloca el sensor en contacto firme con la **muñeca o el dedo**.
- Espera unos segundos a que se estabilice (detección de dedo + pulso sostenido).
- Rango humano considerado: **40–200 BPM** y **SpO₂ ≥ 85 %**.

## Temperatura (GY906)

Muestra:

- **Temperatura** corporal en °C.
- **Tendencia / forma de onda** de la temperatura.

Para una lectura válida:

- Apoya el sensor sobre la piel del **antebrazo**.
- Rango de detección humana: **29,7 °C – 41 °C** (piel del antebrazo, más fría que
  la temperatura central).
- Una lectura de 0 indica sensor desconectado o con error.

> Estas pantallas muestran la **última lectura válida** durante pausas breves de
> transmisión (hasta ~60 s), para que el valor no parpadee.
{: .note }

> **Nota sobre las capturas:** las imágenes de estas pantallas se tomaron en un
> emulador sin sensor físico, por lo que aparecen en estado *desconectado /
> buscando*. Con el sensor M5 real mostrarían datos en vivo.
{: .warning }
