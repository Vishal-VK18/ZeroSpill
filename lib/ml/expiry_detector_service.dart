import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

/// Detection result from YOLO model
class Detection {
  final BoundingBox boundingBox;
  final int classId;
  final String className;
  final double confidence;

  Detection({
    required this.boundingBox,
    required this.classId,
    required this.className,
    required this.confidence,
  });

  @override
  String toString() =>
      'Detection(class: $className, conf: ${confidence.toStringAsFixed(2)}, box: $boundingBox)';
}

/// Bounding box coordinates
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox(this.x, this.y, this.width, this.height);

  double get left => x;
  double get top => y;
  double get right => x + width;
  double get bottom => y + height;

  double get centerX => x + width / 2;
  double get centerY => y + height / 2;

  @override
  String toString() => 'BoundingBox($x, $y, $width, $height)';
}

/// TFLite-based expiry detection service (Singleton)
class ExpiryDetectorService {
  static final ExpiryDetectorService _instance = ExpiryDetectorService._internal();
  factory ExpiryDetectorService() => _instance;
  ExpiryDetectorService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Model configuration
  static const int inputSize = 416;
  static const int numClasses = 6;
  static const double confidenceThreshold = 0.45;
  static const double iouThreshold = 0.45;
  static const int numThreads = 4;

