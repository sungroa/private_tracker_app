# Release Notes - Version 1.1.5+11

**Release Date:** June 14, 2026  
**Comparison:** Version 1.1.5+11 vs. Version 1.1.4+10 (Previous Release)

---

## 📋 Overview

Version 1.1.5+11 brings significant enhancements to user accessibility, biological forecasting, application security, and developer onboarding. The main highlights of this release include full screen-reader accessibility for blind users, an adaptive multi-cycle forecasting engine, secret sanitization for the public release, and distinct visual/build setups for development workflows.

---

## 🚀 Key Enhancements

### 1. Screen-Reader Accessibility for Blind Users
This release achieves full accessibility compatibility with screen readers (e.g., TalkBack and VoiceOver) across all key application paths:
*   **Accessible Calendar Navigation:** Day cells in the custom calendar grid are wrapped in custom semantics that synthesize local logs, bleeding status, predictions, and symptom notes into a single, cohesive spoken description (e.g., *"Monday, June 15, 2026, Selected, Predicted period, Symptoms: cramps, headache"*).
*   **Semantic Chart Summaries:** The Basal Body Temperature (BBT) and mood trend charts automatically compile and speak aggregated statistical summaries (e.g., number of recordings, average values, low/high points, and latest logs) to non-visual users.
*   **Interactive Input Sheets:** Accessibility elements like custom labels, slider levels, and accessibility summaries are implemented for daily symptom logs, cycle logs, and donation screens.

### 2. Adaptive Multi-Cycle Prediction Engine
The cycle forecasting engine is upgraded from a single-cycle forecast to an adaptive multi-cycle engine:
*   **Multi-Cycle Projections:** Calculates up to 4 future cycles depending on the depth of the user's recorded cycle history:
    *   *1 recorded cycle:* 1 projection (Cold Start)
    *   *2–3 recorded cycles:* 2 projections
    *   *4–7 recorded cycles:* 3 projections
    *   *8+ recorded cycles:* 4 projections (ARIMA Engine active)
*   **Expanded Calendar Views:** Bleeding indicators and fertility windows are projected and visible across multiple future months in the calendar grid.
*   **Deduplicated Fertility Projections:** Flat-maps and deduplicates projected fertility windows across all future cycles for clean visual calendar grid rendering.

### 3. Secret Sanitization & Security
To prepare the repository for public release, hardcoded credentials have been securely externalized:
*   **Environment Configuration:** The Google OAuth Web Client ID has been migrated from hardcoded code constants to environment definitions loaded at compile time via `String.fromEnvironment('GOOGLE_CLIENT_ID')`.
*   **Contributors Template:** A template `dart-defines.json.example` is provided, and the local configuration file is added to `.gitignore` to prevent credential exposure in version control.
*   **Onboarding Assertions:** Startup checks halt development builds with clear troubleshooting messages if target environment secrets are missing.

### 4. Development & QA Workflows
*   **Debug Launcher Icons:** Android debug builds automatically overlay a prominent orange "D" badge on the launcher icon and apply a distinct burnt-orange adaptive background, keeping release builds clean and making it easy to identify development builds on-device.
*   **Shared Debug Keystore:** A pre-configured `debug.keystore` is committed to the repository to ensure consistent signing keys across dev machines, preventing signature mismatch errors during local test runs.

---

## 📝 Commits Included in this Release

*   `f855891` - Incrementing the app version to 1.1.5+11.
*   `451d50d` - feat: implement full screen-reader accessibility for blind users (#10)
*   `956b70e` - feat: extend prediction engine to 3–4 future cycles (#9)
*   `b5e3cf4` - Feature/debug launcher icon (#8)
*   `07409f3` - chore: explicitly configure and document shared debug keystore (#7)
*   `30d7901` - docs: update README with dart-defines.json setup and build flags
*   `65a39cd` - security: move Google OAuth client ID to gitignored dart-defines.json
*   `8b84eed` - chore: clean up temporary test and log files and update gitignore

---

## 🧪 Testing & Verification Summary

*   **Static Analysis:** `flutter analyze` passes with zero issues.
*   **Unit & Widget Tests:** Expanded test suite (now totaling 233 tests) passes successfully.
*   **Accessibility Tests:** Added automated semantics verification in `test/presentation/accessibility_test.dart` to assert correct behavior of `SummaryTrendCard`, `SummaryLineChart`, and `BbtChart`.
