# Release Notes - Version 1.1.6+12

**Release Date:** July 26, 2026  
**Comparison:** Version 1.1.6+12 vs. Version 1.1.5+11 (Previous Release)

---

## 📋 Overview

Version 1.1.6+12 completes a comprehensive modernization of the application's underlying ecosystem, upgrading to Flutter SDK 3.44.8 and Dart 3.12.2 while updating the native Android toolchain to Android Gradle Plugin (AGP) 8.11.1, Kotlin 2.2.20, and Gradle 8.14. This release updates core libraries (including `app_links` 7.2.1 and `flutter_markdown_plus` 1.0.7), refactors code for Dart 3.12 standards, and enforces Flutter 3.44 Material Ink rendering compliance.

---

## 🚀 Key Enhancements

### 1. Framework & SDK Modernization
*   **Flutter SDK Upgrade:** Upgraded from Flutter 3.41.6 to Flutter 3.44.8 (Dart 3.12.2).
*   **SDK Constraint:** Updated `pubspec.yaml` environment constraint to `>=3.12.0 <4.0.0`.
*   **Deep Link Navigation:** Upgraded `app_links` to `7.2.1` for enhanced deep-linking handling across mobile platforms.
*   **Markdown Support:** Replaced discontinued `flutter_markdown` with `flutter_markdown_plus` (`1.0.7`).

### 2. Native Android Toolchain Upgrade
*   **Gradle Wrapper:** Upgraded to Gradle `8.14`.
*   **Android Gradle Plugin:** Upgraded AGP to `8.11.1`.
*   **Kotlin Plugin:** Upgraded Kotlin to `2.2.20`.
*   **Compatibility Safeguards:** Maintained backwards-compatibility build flags in `gradle.properties` to ensure third-party plugin stability.

### 3. Modernized Dart Syntaxes & UI Assertions
*   **Initializing Formals:** Refactored constructor parameter initializers across core services and presentation providers to use concise Dart 3.12 `this._fieldName` formals.
*   **Null-Aware Spread Operators:** Refactored map projections to use null-aware collection spreads (`...?`).
*   **Material Ink Splash Compliance:** Wrapped `ListTile` items in a `Material(color: Colors.transparent)` widget inside `SettingsPage` to satisfy Flutter 3.44's background ink splash assertions.

---

## 🧪 Verification & Build Integrity

*   **Static Analysis:** `flutter analyze` passes cleanly with 0 issues.
*   **Test Suite:** 100% pass rate across all 234 unit and widget tests.
*   **Build Verification:** Successfully produced debug APK (`app-debug.apk`) with Gradle 8.14 and AGP 8.11.1.

---

# Previous Release Notes

<details>
<summary><b>Version 1.1.5+11 (June 14, 2026)</b></summary>

### Key Enhancements:
*   **Screen-Reader Accessibility for Blind Users:** Custom calendar grid semantics, semantic BBT/mood chart statistical summaries, and accessible symptom input sheets.
*   **Adaptive Multi-Cycle Prediction Engine:** Scalable cycle forecasting engine projecting up to 4 future cycles based on recorded history depth.
*   **Secret Sanitization & Security:** Google OAuth Client ID externalization via `String.fromEnvironment('GOOGLE_CLIENT_ID')` and gitignored `dart-defines.json`.
*   **Development Workflows:** Debug launcher icon badge overlay and shared debug keystore.

</details>
