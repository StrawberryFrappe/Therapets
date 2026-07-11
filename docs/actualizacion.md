---
title: Actualizar la App
parent: Guía del Usuario
lang: es
nav_order: 10
description: "Canales de actualización y proceso de actualización dentro de la app."
---

# Actualizar la App
{: .no_toc }

1. TOC
{:toc}

## Canales

Therapets se distribuye en tres canales (ver [Instalación](instalacion.html)):

- **Stable** — versiones de producción (`vX.Y.Z`).
- **Nightly** — compilaciones de la rama `dev` (`vX.Y.Z-nightly.N`).
- **Unstable** — compilaciones experimentales (`vX.Y.Z-unstable.N`).

## Actualización dentro de la app

La app comprueba si hay una versión más reciente en las *Releases* de GitHub.
Cuando hay una disponible, aparece un **icono de actualización** en el HUD.

1. Pulsa el icono de actualización.
2. La app descarga el APK de la nueva versión.
3. Se lanza el instalador de Android (gracias al permiso
   `REQUEST_INSTALL_PACKAGES`).
4. Confirma para instalar sobre la versión actual.

> Tus datos (mascota, monedas, misiones) se conservan entre actualizaciones: se
> guardan en almacenamiento local con migración automática de formatos antiguos.
{: .note }

## Actualización manual

También puedes descargar el APK más reciente directamente desde las
[Releases de GitHub](https://github.com/StrawberryFrappe/Therapets/releases) e
instalarlo encima.
