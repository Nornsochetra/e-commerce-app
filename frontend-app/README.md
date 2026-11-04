# APM app (Flutter)

The APM mobile app. How to run it with the backend is in the [project README](../README.md);
the folder structure and conventions are in [`docs/flutter.md`](../docs/flutter.md).

```bash
flutter pub get
flutter run -d "iPhone 16"
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api/v1   # Android emulator
flutter analyze && flutter test
```
