# Installing TensorFlow Lite Native Libraries

The error "Failed to load dynamic library 'libtensorflowlite_c.so'" means the TensorFlow Lite native library is missing.

## Solution: Install TFLite Libraries Manually

### Option 1: Use install_tflite.sh Script (Recommended)

1. **Download the installation script:**
   ```bash
   cd d:\ZeroSpill
   curl -o install_tflite.sh https://raw.githubusercontent.com/am15h/tflite_flutter_plugin/master/install.sh
   ```

2. **Run the script:**
   ```bash
   bash install_tflite.sh
   ```

This will download the TensorFlow Lite C libraries and place them in the correct Android directories.

---

### Option 2: Manual Download (If script doesn't work)

1. **Download TensorFlow Lite Android AAR:**
   - Go to: https://www.tensorflow.org/lite/android/lite_build
   - Or download directly from Maven: https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/2.13.0/

2. **Add to gradle.properties:**
   Add this line to `android/gradle.properties`:
   ```properties
   android.useAndroidX=true
   ```

3. **Add to app/build.gradle.kts:**
   Add to dependencies section:
   ```kotlin
   dependencies {
       // ... existing dependencies
       implementation("org.tensorflow:tensorflow-lite:2.13.0")
       implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
   }
   ```

---

### Option 3: Use Pre-built AAR

1. **Create `android/app/libs/` directory:**
   ```bash
   mkdir -p android/app/libs
   ```

2. **Download libtensorflowlite_c.so:**
   ```bash
   # For ARM64 (most modern phones)
   curl -L https://storage.googleapis.com/tensorflow-nightly/github/tensorflow/tensorflow/lite/tools/make/gen/android_arm64-v8a/lib/libtensorflowlite_c.so -o android/app/src/main/jniLibs/arm64-v8a/libtensorflowlite_c.so
   
   # For ARMv7 (older phones)
   curl -L https://storage.googleapis.com/tensorflow-nightly/github/tensorflow/tensorflow/lite/tools/make/gen/android_armeabi-v7a/lib/libtensorflowlite_c.so -o android/app/src/main/jniLibs/armeabi-v7a/libtensorflowlite_c.so
   ```

---

## Quick Fix (Easiest)

Add TensorFlow Lite dependency to your `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.13.0")
}
```

Then rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

---

## Verification

After applying the fix, check if the library is included:
```bash
# Extract APK and check for .so files
cd d:\ZeroSpill\build\app\outputs\flutter-apk
unzip -l app-debug.apk | grep libtensorflow
```

You should see entries like:
- `lib/arm64-v8a/libtensorflowlite_c.so`
- `lib/armeabi-v7a/libtensorflowlite_c.so`
