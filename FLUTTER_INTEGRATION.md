# Flutter Expiry Detection Integration Guide

Complete guide for integrating the trained TFLite model into the ZeroSpill Flutter app.

## Prerequisites

Before starting, ensure you have:
1. ✓ Trained YOLOv8 model exported to TFLite
2. ✓ `expiry_detector.tflite` file
3. ✓ `labels.txt` file
4. ✓ Flutter development environment set up

---

## Quick Start

### Step 1: Install Dependencies

```bash
cd d:/ZeroSpill
flutter pub get
```

This will install:
- `tflite_flutter` - TensorFlow Lite runtime
- `tflite_flutter_helper` - Helper utilities
- `image` - Image processing
- Existing dependencies (camera, OCR, etc.)

### Step 2: Place Model Files

**IMPORTANT**: The model files must be placed in the correct location:

```
d:/ZeroSpill/assets/ml/
├── expiry_detector.tflite  (Your trained model, ~1.5-2 MB)
└── labels.txt              (Class names, one per line)
```

**If you haven't trained the model yet:**
1. Follow `ml_training/README.md` to generate dataset and train
2. Run `python export_to_tflite.py` to export model
3. The script will automatically copy files to `assets/ml/`

**Manual Copy (if needed):**
```bash
# From ml_training directory
cp best_saved_model/best_int8.tflite d:/ZeroSpill/assets/ml/expiry_detector.tflite
cp expiry_dataset/labels.txt d:/ZeroSpill/assets/ml/labels.txt
```

**Verify labels.txt format:**
```
use_by
best_before
exp
mfg
pkd
date_value
```

### Step 3: Android Configuration

For TFLite to work on Android, add to `android/app/build.gradle`:

```gradle
android {
    // ... existing config ...
    
    aaptOptions {
        noCompress 'tflite'
        noCompress 'lite'
    }
}
```

**Update minSdkVersion if needed:**
```gradle
defaultConfig {
    minSdkVersion 21  // Minimum for TFLite
    // ... rest of config ...
}
```

---

## Integration into Existing Scanner Flow

### Current Flow
1. User scans barcode
2. Product identified
3. Manual expiry entry

### New Flow (After Integration)
1. User scans barcode
2. Product identified
3. **Auto-open ExpiryScannerScreen**
4. **ML model detects expiry labels**
5. **OCR extracts dates**
6. **Auto-fill expiry field**
7. User confirms or edits

---

## Code Integration

### Option A: Navigate from Barcode Scanner

Find where barcode scanning completes (likely in your existing scanner screen) and add:

```dart
import 'package:zerospill/features/scanner/expiry_scanner_screen.dart';
import 'package:zerospill/ml/expiry_text_parser.dart';

// After successful barcode scan:
void _onBarcodeDetected(String barcode) async {
  // Existing logic to identify product
  final productName = await identifyProduct(barcode);
  
  // Navigate to expiry scanner
  final ExpiryData? expiryResult = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ExpiryScannerScreen(
        productName: productName,
        barcode: barcode,
      ),
    ),
  );
  
  // Use the detected expiry date
  if (expiryResult != null && expiryResult.hasValidExpiry) {
    _setExpiryDate(expiryResult.expiryDate!);
  }
}
```

### Option B: Add Button to Scanner Preview

In your `scan_result_preview_screen.dart`:

```dart
ElevatedButton.icon(
  onPressed: () async {
    final expiryResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpiryScannerScreen(
          productName: productName,
          barcode: scannedBarcode,
        ),
      ),
    );
    
    if (expiryResult != null) {
      setState(() {
        expiryDate = expiryResult.expiryDate;
      });
    }
  },
  icon: Icon(Icons.camera_alt),
  label: Text('Scan Expiry Date'),
)
```

### Option C: Initialize Model on App Start

For better performance, initialize the ML model when app starts:

**In your main.dart or app initialization:**

```dart
import 'package:zerospill/ml/expiry_detector_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ML model (warm-up)
  await ExpiryDetectorService().initialize();
  
  runApp(MyApp());
}
```

---

## Testing

### Test without Real Model (Development)

If you haven't trained the model yet, you can test the UI:

1. Create dummy model files:
```bash
mkdir -p d:/ZeroSpill/assets/ml
echo "use_by\nbest_before\nexp\nmfg\npkd\ndate_value" > d:/ZeroSpill/assets/ml/labels.txt
# For .tflite, you'll need to complete training or use a placeholder
```

2. The scanner will show camera and UI, but detection won't work until you have a real model.

### Test with Real Model

1. Train the model using `ml_training/` scripts
2. Export to TFLite
3. Run app on real Android device (emulator may not have camera)
4. Test with various grocery products:
   - Boxes (cereal, crackers)
   - Bottles (milk, juice)
   - Cans (soup, beans)
   - Plastic wrappers (bread, snacks)

