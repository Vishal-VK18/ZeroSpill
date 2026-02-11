#!/bin/bash

# TensorFlow Lite Native Library Installer for Android
# This script downloads the libtensorflowlite_c.so files for Android

set -e

echo "Installing TensorFlow Lite native libraries..."

# Create directories
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
mkdir -p android/app/src/main/jniLibs/x86
mkdir -p android/app/src/main/jniLibs/x86_64

# TensorFlow Lite version
TFLITE_VERSION="2.13.0"

# Download URLs
BASE_URL="https://storage.googleapis.com/tensorflow/libtensorflow"

echo "Downloading for arm64-v8a..."
curl -L "$BASE_URL/libtensorflowlite_jni-${TFLITE_VERSION}.aar" -o tflite.aar

# Extract .so files from AAR
unzip -j tflite.aar "jni/arm64-v8a/*" -d android/app/src/main/jniLibs/arm64-v8a/
unzip -j tflite.aar "jni/armeabi-v7a/*" -d android/app/src/main/jniLibs/armeabi-v7a/
unzip -j tflite.aar "jni/x86/*" -d android/app/src/main/jniLibs/x86/
unzip -j tflite.aar "jni/x86_64/*" -d android/app/src/main/jniLibs/x86_64/

# Cleanup
rm tflite.aar

echo "✅ TensorFlow Lite native libraries installed successfully!"
echo "Libraries installed in:"
echo "  - android/app/src/main/jniLibs/arm64-v8a/"
echo "  - android/app/src/main/jniLibs/armeabi-v7a/"
echo "  - android/app/src/main/jniLibs/x86/"
echo "  - android/app/src/main/jniLibs/x86_64/"
echo ""
echo "Now run: flutter clean && flutter pub get && flutter run"
