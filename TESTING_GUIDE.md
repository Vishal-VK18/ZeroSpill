# Testing Guide - Expiry Detection System

## 🧪 Quick Test Commands

### 1. Check Model File Exists
```bash
# Windows
dir d:\ZeroSpill\assets\ml\

# Should show:
# expiry_detector.tflite
# labels.txt
```

### 2. Verify Dependencies
```bash
cd d:\ZeroSpill
flutter pub get
flutter doctor -v
```

### 3. Run on Device
```bash
flutter run --release
```

---

## ✅ Test Scenarios

### Test 1: App Startup
**Expected:**
1. Splash screen appears with "Loading ML model..."
2. Progress indicator shows
3. ~2-3 seconds loading time
4. Main screen appears

**Pass criteria:**
- No crash during model loading
- App becomes responsive
- No infinite loading

---

### Test 2: Barcode → Expiry Flow
**Steps:**
1. Open app
2. Tap "+ Add Item" or scan action
3. Scan a product barcode
4. **PackageScanScreen** should auto-open
5. Point camera at expiry label
6. Wait 1-3 seconds

**Expected:**
- Green bounding boxes appear when label detected
- Auto-capture triggers
- Processing overlay shows "Reading expiry date..."
- Dialog shows detected expiry

**Pass criteria:**
- Camera doesn't close immediately
- Detection runs periodically
- Bounding boxes visible
- OCR extracts date correctly

---

### Test 3: Manual Capture
**Steps:**
1. Open PackageScanScreen
2. Point at expiry label
3. Tap "Capture Now" button

**Expected:**
- Single capture triggered
- Processing starts
- Result or error shown

**Pass criteria:**
- Button works
- No frozen UI
- Clear feedback

---

### Test 4: Vegetable Auto-Expiry
**Steps:**
1. Scan barcode for tomato (or manually enter "Tomato")
2. Open expiry scanner
3. Wait for detection timeout or skip

**Expected:**
- If no expiry detected
- System calculates: Today + 5 days
- Auto-filled in form

**Pass criteria:**
- Fallback works
- Correct calculation
- "Auto-calculated" badge shown

---

### Test 5: Manual Entry Fallback
**Steps:**
1. Open PackageScanScreen
2. Tap "Enter Manually"

**Expected:**
- Returns to form
- Expiry field shows date picker
- User can input manually

**Pass criteria:**
- Navigation works
- Date picker functional
- Data persists

---

## 🐛 Common Issues & Solutions

### Issue: Model Not Loading
**Error**: "Loading ML model..." never completes

**Debug:**
```bash
flutter run --verbose
```

Look for:
```
❌ Failed to load model: <error>
```

**Solutions:**
1. Check `assets/ml/expiry_detector.tflite` exists
2. Run `flutter clean && flutter pub get`
3. Rebuild: `flutter run --release`

---

### Issue: No Camera Permission
**Error**: "Camera error: Permission denied"

**Solution:**
```bash
# Check AndroidManifest.xml has:
<uses-permission android:name="android.permission.CAMERA" />

# On device:
# Settings → Apps → ZeroSpill → Permissions → Camera → Allow
```

---

### Issue: Detection Not Working
**Symptoms**: No bounding boxes appear

**Debug steps:**
1. Check console for detection logs:
   ```
   🔍 Detected N expiry regions
   ```

2. If N = 0:
   - Ensure good lighting
   - Get closer to package
   - Try different angle
   - Check confidence threshold in code

3. Lower threshold temporarily:
   ```dart
   // lib/ml/expiry_detector_service.dart line 60
   static const double confidenceThreshold = 0.30; // Lower for testing
   ```

---

### Issue: OCR Fails
**Symptoms**: Detection works but no date extracted

**Debug:**
1. Check `ExpiryTextParser` logs
2. Capture test image manually
3. Verify cropped region is readable