### Troubleshooting

**Model not loading:**
```
Error: Unable to load asset: assets/ml/expiry_detector.tflite
```
- Run `flutter clean && flutter pub get`
- Verify file exists at `d:/ZeroSpill/assets/ml/expiry_detector.tflite`
- Check `pubspec.yaml` has correct asset path

**Camera not working:**
```
CameraException: Camera permission denied
```
- Ensure `AndroidManifest.xml` has camera permissions (already configured)
- On device, grant camera permission when prompted

**Detection not working:**
- Model might need more training
- Try different lighting conditions
- Ensure expiry label is clearly visible and in focus
- Check model validation metrics (mAP should be > 0.85)

**OCR not extracting text:**
- Region might be too small or blurry
- Try manual capture button instead of auto-capture
- Increase cropping padding in `expiry_region_cropper.dart`

**False positives:**
- Increase `confidenceThreshold` in `expiry_detector_service.dart`
- Train model with more diverse negative examples

---

## Performance Optimization

### Reduce Detection Frequency

In `expiry_scanner_screen.dart`, change timer interval:

```dart
// From 1 second to 2 seconds (less CPU usage)
_detectionTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
  ...
});
```

### Use Lower Camera Resolution

```dart
_cameraController = CameraController(
  camera,
  ResolutionPreset.medium, // Change from 'high' to 'medium'
  enableAudio: false,
);
```

### Reduce Model Size

If app size is a concern:
1. Use YOLOv8n (nano) instead of larger models
2. Apply INT8 quantization (already done in export script)
3. Expected model size: 1.5-2 MB

---

## Advanced Customization

### Adjust Detection Confidence

In `lib/ml/expiry_detector_service.dart`:

```dart
static const double confidenceThreshold = 0.5; // Lower = more detections
static const double iouThreshold = 0.4;        // NMS threshold
```

### Add More Date Formats

In `lib/ml/expiry_text_parser.dart`, add to `patterns`:

```dart
// Example: Add DDMMMYY format (e.g., 15JAN25)
RegExp(r'(\d{2})(JAN|FEB|MAR|...)(\\d{2})'),
```

### Custom UI Colors/Styles

In `lib/features/scanner/expiry_scanner_screen.dart`:

```dart
// Change bounding box colors
Color _getColorForClass(String className) {
  switch (className) {
    case 'exp':
      return Colors.deepOrange; // Your custom color
    // ... etc
  }
}
```

---

## API Reference

### ExpiryDetectorService

```dart
final detector = ExpiryDetectorService();
await detector.initialize();
final detections = await detector.detect(imageBytes);
```

### ExpiryRegionCropper

```dart
final croppedImage = ExpiryRegionCropper.cropRegion(
  imageBytes,
  boundingBox,
  padding: 10,
);

final annotated = ExpiryRegionCropper.createAnnotatedImage(
  imageBytes,
  detections,
);
```

### ExpiryTextParser

```dart
final expiryData = await ExpiryTextParser.parseExpiryText(
  croppedImageBytes,
  'exp', // detected class
);

if (expiryData.hasValidExpiry) {
  print('Expiry: ${expiryData.expiryDate}');
}
```

---

## Next Steps

1. ✓ Dependencies installed (`flutter pub get`)
2. ✓ Model files in place
3. ✓ Integration code added
4. → **Train your model** (see `ml_training/README.md`)
5. → Test with real devices
6. → Iterate based on real-world performance

---

## Support

**Common Issues:**

| Issue | Solution |
|-------|----------|
| Model too large | Use YOLOv8n, apply quantization |
| Low detection accuracy | Train longer, add more data |
| Slow inference | Reduce image size, use lower resolution |
| OCR fails | Increase cropping padding, better lighting |

**Model Performance Targets:**
- **Inference time**: < 200ms per frame on mid-range Android
- **Memory usage**: < 100MB total for model
- **Detection accuracy**: mAP50 > 0.85

---

## File Structure

```
d:/ZeroSpill/
├── lib/
│   ├── ml/
│   │   ├── expiry_detector_service.dart    ← TFLite inference
│   │   ├── expiry_region_cropper.dart      ← Image cropping
│   │   └── expiry_text_parser.dart         ← OCR + date parsing
│   └── features/
│       └── scanner/
│           └── expiry_scanner_screen.dart  ← Camera UI
├── assets/
│   └── ml/
│       ├── expiry_detector.tflite          ← YOUR TRAINED MODEL
│       └── labels.txt                      ← Class names
└── ml_training/
    ├── synthetic_dataset_generator.py
    ├── train_expiry_model.py
    └── export_to_tflite.py
```

---

**Ready to integrate?** Follow the Quick Start steps above!
