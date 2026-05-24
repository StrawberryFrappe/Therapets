# Therapets Architecture Mapping

## Core Systems & Data Flow

The architecture of Therapets is strictly divided into layers, ensuring that the Flutter UI and Flame Game Engine are decoupled from low-level hardware intricacies.

```mermaid
classDiagram
    %% Core Bootstrapping & Lifecycle
    class AppBootstrapper {
        +init() Future<BootstrapResult>
    }
    class AppLifecycleManager {
        +didChangeAppLifecycleState(state)
        -handleSuspend()
        -handleResume()
    }
    
    %% Service Layer (Hardware & Data)
    class BluetoothService {
        <<Native / Foreground>>
        +init()
        +connect(device)
        +startScan()
        +incomingRaw$ : Stream
        -_platform : MethodChannel
    }

    class DeviceService {
        +events$ : Stream<DeviceEvent>
        +telemetry$ : Stream<TelemetryData>
    }

    class BioSignalProcessor {
        +processBytes()
    }

    class CloudService {
        +logEvent(type, payload)
        +flushQueue()
    }
    
    class MissionManager {
        <<Native / Kotlin>>
        +evaluateMissions()
    }

    %% Service Relationships
    DeviceService --> BluetoothService : consumes raw streams
    DeviceService --> BioSignalProcessor : decodes payloads
    BleForegroundService --> MissionManager : invokes every minute
    MissionManager --> CloudService : uses for HTTP logging

    %% Game Layer
    class VirtualPetGame {
        +Pet currentPet
    }
    class PetStats {
        +double hunger
        +double happiness
    }
    class FlappyBirdGame {
        -onDeviceEvent(event)
    }

    %% App Structure
    AppLifecycleManager --> DeviceService : informs of suspend/resume
    AppBootstrapper --> DeviceService : instantiates
    VirtualPetGame --> PetStats : reads
    FlappyBirdGame --> DeviceService : listens to (events$)
```

## Service Layer Breakdown
1. **`lib/services/device/`**:
   - `bluetooth_service.dart`: Low-level BLE management (scanning, connecting, MethodChannels to Foreground Service).
   - `device_service.dart`: High-level abstraction. Emits clean `events$` and `telemetry$`.
   - `bio_signal_processor.dart` & `temperature_signal_processor.dart`: Decode raw byte payloads based on the connected hardware variant.
2. **`lib/services/cloud/`**:
   - `cloud_service.dart`: Manages the HTTP queue for Thingsboard.
3. **`lib/services/notifications/`**:
   - Manages the interaction with the `FlutterForegroundTask` plugin for the `therapets_fg` channel.
4. **Native Android (`app/src/main/kotlin/`)**:
   - `BleForegroundService.kt`: Handles BLE connection and background telemetry bridging.
   - `CloudManager.kt`: Native HTTP poster for background syncing.
   - `MissionManager.kt`: Native JSON Mission Engine that evaluates metric goals natively to survive Flutter Engine suspension.

## Unified Sync State (Source of Truth)
- The **Native Android foreground service (`BleForegroundService`)** is the absolute source of truth for connection state.
- Flutter `DeviceService.onAppResumed()` must **NEVER** overwrite or nuke state; it must read the canonical state from Native.
- Refer to `AGENTS.md` for specific handling of the **10-second IoT sleep cycle** and the **15-second Grace Window**.