  /// Initialize TFLite model (singleton - only loads once)
  Future<void> initialize() async {
    if (_isInitialized) {
      print('✓ Model already initialized');
      return;
    }

    if (_isInitializing) {
      print('Model initialization in progress, waiting...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;

    try {
      print('🔄 Loading expiry detection model...');
      
      // Load model
      final interpreterOptions = InterpreterOptions()..threads = numThreads;
      _interpreter = await Interpreter.fromAsset(
        'assets/ml/expiry_detector.tflite',
        options: interpreterOptions,
      );
      
      // Load labels
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();
      
      print('✅ Model loaded successfully');
      print('  Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('  Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('  Classes: ${_labels.join(", ")}');
      print('  Threads: $numThreads');
      
      _isInitialized = true;
    } catch (e) {
      print('❌ Failed to load model: $e');
      _isInitialized = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Check if model is initialized
  bool get isInitialized => _isInitialized;

  /// Detect expiry regions from camera frame
  Future<List<Detection>> detectFromCameraImage(CameraImage cameraImage) async {
    if (!_isInitialized) {
      print('⚠️  Model not initialized');
      return [];
    }

    try {
      // Convert CameraImage to Uint8List
      final imageBytes = await _convertCameraImage(cameraImage);
      if (imageBytes == null) {
        return [];
      }

      return await detect(imageBytes);
    } catch (e) {
      print('❌ Error detecting from camera: $e');
      return [];
    }
  }

  /// Run detection on image bytes
  Future<List<Detection>> detect(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw StateError('Model not initialized. Call initialize() first.');
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Run inference
      final detections = await _runInferenceIsolate(imageBytes);
      
      return detections;
    } catch (e) {
      print('❌ Error during detection: $e');
      return [];
    }
  }

  /// Convert CameraImage to Uint8List
  Future<Uint8List?> _convertCameraImage(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;

      // Convert YUV to RGB
      final img.Image imgImage = img.Image(width: width, height: height);
      
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

          imgImage.setPixelRgb(x, y, r, g, b);
        }
      }

      return Uint8List.fromList(img.encodeJpg(imgImage));
    } catch (e) {
      print('❌ Error converting camera image: $e');
      return null;
    }
  }

  /// Run inference in isolate to avoid blocking UI
  Future<List<Detection>> _runInferenceIsolate(Uint8List imageBytes) async {
    try {
      // For now, run on main thread - isolate requires more complex setup
      final image = img.decodeImage(imageBytes)!;
      final preprocessed = _preprocessImage(image);
      final output = _runInference(preprocessed);
      final detections = _postProcess(output, image.width, image.height);
      return detections;
    } catch (e) {
      print('❌ Inference error: $e');
      return [];
    }
  }

  /// Preprocess image for model input
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Apply orientation correction if needed (handle EXIF rotation)
    img.Image orientedImage = image;
    
    // Resize image to model input size maintaining aspect ratio
    final resized = img.copyResize(
      orientedImage,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to normalized float array [1, 416, 416, 3]
    // YOLOv8 expects RGB format normalized to [0, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            // Normalize to [0, 1] range as expected by model
            return [
              pixel.r.toDouble() / 255.0,
              pixel.g.toDouble() / 255.0,
              pixel.b.toDouble() / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Run model inference
  List<dynamic> _runInference(List<List<List<List<double>>>> input) {
    // Get output tensor shape dynamically - CRITICAL FIX
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    print('📊 Output tensor shape: $outputShape');
    
    // Allocate output buffer based on ACTUAL tensor shape
    // YOLOv8 format: [batch, features, predictions]
    // e.g., [1, 10, 3549] means 1 batch, 10 features (4 bbox + 6 classes), 3549 predictions
    final output = List.generate(
      outputShape[0], // batch size (usually 1)
      (_) => List.generate(
        outputShape[1], // number of features (bbox + classes)
        (_) => List.filled(outputShape[2], 0.0), // number of predictions
      ),
    );

    // Run inference
    _interpreter!.run(input, output);

    return output;
  }

  /// Post-process model output to get detections
  List<Detection> _postProcess(List<dynamic> output, int originalWidth, int originalHeight) {
    final detections = <Detection>[];
    
    // Output format: [batch, features, predictions]
    // YOLOv8 format: First 4 features are bbox (center_x, center_y, width, height)
    // Remaining features are class scores
    final predictions = output[0];
    final numFeatures = predictions.length;
    final numPredictions = predictions[0].length;

    print('📊 Post-processing: $numFeatures features × $numPredictions predictions');
    print('📐 Original image size: ${originalWidth}x$originalHeight');

    // Validate shape
    if (numFeatures < 4 + numClasses) {
      print('⚠️ Unexpected output shape: expected at least ${4 + numClasses} features, got $numFeatures');
      return [];
    }

    for (int i = 0; i < numPredictions; i++) {
      // CRITICAL FIX: YOLOv8 outputs coordinates in NORMALIZED format (0-1 range)
      // These coordinates are relative to the INPUT SIZE (416x416), not pixel coordinates
      final centerX = predictions[0][i] as double;
      final centerY = predictions[1][i] as double;
      final w = predictions[2][i] as double;
      final h = predictions[3][i] as double;

      // Extract class scores
      double maxConf = 0.0;
      int maxClassId = 0;

      for (int c = 0; c < numClasses; c++) {
        final conf = predictions[4 + c][i] as double;
        if (conf > maxConf) {
          maxConf = conf;
          maxClassId = c;
        }
      }

      // Filter by confidence threshold
      if (maxConf < confidenceThreshold) continue;

      // CRITICAL FIX: Convert from model coordinate space to original image space
      // Step 1: Model outputs are in range [0, inputSize] (0-416)
      // Step 2: Scale these to original image dimensions
      // The coordinates are already in pixel space relative to 416x416 input
      final scaleX = originalWidth / inputSize.toDouble();
      final scaleY = originalHeight / inputSize.toDouble();

      // Convert from center format (cx, cy, w, h) to corner format (x, y, w, h)
      // Scale from 416x416 model space to original image space
      final x = (centerX - w / 2) * scaleX;
      final y = (centerY - h / 2) * scaleY;
      final width = w * scaleX;
      final height = h * scaleY;

      // Debug log for first few detections
      if (detections.length < 3) {
        print('🔍 Detection #${detections.length + 1}:');
        print('   Model coords (center): cx=$centerX, cy=$centerY, w=$w, h=$h');
        print('   Scaled to original: x=${x.toStringAsFixed(1)}, y=${y.toStringAsFixed(1)}, w=${width.toStringAsFixed(1)}, h=${height.toStringAsFixed(1)}');
        print('   Confidence: ${(maxConf * 100).toStringAsFixed(1)}%');
      }

      final bbox = BoundingBox(
        x.clamp(0, originalWidth.toDouble()),
        y.clamp(0, originalHeight.toDouble()),
        width.clamp(0, originalWidth - x),
        height.clamp(0, originalHeight - y),
      );

      detections.add(Detection(
        boundingBox: bbox,
        classId: maxClassId,
        className: maxClassId < _labels.length ? _labels[maxClassId] : 'unknown',
        confidence: maxConf,
      ));
    }

    // Apply Non-Maximum Suppression (NMS)
    final filteredDetections = _applyNMS(detections);

    print('🔍 Detected ${filteredDetections.length} expiry regions');
    for (final det in filteredDetections) {
      print('  ${det.className}: ${(det.confidence * 100).toStringAsFixed(1)}%');
    }

    return filteredDetections;
  }

  /// Apply Non-Maximum Suppression to remove overlapping boxes
  List<Detection> _applyNMS(List<Detection> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final result = <Detection>[];
    final suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      result.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        // Calculate IoU (Intersection over Union)
        final iou = _calculateIoU(
          detections[i].boundingBox,
          detections[j].boundingBox,
        );

        // Suppress if IoU is too high
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return result;
  }

  /// Calculate Intersection over Union between two bounding boxes
  double _calculateIoU(BoundingBox box1, BoundingBox box2) {
    final intersectionLeft = box1.left > box2.left ? box1.left : box2.left;
    final intersectionTop = box1.top > box2.top ? box1.top : box2.top;
    final intersectionRight = box1.right < box2.right ? box1.right : box2.right;
    final intersectionBottom = box1.bottom < box2.bottom ? box1.bottom : box2.bottom;

    if (intersectionRight < intersectionLeft || intersectionBottom < intersectionTop) {
      return 0.0; // No intersection
    }

    final intersectionArea = (intersectionRight - intersectionLeft) *
        (intersectionBottom - intersectionTop);

    final box1Area = box1.width * box1.height;
    final box2Area = box2.width * box2.height;
    final unionArea = box1Area + box2Area - intersectionArea;

    return intersectionArea / unionArea;
  }

  /// Get labels list
  List<String> get labels => _labels;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    print('🗑️  Model resources disposed');
  }
}
