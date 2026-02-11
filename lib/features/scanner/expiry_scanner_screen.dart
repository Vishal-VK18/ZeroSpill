import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../ml/expiry_detector_service.dart';
import '../../ml/expiry_region_cropper.dart';
import '../../ml/expiry_text_parser.dart';
import 'expiry_detector.dart'; // HumanLikeExpiryDetector

/// Screen for scanning expiry dates using camera and ML detection
class ExpiryScannerScreen extends StatefulWidget {
  final String? productName; // From barcode scan
  final String? barcode;

  const ExpiryScannerScreen({
    Key? key,
    this.productName,
    this.barcode,
  }) : super(key: key);

  @override
  State<ExpiryScannerScreen> createState() => _ExpiryScannerScreenState();
}

class _ExpiryScannerScreenState extends State<ExpiryScannerScreen> {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // ML Detection
  final _detectorService = ExpiryDetectorService();
  bool _isDetecting = false;
  List<Detection> _currentDetections = [];
  Timer? _detectionTimer;

  // Results
  ExpiryData? _bestExpiryResult;
  Uint8List? _capturedImage;
  bool _isProcessing = false;
  int _retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize ML model
      await _detectorService.initialize();

      // Initialize camera
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _initializeCamera(_cameras!.first);
      }

      // Start periodic detection
      _startPeriodicDetection();
    } catch (e) {
      print('Error initializing services: $e');
      _showError('Failed to initialize camera or model');
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  void _startPeriodicDetection() {
    // Run detection every 1 second (adjust for performance)
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (!_isDetecting && _isCameraInitialized && !_isProcessing) {
        _runDetection();
      }
    });
  }

  Future<void> _runDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _isDetecting = true;

    try {
      // Capture current frame
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      // Run YOLO detection
      final detections = await _detectorService.detect(imageBytes);

      if (mounted) {
        setState(() {
          _currentDetections = detections;
        });
      }

      // Auto-capture if confident detection found
      if (detections.isNotEmpty && _hasConfidentDetection(detections)) {
        await _captureAndProcess(imageBytes);
      }
    } catch (e) {
      print('Error during detection: $e');
    } finally {
      _isDetecting = false;
    }
  }

  bool _hasConfidentDetection(List<Detection> detections) {
    // Check if we have high-confidence expiry-related detections
    return detections.any((d) =>
        d.confidence > 0.7 &&
        (d.className == 'exp' ||
            d.className == 'use_by' ||
            d.className == 'best_before'));
  }

  Future<void> _captureAndProcess(Uint8List imageBytes) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop periodic detection while processing
      _detectionTimer?.cancel();

      // Step 1: Merge nearby regions to combine split labels (e.g., "USE BY" + "12/2026")
      final mergedDetections = ExpiryRegionCropper.mergeNearbyRegions(
        _currentDetections
            .map((d) => DetectionRegion(
                  boundingBox: d.boundingBox,
                  className: d.className,
                  confidence: d.confidence,
                ))
            .toList(),
      );

      print('🔍 Processing: ${_currentDetections.length} detections → ${mergedDetections.length} after merging');

      // Step 2: Crop merged regions and run OCR
      final croppedRegions = ExpiryRegionCropper.cropMultipleRegions(
        imageBytes,
        mergedDetections,
        padding: 15, // Increased padding for better OCR
      );

      // Step 3: Run OCR on each cropped region
      ExpiryData? bestResult;
      double bestConfidence = 0.0;

      for (final region in croppedRegions) {
        final expiryData = await ExpiryTextParser.parseExpiryText(
          region.imageBytes,
          region.className,
        );

        print('   Region ${region.className}: "${expiryData.rawText}" → ${expiryData.expiryDate}');

        // Keep best result (highest confidence with valid expiry)
        if (expiryData.hasValidExpiry && expiryData.confidence > bestConfidence) {
          bestResult = expiryData;
          bestConfidence = expiryData.confidence;
        }
      }

      // Step 4: FALLBACK - If no valid expiry found, run full-image OCR
      if (bestResult == null || !bestResult.hasValidExpiry) {
        print('⚠️ No expiry from regions. Trying full-image OCR fallback...');
        bestResult = await _runFullImageOCR(imageBytes);
      }

      // Step 5: Create annotated image for preview
      final annotatedImage = ExpiryRegionCropper.createAnnotatedImage(
        imageBytes,
        mergedDetections,
      );

      if (mounted) {
        setState(() {
          _bestExpiryResult = bestResult;
          _capturedImage = annotatedImage ?? imageBytes;
        });
      }

      // Step 6: Show results or retry
      if (bestResult != null && bestResult.hasValidExpiry) {
        // Success - show result
        _retryCount = 0;
        _showResultDialog(bestResult);
      } else {
        // Failed - retry or show error
        _retryCount++;
        if (_retryCount < maxRetries) {
          _showRetryMessage('No expiry date found. Attempt $_retryCount/$maxRetries. Move camera closer to the expiry label.');
          _restartDetection();
        } else {
          _showError('Could not detect expiry date after $maxRetries attempts. Please ensure good lighting and clear view of the label.');
          _retryCount = 0;
          _restartDetection();
        }
      }
    } catch (e) {
      print('❌ Error processing capture: $e');
      _showError('Failed to process image: $e');
      _restartDetection();
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Run full-image OCR as fallback when model detection fails
  Future<ExpiryData?> _runFullImageOCR(Uint8List imageBytes) async {
    try {
      // Decode image
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return null;

      // Create InputImage for ML Kit
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: decodedImage.width * 3,
        ),
      );

      // Run OCR on full image
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final fullText = recognizedText.text;
      print('📄 Full-image OCR result: "$fullText"');

      if (fullText.isEmpty) return null;

      // Use HumanLikeExpiryDetector for context-aware parsing
      final detector = HumanLikeExpiryDetector();
      final result = detector.detectExpiry(fullText);

      if (result.date != null) {
        print('✅ Fallback detection found: ${result.date}');
        return ExpiryData(
          expiryDate: result.date,
          rawText: fullText,
          confidence: result.score,
          labelType: ExpiryLabel.exp,
        );
      }

      return null;
    } catch (e) {
      print('❌ Full-image OCR failed: $e');
      return null;
    }
  }

  void _restartDetection() {
    setState(() {
      _currentDetections = [];
      _bestExpiryResult = null;
      _capturedImage = null;
    });
    _startPeriodicDetection();
  }

  void _showResultDialog(ExpiryData expiryData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Expiry Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_capturedImage != null)
              Image.memory(
                _capturedImage!,
                height: 200,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 16),
            Text(
              'Expiry Date: ${_formatDate(expiryData.expiryDate!)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(expiryData.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getConfidenceColor(expiryData.confidence),
              ),
            ),
            if (expiryData.rawText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Detected text: ${expiryData.rawText}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartDetection();
            },
            child: const Text('Retry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, expiryData); // Return to previous screen
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showRetryMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Expiry Date'),
        backgroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Detection overlay
          if (_currentDetections.isNotEmpty && !_isProcessing)
            Positioned.fill(
              child: CustomPaint(
                painter: DetectionPainter(
                  detections: _currentDetections,
                  cameraSize: _cameraController?.value.previewSize ?? const Size(1, 1),
                ),
              ),
            ),

          // Instructions overlay
          if (!_isProcessing)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Point camera at expiry label',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentDetections.isNotEmpty)
                      Text(
                        '${_currentDetections.length} label(s) detected',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                        ),
                      )
                    else
                      const Text(
                        'Searching for labels...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Processing indicator
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing expiry date...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Manual capture button
          if (!_isProcessing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    if (_isCameraInitialized) {
                      final image = await _cameraController!.takePicture();
                      final imageBytes = await image.readAsBytes();
                      
                      // Run detection on captured image
                      final detections = await _detectorService.detect(imageBytes);
                      
                      if (detections.isNotEmpty) {
                        setState(() {
                          _currentDetections = detections;
                        });
                        await _captureAndProcess(imageBytes);
                      } else {
                        _showError('No expiry labels detected');
                      }
                    }
                  },
                  icon: const Icon(Icons.camera),
                  label: const Text('Capture'),
                  backgroundColor: Colors.deepOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing detection boxes
class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size cameraSize;

  DetectionPainter({
    required this.detections,
    required this.cameraSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      // Calculate scale factors (camera preview size vs actual display size)
      final scaleX = size.width / cameraSize.width;
      final scaleY = size.height / cameraSize.height;

      // Scale bounding box
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          detection.boundingBox.left * scaleX,
          detection.boundingBox.top * scaleY,
          detection.boundingBox.width * scaleX,
          detection.boundingBox.height * scaleY,
        ),
        const Radius.circular(8),
      );

      // Draw bounding box
      final paint = Paint()
        ..color = _getColorForClass(detection.className)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRRect(rect, paint);

      // Draw label background
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${detection.className} ${(detection.confidence * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        detection.boundingBox.left * scaleX,
        (detection.boundingBox.top * scaleY) - 30,
        textPainter.width + 8,
        24,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = _getColorForClass(detection.className),
      );

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(labelRect.left + 4, labelRect.top + 4),
      );
    }
  }

  Color _getColorForClass(String className) {
    switch (className) {
      case 'exp':
        return Colors.red;
      case 'use_by':
        return Colors.orange;
      case 'best_before':
        return Colors.green;
      case 'mfg':
        return Colors.blue;
      case 'pkd':
        return Colors.purple;
      case 'date_value':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return detections != oldDelegate.detections;
  }
}