**Solutions:**
- Increase crop padding
- Better lighting
- Hold camera steady (reduce blur)

---

## 🔍 Debug Mode

### Enable Verbose Logging

**File**: `lib/ml/expiry_detector_service.dart`

Uncomment debug prints:
```dart
// After line 245 in _postProcess
for (final det in filteredDetections) {
  print('  Detection: ${det.className}');
  print('    Confidence: ${det.confidence}');
  print('    BBox: ${det.boundingBox}');
  print('    Raw coords: (${det.boundingBox.x}, ${det.boundingBox.y})');
}
```

**File**: `lib/ml/expiry_text_parser.dart`

Add logging:
```dart
// After line 20
print('📝 OCR Result: $rawText');
print('🔍 Extracted dates: $dates');
```

---

## 📊 Performance Testing

### Measure Inference Time

Add timer in `expiry_detector_service.dart`:

```dart
Future<List<Detection>> detect(Uint8List imageBytes) async {
  final stopwatch = Stopwatch()..start();
  
  // ... existing code ...
  
  stopwatch.stop();
  print('⏱️  Inference took: ${stopwatch.elapsedMilliseconds}ms');
  
  return detections;
}
```

**Target:**
- < 150ms on mid-range device
- < 100ms on high-end device

---

## 🎯 Test Checklist

Before declaring "production-ready":

- [ ] App starts without crash
- [ ] ML model loads successfully
- [ ] Camera permission works
- [ ] Barcode scanner works
- [ ] Expiry scanner opens after barcode
- [ ] Camera doesn't close immediately  
- [ ] Detection runs periodically (every 1.5s)
- [ ] Bounding boxes appear on labels
- [ ] Auto-capture triggers on confident detection
- [ ] OCR extracts dates correctly
- [ ] Vegetable auto-expiry works
- [ ] Manual capture button works
- [ ] Skip to manual entry works
- [ ] Expiry data returns to caller
- [ ] Form auto-fills with detected date
- [ ] No navigation stack issues
- [ ] No black screens
- [ ] No memory leaks (test 10+ scans)
- [ ] Works in low light (with flash)
- [ ] Works on various packages
- [ ] Handles errors gracefully

---

## 🚨 Critical Tests

### Test on Multiple Devices

Test on at least:
1. **Low-end** (2GB RAM, old CPU)
2. **Mid-range** (4GB RAM, modern CPU)
3. **High-end** (8GB+ RAM, flagship CPU)

Check:
- Inference speed
- App responsiveness
- Battery usage
- Heat generation

---

### Real-World Package Testing

Test with:
1. ✅ Milk carton
2. ✅ Bread bag
3. ✅ Canned food
4. ✅ Fresh vegetables
5. ✅ Packaged snacks
6. ✅ Medicine box
7. ✅ Frozen food

Document:
- Detection success rate
- OCR accuracy
- Manual intervention needed

---

## 📈 Success Metrics

**Target Benchmarks:**
- **Model load time**: < 5 seconds
- **Detection rate**: > 75%
- **OCR accuracy**: > 70%
- **Overall automation**: > 60%
- **Inference time**: < 200ms

**Real-world expected:**
- 65-75% fully automated
- 20-25% manual capture needed
- 5-10% manual entry fallback
- 0-2% vegetable auto-calc

---

## 🎉 When All Tests Pass

You're ready to:
1. Build release APK
2. Deploy to test users
3. Collect real-world feedback
4. Iterate on accuracy

**Remember**: 100% accuracy is NOT the goal. The goal is to **reduce manual effort by 60-70%**.

---

## 💡 Pro Tips

1. **Always test with real devices** - Emulators don't have proper camera
2. **Test in various lighting** - Bright, dim, natural, artificial
3. **Test with worn packages** - Faded text, wrinkled labels
4. **Collect failure cases** - Use them to improve model
5. **Monitor battery usage** - Detection should not drain battery fast

---

Good luck! 🚀
