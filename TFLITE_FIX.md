# TFLite Namespace Error - Quick Fix

## Problem
You're getting this error:
```
Namespace not specified for tflite_flutter plugin
```

This is a known issue with `tflite_flutter` versions 0.9.x and 0.10.x when using newer Android Gradle Plugin (AGP).

## Solution 1: Add Namespace to Plugin (RECOMMENDED)

Navigate to the plugin's build.gradle and add namespace:

**File to edit:**
```
C:\Users\durai\AppData\Local\Pub\Cache\hosted\pub.dev\tflite_flutter-0.9.5\android\build.gradle
```

**Add this line** (around line 25, inside the `android {` block):
```gradle
android {
    namespace 'sq.flutter.tflite_flutter'  // ADD THIS LINE
    compileSdkVersion 31
    // ... rest of config
}
```

### Steps:
1. Open File Explorer
2. Navigate to: `C:\Users\durai\AppData\Local\Pub\Cache\hosted\pub.dev\tflite_flutter-0.9.5\android\`
3. Edit `build.gradle`
4. Add the `namespace` line as shown above
5. Save the file
6. Run: `flutter clean && flutter pub get && flutter run --release`

---

## Solution 2: Use Alternative TFLite Package

If Solution 1 doesn't work, use `tflite_flutter_plus` instead:

**Update pubspec.yaml:**
```yaml
dependencies:
  tflite_flutter_plus: ^0.1.0  # Instead of tflite_flutter
```

Then update imports in code files:
- `lib/ml/expiry_detector_service.dart`
- Change: `import 'package:tflite_flutter/tflite_flutter.dart';`
- To: `import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';`

---

## Solution 3: Run Without Model (For Now)

If you just want to test the app UI without ML functionality:

1. Comment out model loading in `lib/core/services/model_initializer.dart`:
   ```dart
   Future<void> initialize({Function(String)? onStatus}) async {
     // Temporarily skip model loading
     _initialized = true;
     onStatus?.call('Model ready (skipped)');
     return;
     
     // ... rest of code
   }
   ```

2. Run the app - everything will work except expiry detection

---

## Why This Happens

Android Gradle Plugin 7.0+ requires all modules to specify a namespace. Older Flutter plugins don't have this, causing build failures.

---

## Recommended Action

**Try Solution 1 first** - it's the simplest and preserves all functionality.

After fixing, run:
```bash
flutter clean
flutter pub get
flutter run --release
```

---

## Alternative: Wait for Model File

If you haven't trained the model yet, you can:
1. Train the model first: `cd ml_training  && python train_expiry_model.py && python export_to_tflite.py`
2. Then deal with the TFLite dependency issue

The model file must exist at: `assets/ml/expiry_detector.tflite`
