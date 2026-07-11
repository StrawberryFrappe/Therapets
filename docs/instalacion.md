---
title: Instalación
parent: Guía del Usuario
lang: es
nav_order: 1
description: "Descarga, instala y otorga permisos a Therapets en Android."
---

# Instalación
{: .no_toc }

1. TOC
{:toc}

## Requisitos

- Android (la app declara permisos modernos de Bluetooth de Android 12+; funciona
  en versiones anteriores con permiso de ubicación).
- El sensor **M5-IMU** (variante MAX30100 o GY906).
- *(Opcional)* Acceso a un servidor ThingsBoard si vas a usar la nube.

## Canales de descarga

Therapets se publica como APK en las
[Releases de GitHub](https://github.com/StrawberryFrappe/Therapets/releases).
Hay tres canales:

| Canal | Tipo | Para quién |
|-------|------|-----------|
| **Stable** | Producción | Uso normal. [Última APK estable](https://github.com/StrawberryFrappe/Therapets/releases/latest/download/app-release.apk) |
| **Nightly** | Desarrollo (`dev`) | Probar lo último, puede fallar. |
| **Unstable** | Experimental | Funciones a medias. |

> Las versiones Nightly y Unstable son *prereleases*. Instálalas solo si quieres
> probar cambios nuevos.
{: .warning }

## Instalar el APK

1. Descarga el APK del canal elegido en tu teléfono.
2. Ábrelo. Android pedirá permitir **instalar apps de orígenes desconocidos**
   para tu navegador/gestor de archivos — actívalo.
3. Confirma la instalación.

> Therapets usa el permiso `REQUEST_INSTALL_PACKAGES` para poder ofrecer
> actualizaciones dentro de la app. Ver [Actualizar la app](actualizacion.html).
{: .note }

## Permisos en el primer arranque

Al abrir la app por primera vez te pedirá varios permisos. Todos son necesarios
para el funcionamiento BLE en segundo plano:

| Permiso | Para qué |
|---------|----------|
| **Bluetooth** (escanear, conectar) | Encontrar y enlazar el sensor M5. |
| **Ubicación** | Requerido por Android para escanear BLE en versiones antiguas. |
| **Notificaciones** | Notificación persistente del servicio + avisos de bienestar bajo. |
| **Cámara** | Escanear el código QR del *token* de la nube (opcional). |
| **Ignorar optimización de batería** | Evita que el sistema mate el servicio BLE en segundo plano. |

> En teléfonos con capas agresivas (Xiaomi, Huawei, Samsung, etc.) acepta la
> exención de optimización de batería; si no, el sensor se desconectará cuando la
> pantalla se apague.
{: .warning }

## Siguiente paso

Con la app instalada y los permisos concedidos, continúa con
[Conexión BLE](configuracion_ble.html).
