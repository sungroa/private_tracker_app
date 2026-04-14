# Engineering & Development Guide

This guide provides a deep dive into the technical standards and architectural patterns of the Private Tracker App.

## 🏛 Clean Architecture Standards

We adhere to a strict 3-tier Clean Architecture to ensure business logic is isolated, testable, and reusable.

```mermaid
graph TD
    subgraph Presentation
        W["Widgets (Flutter)"] --> P["Providers (State)"]
    end
    
    subgraph Domain
        P --> UC["Use Cases (Business Logic)"]
        UC --> M["Models (Pure Dart)"]
        UC --> C["Calculators (Pure Dart)"]
    end
    
    subgraph Data
        UC --> R["Repository Interfaces"]
        R --> RI["Repository Impl"]
        RI --> DS["Data Sources (Hive/Cloud)"]
        RI --> Mapper["Model Mappers (DTO)"]
    end

    style Presentation fill:#f9f,stroke:#333,stroke-width:2px
    style Domain fill:#bbf,stroke:#333,stroke-width:2px
    style Data fill:#bfb,stroke:#333,stroke-width:2px
```

### 1. Domain Layer (`lib/domain/`)
- **Content**: Pure Dart models, Repository interfaces, and specialized Calculators.
- **Constraints**: **ZERO** dependencies on Flutter, Hive, or any external framework.
- **Key Files**: 
  - `models/`: Immutable business entities using `@immutable`.
  - `calculators/`: Logic for predictions and trends analysis.

### 2. Data Layer (`lib/data/`)
- **Content**: Persistence implementations, DTOs, and External Service clients.
- **Pattern**: The **Repository Pattern** is used to abstract storage details. DataSources handle low-level Hive ops.
- **DTO Mapping**: We use a explicit mapping layer (`model_mapper.dart`) to convert between Hive-compatible DTOs and pure Domain models.

### 3. Presentation Layer (`lib/presentation/`)
- **Content**: Flutter widgets, UI-only theme logic, and Providers.
- **State Management**: Selective rebuilds using `Selector` or `Consumer` to ensure 60FPS performance on heavy calendar views.

---

## ⚡ Thread-Safety & Isolate Architecture

To ensure a buttery-smooth 60FPS user experience, we offload all CPU-intensive operations to background **Isolates** using `Isolate.run`.

- **Trends Analysis**: `CycleProvider` uses an isolate to calculate complex trends and map them to calendar events.
- **Sync Parsing**: Large encrypted payloads are decrypted and parsed into DTOs in a background isolate.
- **LWW Merging**: The conflict resolution logic (Last-Write-Wins) for multi-device sync runs entirely off the main thread.

---

## 🔄 Data Synchronization (LWW Merge)

We use a record-level **Last-Write-Wins (LWW)** strategy for offline-first synchronization.

```mermaid
sequenceDiagram
    participant LS as Local Storage
    participant UC as SyncUseCase
    participant ISO as Background Isolate
    participant CS as Cloud Storage

    UC->>CS: Fetch Cloud Checksum
    UC->>CS: Download Encrypted Payload
    UC->>LS: Fetch Local Records
    UC->>ISO: Merge(Local, Cloud)
    Note over ISO: Compare 'updatedAt' timestamps<br/>per record ID
    ISO-->>UC: Merged Map
    UC->>LS: Persist Merged State
    UC->>CS: Upload Unified Snapshot
```

---

## 🛡 Security & Encryption Protocols

Private Tracker uses a Multi-Layered Encryption approach:

1.  **Encryption at Rest**: AES-256-SIC via `hive_flutter`.
2.  **Key Management**: 256-bit AES master key stored in KeyChain (iOS) or KeyStore (Android).
3.  **Authenticated Backup**: Password-based key derivation using PBKDF2 with HMAC-SHA256 integrity verification.

For a full security audit, see [SECURITY.md](file:///home/sungroa/git/private_tracker_app/SECURITY.md).

---

## 🧪 Testing Protocol

A feature is considered **Incomplete** if it lacks associated tests.

- **Domain Tests**: Test all calculators and model transformations in `test/domain/`.
- **Data Tests**: Verify storage serialization and encryption/backup flows in `test/data/`.

---

## 🛠 Project Lifecycle & DI

- **Service Locator**: We use `GetIt` (in `service_locator.dart`) for dependency injection of repositories and use cases.
- **App Initializer**: `lib/core/services/app_initializer.dart` coordinates the parallel startup of storage, providers, and initial sync.
