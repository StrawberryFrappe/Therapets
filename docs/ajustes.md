---
title: Ajustes
parent: Guía del Usuario
lang: es
nav_order: 9
description: "Configurar la nube, el idioma, las tasas de estadísticas y las herramientas de desarrollo."
---

# Ajustes
{: .no_toc }

1. TOC
{:toc}

![Pantalla de ajustes]({{ '/assets/images/screenshots/07_settings.png' | relative_url }})
*Ajustes: estado de la mascota, economía (debug), idioma, escaneo de dispositivos y ajustes avanzados.*

## Dispositivo

- **Escanear / conectar / olvidar** el sensor BLE (botón **Scan for devices**).
- Acceso a las [pantallas de sensores](sensores.html).

## Nube (ThingsBoard)

Para enviar telemetría a un servidor ThingsBoard:

1. Entra en **Ajustes → Configuración avanzada**.
2. Introduce la **URL base** (ej. `http://TU_IP_THINGSBOARD:8080`).
3. Introduce el **token del dispositivo** — puedes **escanearlo por QR** con la
   cámara en lugar de teclearlo.
4. La app empieza a **encolar y enviar** datos automáticamente cuando hay conexión.

![Ajustes avanzados]({{ '/assets/images/screenshots/08_advanced.png' | relative_url }})
*Ajustes avanzados: actualizaciones, tasas de estadísticas, umbral de bienestar, sincronización a la nube y herramientas de debug.*

> Si no configuras la nube, la app funciona igual: simplemente no envía telemetría.
> Detalle del formato en [Telemetría y Nube](telemetria.html).
{: .note }

## Idioma

Therapets detecta el idioma del dispositivo (Español / Inglés) y permite
cambiarlo manualmente con los botones de bandera.

## Tasas de estadísticas y Dev Tools

La sección de desarrollo permite ajustar el ritmo del juego y depurar:

- **Tasas** de decaimiento/ganancia de hambre y felicidad.
- Dificultad de **Flappy** y multiplicador de **SBR**.
- **Reiniciar** estadísticas o misiones.
- Activar/desactivar la sincronización a la nube.
- **Terminal de telemetría** para ver los paquetes en crudo.

> Las Dev Tools están pensadas para pruebas. Cambiar las tasas afecta directamente
> la velocidad del juego.
{: .warning }
