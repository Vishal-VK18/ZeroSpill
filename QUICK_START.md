# Quick Reference: Offline Expiry Detection System

## 📁 File Locations

### ML Training (Python)
```
d:/ZeroSpill/ml_training/
├── synthetic_dataset_generator.py    # Generate 500 training images
├── train_expiry_model.py            # Train YOLOv8 model
├── export_to_tflite.py              # Convert to TFLite
├── requirements.txt                 # Python dependencies
└── README.md                        # Full training guide
```

### Flutter Code (Dart)
```
d:/ZeroSpill/lib/
├── ml/
│   ├── expiry_detector_service.dart # TFLite inference
│   ├── expiry_region_cropper.dart   # Image processing
│   └── expiry_text_parser.dart      # Date extraction
└── features/scanner/
    └── expiry_scanner_screen.dart   # Camera UI
```

### Assets
```
d:/ZeroSpill/assets/ml/
├── expiry_detector.tflite          # Model (train first!)
└── labels.txt                      # Class names ✓
```

### Documentation
```
d:/ZeroSpill/
├── EXPIRY_DETECTION_README.md      # Project overview
├── FLUTTER_INTEGRATION.md          # Integration guide
└── ml_training/README.md           # Training guide
```

---

## ⚡ Quick Start Commands

### 1. Train Model (Python)
```bash
cd d:/ZeroSpill/ml_training
pip install -r requirements.txt
python synthetic_dataset_generator.py  # ~10 min
python train_expiry_model.py          # 2-4 hrs GPU
python export_to_tflite.py            # ~5 min
```

### 2. Run Flutter App
```bash
cd d:/ZeroSpill
flutter pub get  # ✓ Already done
flutter run      # On Android device
```

---

## 🔌 Integration Example

Add to your barcode scanner result handler:

```dart
import 'package:zerospill/features/scanner/expiry_scanner_screen.dart';
import 'package:zerospill/ml/expiry_text_parser.dart';

// After barcode scan succeeds
final expiryResult = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ExpiryScannerScreen(
      productName: productName,
      barcode: barcode,
    ),
  ),
);

if (expiryResult != null && expiryResult.hasValidExpiry) {
  // Use detected expiry date
  setState(() {
    expiryDate = expiryResult.expiryDate;
  });
}
```

---

## 📊 What Was Built

| Component | Status | File(s) |
|-----------|--------|---------|
| Dataset Generator | ✅ | synthetic_dataset_generator.py |
| Training Script | ✅ | train_expiry_model.py |
| TFLite Export | ✅ | export_to_tflite.py |
| TFLite Service | ✅ | expiry_detector_service.dart |
| Region Cropper | ✅ | expiry_region_cropper.dart |
| Text Parser | ✅ | expiry_text_parser.dart |
| Scanner UI | ✅ | expiry_scanner_screen.dart |
| Dependencies | ✅ | pubspec.yaml updated |
| Documentation | ✅ | 3 comprehensive guides |

---

## 🎯 Classes Detected

The model detects 6 types of expiry-related text:

1. **use_by** - "USE BY", "USE BEFORE"
2. **best_before** - "BEST BEFORE", "BB"
3. **exp** - "EXP", "EXPIRY", "EXPIRY DATE"
4. **mfg** - "MFG", "MANUFACTURED"
5. **pkd** - "PKD", "PACKED DATE"
6. **date_value** - Date numbers near labels

---

## ⚙️ Configuration

### Adjust Detection Sensitivity
`lib/ml/expiry_detector_service.dart` line 38:
```dart
static const double confidenceThreshold = 0.5; // Lower = more detections
```

### Change Detection Frequency
`lib/features/scanner/expiry_scanner_screen.dart` line 80:
```dart
_detectionTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
```

### Add Date Formats
`lib/ml/expiry_text_parser.dart` line 90 - add regex patterns

---

## 🚨 Important Notes

> **Model NOT included**: You must train the model yourself using the provided scripts.

> **GPU recommended**: Training on CPU takes 20+ hours. Use Google Colab for free GPU.

> **Real device required**: Emulator may not support camera properly.

> **Android minSdk**: Must be 21+ for TFLite support.

---

## 📚 Where to Get Help

1. **Training issues?** → `ml_training/README.md`
2. **Flutter errors?** → `FLUTTER_INTEGRATION.md`
3. **Project overview?** → `EXPIRY_DETECTION_README.md`
4. **What was built?** → `brain/.../walkthrough.md`

---

## ✅ Next Steps

1. ⚠️ **Train model** (required)
2. 📱 Test on real device
3. 🔧 Integrate into scanner flow
4. 🎯 Test with real products
5. 🚀 Deploy

---

## 🏆 Result

**Complete offline expiry detection** - No Roboflow, No APIs, 100% custom!
