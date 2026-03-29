# Privacy-First Women's Health Tracker

A high-fidelity, native Flutter application designed with a security-first mindset. No data ever leaves your device; everything is stored locally using Hive with AES-256 encryption.

## Key Features
- **Privacy-First**: Zero-tracking, zero-telemetry. All data is encrypted and stored locally.
- **Premium Aesthetics**: High-end glassmorphic UI with vibrant colors and smooth animations.
- **Cycle & Period Tracking**: Intuitive calendar interface for logging cycles and predicting future periods.
- **Symptom & Mood Logging**: Detailed daily logging for symptoms (cramps, bloating, etc.) and mood.
- **Summary & Trends**: Advanced data aggregation to visualize your patterns and health trends over time.

## Architecture
- **Clean Architecture**: Clear separation of concern between Domain (models/logic), Data (storage/encryption), and Presentation (UI).
- **Security**: Uses `flutter_secure_storage` for key management and `Hive` for encrypted persisted storage.

## Testing
The project maintains a high-quality codebase with mandatory testing.

### Run All Tests
```bash
flutter test
```

### Specific Test Areas
- **Unit Tests**: `test/domain/` for logic and calculators.
- **Widget Tests**: `test/presentation/` for UI rendering and sheet behavior.
- **Integration/Storage**: `test/data/` for encryption and Hive service verification.

## Development Setup

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run Dev Server** (for web development):
   ```bash
   flutter run -d chrome
   ```

3. **Format Code**:
   ```bash
   flutter format .
   ```
