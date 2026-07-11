---
title: Solución de Problemas
parent: Guía del Usuario
lang: es
nav_order: 11
description: "Preguntas frecuentes y soluciones a problemas comunes."
---

# Solución de Problemas y FAQ
{: .no_toc }

1. TOC
{:toc}

## Conexión BLE

**El sensor no aparece al escanear.**
Verifica que esté encendido, con batería, y que el Bluetooth del teléfono esté
activo. Acércalo al teléfono y vuelve a escanear.

**Se conecta pero el estado no llega a "Sincronizado".**
"Sincronizado" requiere **humano detectado**. Lleva el sensor en contacto con la
piel (muñeca/antebrazo) y espera unos segundos a que estabilice la lectura.

**Se desconecta cuando apago la pantalla.**
Concede la **exención de optimización de batería** (Ajustes del sistema → Batería).
En teléfonos Xiaomi/Huawei/Samsung suele ser obligatorio.

**Tras reiniciar el teléfono no reconecta.**
La app reanuda el servicio al arrancar el sistema, pero en algunos teléfonos hay
que **abrir la app una vez** tras el reinicio.

## Mascota y estadísticas

**La felicidad baja aunque estoy sincronizado.**
Si el **hambre está por debajo del 25 %**, la felicidad baja igualmente.
Alimenta a Bob.

**Estuve sincronizado con la app cerrada, ¿perdí el progreso?**
No. La felicidad se acumula en un *buffer* en segundo plano y se aplica al abrir
la app. Las misiones también recuperan su progreso.

## Nube

**Configuré la nube pero no llegan datos.**
Revisa la URL base y el token. La app **encola** los eventos y los envía cuando
hay conexión; si falla 5 veces, descarta el evento. Ver [Telemetría](telemetria.html).

## Actualizaciones

**No puedo instalar la actualización.**
Permite **instalar apps de orígenes desconocidos** para la app/instalador cuando
Android lo pida.

## Datos

**¿Pierdo mi mascota al actualizar?**
No. Los datos persisten localmente con migración automática.

---

¿No está tu problema aquí? Abre un *issue* en
[GitHub](https://github.com/StrawberryFrappe/Therapets/issues).
