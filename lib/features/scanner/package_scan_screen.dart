import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../ml/expiry_detector_service.dart';
import '../../ml/expiry_region_cropper.dart';
import '../../ml/expiry_text_parser.dart';
import 'expiry_calculator.dart';

class PackageScanScreen extends StatefulWidget {
  final String barcode;
  final String barcodeFormat;
  final String? productName;

  const PackageScanScreen({
    super.key,
    required this.barcode,
    required this.barcodeFormat,
    this.productName,
  });

  @override
  State<PackageScanScreen> createState() => _PackageScanScreenState();
}

class _PackageScanScreenState extends State<PackageScanScreen> {
  CameraController? _cameraController;
  final _detectorService = ExpiryDetectorService();
  final _expiryCalculator = ExpiryCalculator();
  
  bool _isProcessing = false;
  bool _cameraReady = false;
  bool _modelReady = false;
  
  DateTime? _detectedExpiryDate;
  String? _detectionMethod;
  double _detectionConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      // Initialize camera
      await _initCamera();
      
      // Load ML model in background
      _initMLModelInBackground();
    } catch (e) {
      if (mounted) {
        _showError('Initialization error: ${e.toString()}');
      }
    }
  }

  Future<void> _initMLModelInBackground() async {
    try {
      if (!_detectorService.isInitialized) {
        print('🔄 Loading ML model...');
        await _detectorService.initialize();
        print('✅ ML model ready');
      }
      
      if (mounted) {
        setState(() => _modelReady = true);
      }
    } catch (e) {
      print('⚠️ ML model failed to load: $e');
      if (mounted) {
        setState(() => _modelReady = false);
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          _showError('No camera available');
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Camera error: ${e.toString()}');
      }
    }
  }

  /// MANUAL CAPTURE - triggered by button press
  Future<void> _captureAndDetect() async {
    if (!_cameraReady || _cameraController == null) {
      _showError('Camera not ready');
      return;
    }

    if (!_modelReady) {
      _showError('ML model not loaded yet. Please wait...');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Take picture
      final image = await _cameraController!.takePicture();
      final imageBytes = await File(image.path).readAsBytes();

      print('📸 Image captured, running detection...');

      // 2. Run YOLO detection ONCE
      final detections = await _detectorService.detect(imageBytes);

      print('🔍 Found ${detections.length} regions');

      // 3. Process results
      if (detections.isNotEmpty) {
        await _processDetections(imageBytes, detections);
      } else {
        _showError('No expiry date detected. Try moving camera closer to the expiry label.');
      }
    } catch (e) {
      print('❌ Detection error: $e');
      _showError('Detection failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processDetections(Uint8List imageBytes, List<Detection> detections) async {
    try {
      // Crop detected regions
      final regions = detections
          .map((d) => DetectionRegion(
                boundingBox: d.boundingBox,
                className: d.className,
                confidence: d.confidence,
              ))
          .toList();

      final croppedRegions = ExpiryRegionCropper.cropMultipleRegions(
        imageBytes,
        regions,
        padding: 15,
      );

      // Run OCR on each cropped region
      ExpiryData? bestResult;
      double bestConfidence = 0.0;

      for (final region in croppedRegions) {
        final expiryData = await ExpiryTextParser.parseExpiryText(
          region.imageBytes,
          region.className,
        );

        if (expiryData.hasValidExpiry && expiryData.confidence > bestConfidence) {
          bestResult = expiryData;
          bestConfidence = expiryData.confidence;
        }
      }

      if (bestResult != null && bestResult.hasValidExpiry) {
        setState(() {
          _detectedExpiryDate = bestResult!.expiryDate;
          _detectionMethod = 'ML Detection';
          _detectionConfidence = bestResult.confidence;
        });
        _showSuccessDialog(bestResult);
      } else {
        // Fallback: try vegetable expiry calculation
        if (widget.productName != null) {
          final calculatedExpiry = _expiryCalculator.calculateWithDetails(
            widget.productName!,
          );
          if (calculatedExpiry.isCalculated) {
            setState(() {
              _detectedExpiryDate = calculatedExpiry.expiryDate;
              _detectionMethod = 'Auto-calculated (${calculatedExpiry.shelfLifeDays} days)';
              _detectionConfidence = 0.8;
            });
            _returnResult();
            return;
          }
        }
        
        // No expiry found
        _showError('No expiry date found in detected regions. Try again.');
      }
    } catch (e) {
      print('Processing error: $e');
      _showError('Failed to process expiry. Please try again.');
    }
  }

  void _showSuccessDialog(ExpiryData expiryData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('Expiry Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(expiryData.expiryDate!),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getConfidenceColor(expiryData.confidence).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Confidence: ${(expiryData.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _getConfidenceColor(expiryData.confidence),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (expiryData.rawText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Detected: "${expiryData.rawText}"',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Allow another capture
            },
            child: const Text('Retry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _returnResult();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
            child: const Text('Use This Date', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _returnResult() {
    Navigator.pop(context, {
      'barcode': widget.barcode,
      'barcodeFormat': widget.barcodeFormat,
      'expiryDate': _detectedExpiryDate,
      'detectionMethod': _detectionMethod,
      'confidence': _detectionConfidence,
    });
  }

  void _skipToManual() {
    Navigator.pop(context, {
      'barcode': widget.barcode,
      'barcodeFormat': widget.barcodeFormat,
      'expiryDate': null,
      'skipToManual': true,
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.5) return Colors.orange;
    return Colors.red;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Expiry Date', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _skipToManual,
            tooltip: 'Enter manually',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_cameraReady && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Instructions overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _modelReady 
                        ? 'Point camera at expiry date and tap CAPTURE'
                        : 'Loading ML model...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!_modelReady)
                    const SizedBox(height: 8),
                  if (!_modelReady)
                    const LinearProgressIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                ],
              ),
            ),
          ),

          // CAPTURE BUTTON (centered at bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  // Processing indicator
                  if (_isProcessing)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Capture button
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureAndDetect,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProcessing 
                            ? Colors.grey[600] 
                            : Colors.white,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: _isProcessing ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'CAPTURE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
