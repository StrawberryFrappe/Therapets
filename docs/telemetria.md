---
title: "Config. Telemetría"
lang: es
---

# Configuración de Telemetría (Desarrolladores)

Para apuntar la telemetría del dispositivo a tu propio servidor o instancia de nube (como Thingsboard), debes configurar la IP y el Device ID.

## Configuración Manual

1. En la aplicación, navega a **Ajustes > Ajustes Avanzados**.
2. Desplázate hasta la sección **Nube (Cloud)**.
3. Toca en el botón para escanear y escanea el código QR de tu dispositivo físico para obtener su **Device ID**.
4. En el campo de texto inferior, escribe manualmente la dirección **IP** del servidor host donde se debe enviar la telemetría.
5. Guarda los cambios. A partir de este momento, todas las peticiones HTTP/MQTT en segundo plano usarán estos parámetros.

![Configuración de Telemetría en Ajustes Avanzados](/assets/images/telemetry_config_es.png)
