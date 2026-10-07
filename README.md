# Calculator App (CSC 4360, Assignment 01)

A two-operand Flutter calculator with these undergraduate pathway features:

1. **Theme toggle**: switch between light and dark themes in the app bar, with an animated 400 ms transition.
2. **Clear / all clear**: `AC` resets all state, and `C` clears only the current entry.
3. **Error handling**: division by zero and overflow show a recoverable error; an incomplete operation (`8 × =`) shows a hint and keeps the current state.

## Structure
- `lib/calculator_engine.dart`: pure Dart logic (state and arithmetic)
- `lib/main.dart`: UI (theme, display, keypad)
- `test/widget_test.dart`: unit and widget tests

## Run
```bash
flutter pub get
flutter test
flutter run
```

## Build APK
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
