# Project Manifest: Private Tracker App

- **Session ID:** 0ac4c392-2c9c-4c5d-8998-84cad20dd59a
- **Last Updated:** 2026-04-05T07:15:00Z
- **Session Health:** NOMINAL (Phase 2 Complete)
- **Project Root:** /home/sungroa/git/private_tracker_app
- **STRICT_CONSTRAINTS:**
    - **Privacy-First**: No data sent to any server. Local only.
    - **Zero Tech Debt**: Principal Engineer standards. Pure domain layer.
    - **Premium Aesthetics**: Glassmorphic UI is mandatory.
    - **Security**: Authenticated encryption for all data sharing.

### Project Status: **STABLE / CLEAN**

- **Audit Report**: `brain/0ac4c392-2c9c-4c5d-8998-84cad20dd59a/audit_report.md`
- **Current Walkthrough**: `brain/0ac4c392-2c9c-4c5d-8998-84cad20dd59a/walkthrough.md`
- **Next Phase Plan**: `brain/0ac4c392-2c9c-4c5d-8998-84cad20dd59a/implementation_plan.md`

## Progress Tracking

### [x] Phase 1: Initial Audit & Critical Fixes
- [x] Fixed Hive key corruption (C-4) and CSV export crash (N-8).
- [x] Removed deep-link logging (W-7) and redundant UI code (W-3).
- [x] Refactored Custom Tags into a decoupled `TagProvider` and `TagRepository` (C-2).

### [x] Phase 2: Mandatory Audit Refactor (Hardening & Decoupling)
- [x] **Security**: Upgraded Partner Sharing to **AES-SIC + HMAC-SHA256** (W-6).
- [x] **Architecture**: Decoupled all domain models from `HiveObject` framework (C-1).
- [x] **Organization**: Extracted `SymptomLog` into a dedicated file (N-1).
- [x] **Performance**: Removed `TrendsProvider`, merged analytics into `CycleProvider` (W-1).
- [x] **Robustness**: Fixed TOCTOU race (W-5) and implemented migration flags (N-6).
- [x] **UI Proofing**: Resolved all BuildContext async gap warnings and added deletion feedback (W-4).

### [ ] Phase 3: Deep Refactor (God Class Extraction)
- [ ] Extract `EncryptedStorageService` responsibilities into modular sub-services (C-3).
- [ ] Upgrade Backup/Restore logic to Authenticated Encryption.

## Handoff Payload

### Project State
The codebase is currently in a "Zero Technical Debt" state. All domain models are PURE Dart objects. Persistence is handled by `EncryptedStorageService` via repositories. State management uses `Provider` with a root-level `MultiProvider` configuration.

### Critical Files
- `lib/data/storage/encrypted_storage_service.dart`: The current bottleneck/target for Phase 3.
- `lib/domain/models/symptom_log.dart`: Newly extracted model.
- `lib/domain/services/partner_sharing_service.dart`: Hardened security logic.
- `lib/presentation/providers/cycle_provider.dart`: Consolidated analytics logic.

### Blockers / Lessons
- **Async Safety**: Always pre-fetch Providers before async gaps (like `showDialog`) to avoid `use_build_context_synchronously` lints.
- **Hive Decoupling**: Removing `HiveObject` enables cleaner unit testing of the domain layer but requires manual key-based `put`/`delete` in the data layer.

### Prompt I should use. (Delete these before sending)

Role: Principal Staff Software Engineer & Code Reviewer.
Project: Private Tracker App (Flutter).
Current Status: Phase 2 of the Architectural Audit is COMPLETE. 
- Domain models (CycleEvent, SymptomLog, CustomTag) are PURE Dart objects (Decoupled from HiveObject).
- Security Hardening: Partner sharing now uses AES-SIC + HMAC-SHA256.
- Redundancy Fix: TrendsProvider deleted; all logic consolidated in CycleProvider.

OBJECTIVE: Execute Phase 3 of the Audit Refactor.
1. Read the Implementation Plan: brain/0ac4c392-2c9c-4c5d-8998-84cad20dd59a/implementation_plan.md
2. Goal: Systematically extract responsibilities from the 'EncryptedStorageService' God Class into modular sub-services (SecureKeyStorage, BackupService, MigrationManager, etc.).
3. Standard: Zero Technical Debt. Maintain 100% test pass rate.

Please initialize by reading the project_manifest.md and the Phase 3 implementation_plan.md.
