import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../ml/expiry_detector_service.dart';
import '../../ml/expiry_region_cropper.dart';
import '../../ml/expiry_text_parser.dart';
import '../../ml/shelf_life_estimator.dart';
import 'expiry_detector.dart';

/// Dedicated expiry date capture screen with manual capture button
/// Uses three-stage detection pipeline:
/// 1. YOLO ML region detection
/// 2. OCR on detected regions  
/// 3. Fallback full-image OCR
class ExpiryCaptureScreen extends StatefulWidget {
  const ExpiryCaptureScreen({super.key});

  @override
  State<ExpiryCaptureScreen> createState() => _ExpiryCaptureScreenState();
}

class _ExpiryCaptureScreenState extends State<ExpiryCaptureScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Align expiry date and press Capture';
  final ExpiryDetectorService _detectorService = ExpiryDetectorService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _detectorService.initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _statusMessage = 'No camera available');
        return;
      }

      // Use back camera with high resolution
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'Align expiry date and press Capture';
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() => _statusMessage = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detectorService.dispose();
    super.dispose();
  }

  /// Handle capture button press
  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not ready');
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing image...';
    });

    try {
      // Capture high-resolution image
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      setState(() => _statusMessage = 'Detecting expiry date...');

      // Run three-stage detection pipeline
      final expiryResult = await _detectExpiry(imageBytes);

      if (expiryResult != null && expiryResult.hasValidExpiry) {
        // Success - return result to previous screen
        if (mounted) {
          Navigator.pop(context, {
            'expiryDate': expiryResult.expiryDate,
            'confidence': expiryResult.confidence,
            'rawText': expiryResult.rawText,
            'detectionSource': 'ML_OCR',
          });
        }
      } else {
        // Failed - show manual entry option
        await _showManualEntryDialog();
      }
    } catch (e) {
      debugPrint('Capture and detect error: $e');
      _showError('Detection failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Align expiry date and press Capture';
        });
      }
    }
  }

  /// Multi-pass detection pipeline with candidate collection
  Future<ExpiryData?> _detectExpiry(Uint8List imageBytes) async {
    try {
      print('═══════════════════════════════════════');
      print('🚀 MULTI-PASS EXPIRY DETECTION STARTED');
      print('═══════════════════════════════════════');
      print('');

      final List<DateCandidate> allCandidates = [];

      // PASS 1: ML Region Detection
      print('📍 PASS 1: ML Region Detection');
      final detections = await _detectorService.detect(imageBytes);
      print('   Regions detected: ${detections.length}');

      if (detections.isNotEmpty) {
        for (var detection in detections) {
          print('   • ${detection.className} (confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%)');
        }

        // PASS 2: OCR on Detected Regions
        print('');
        print('📍 PASS 2: OCR on Detected Regions');
        
        final regions = detections
            .map((d) => DetectionRegion(
                  boundingBox: d.boundingBox,
                  className: d.className,
                  confidence: d.confidence,
                ))
            .toList();

        final mergedRegions = ExpiryRegionCropper.mergeNearbyRegions(regions);
        print('   Merged ${detections.length} → ${mergedRegions.length} regions');

        final croppedRegions = ExpiryRegionCropper.cropMultipleRegions(
          imageBytes,
          mergedRegions,
          padding: 15,
        );

        // Collect candidates from each region
        for (var i = 0; i < croppedRegions.length; i++) {
          final region = croppedRegions[i];
          print('');
          print('   Region ${i + 1}/${croppedRegions.length}: ${region.className}');
          
          final expiryData = await ExpiryTextParser.parseExpiryText(
            region.imageBytes,
            region.className,
          );

          print('     Raw text: "${expiryData.rawText.replaceAll('\n', ' ').substring(0, expiryData.rawText.length > 50 ? 50 : expiryData.rawText.length)}..."');
          
          // Add expiry date candidate
          if (expiryData.hasValidExpiry) {
            final label = _getLabelFromClassName(region.className);
            allCandidates.add(DateCandidate(
              date: expiryData.expiryDate!,
              label: label,
              confidence: expiryData.confidence,
              source: 'ML_REGION',
            ));
            print('     ✓ Expiry found: ${expiryData.expiryDate}');
          }
          
          // Add MFG date candidate
          if (expiryData.hasValidMfg) {
            allCandidates.add(DateCandidate(
              date: expiryData.manufacturingDate!,
              label: 'MFG',
              confidence: expiryData.confidence * 0.8,
              source: 'ML_REGION',
            ));
            print('     ✓ MFG found: ${expiryData.manufacturingDate}');
          }
          
          // Add PKD date candidate
          if (expiryData.hasValidPacked) {
            allCandidates.add(DateCandidate(
              date: expiryData.packedDate!,
              label: 'PKD',
              confidence: expiryData.confidence * 0.8,
              source: 'ML_REGION',
            ));
            print('     ✓ PKD found: ${expiryData.packedDate}');
          }
        }
      } else {
        print('   ⚠️ No regions detected by ML model');
      }

      // PASS 3: Fallback Full-Image OCR
      print('');
      print('📍 PASS 3: Full-Image OCR Fallback');
      final fallbackCandidates = await _runFullImageOCR(imageBytes);
      allCandidates.addAll(fallbackCandidates);
      print('   Found ${fallbackCandidates.length} candidates from full-image OCR');

      // Select best candidate
      print('');
      print('📊 CANDIDATE SUMMARY');
      print('   Total candidates collected: ${allCandidates.length}');
      
      if (allCandidates.isEmpty) {
        print('   ❌ No date candidates found');
        print('═══════════════════════════════════════');
        return null;
      }

      // Try to select best expiry candidate
      final selectedDate = DateCandidateSelector.selectBestCandidate(allCandidates);
      
      if (selectedDate != null) {
        print('');
        print('✅ FINAL SELECTION: $selectedDate');
        print('═══════════════════════════════════════');
        
        return ExpiryData(
          expiryDate: selectedDate,
          rawText: 'Multi-pass detection',
          confidence: 0.85,
        );
      }

      print('═══════════════════════════════════════');
      return null;
    } catch (e) {
      print('❌ Detection error: $e');
      print('═══════════════════════════════════════');
      return null;
    }
  }

  /// PASS 3: Fallback full-image OCR with MFG estimation
  Future<List<DateCandidate>> _runFullImageOCR(Uint8List imageBytes) async {
    final List<DateCandidate> candidates = [];
    
    try {
      final result = await ExpiryTextParser.parseExpiryText(
        imageBytes,
        'full_image',
      );

      print('   Full text length: ${result.rawText.length} characters');

      // Add expiry date
      if (result.hasValidExpiry) {
        candidates.add(DateCandidate(
          date: result.expiryDate!,
          label: 'UNLABELED',
          confidence: result.confidence,
          source: 'FULL_IMAGE',
        ));
        print('   ✓ Expiry date found');
      }

      // Add MFG date and estimate expiry
      if (result.hasValidMfg) {
        candidates.add(DateCandidate(
          date: result.manufacturingDate!,
          label: 'MFG',
          confidence: result.confidence * 0.7,
          source: 'FULL_IMAGE',
        ));
        print('   ✓ MFG date found');
        
        // Estimate expiry from MFG
        final estimatedExpiry = ShelfLifeEstimator.estimateExpiryFromMfg(
          result.manufacturingDate!,
        );
        
        if (estimatedExpiry != null) {
          candidates.add(DateCandidate(
            date: estimatedExpiry,
            label: 'MFG_ESTIMATED',
            confidence: 0.6,
            source: 'MFG_ESTIMATED',
          ));
          print('   ✓ Estimated expiry from MFG: $estimatedExpiry');
        }
      }

      // Add PKD date
      if (result.hasValidPacked) {
        candidates.add(DateCandidate(
          date: result.packedDate!,
          label: 'PKD',
          confidence: result.confidence * 0.7,
          source: 'FULL_IMAGE',
        ));
        print('   ✓ PKD date found');
      }

      // Try HumanLikeExpiryDetector as additional fallback
      if (result.rawText.isNotEmpty && candidates.isEmpty) {
        print('   Trying HumanLikeExpiryDetector...');
        final detector = HumanLikeExpiryDetector();
        final expiryConfidence = detector.detectExpiry(result.rawText);

        if (expiryConfidence.date != null) {
          candidates.add(DateCandidate(
            date: expiryConfidence.date!,
            label: 'UNLABELED',
            confidence: expiryConfidence.confidence,
            source: 'FULL_IMAGE',
          ));
          print('   ✓ HumanLikeExpiryDetector found date');
        }
      }

      return candidates;
    } catch (e) {
      print('   ❌ Full-image OCR error: $e');
      return candidates;
    }
  }

  /// Convert class name to label
  String _getLabelFromClassName(String className) {
    switch (className.toLowerCase()) {
      case 'exp':
        return 'EXP';
      case 'use_by':
        return 'USE_BY';
      case 'best_before':
        return 'BEST_BEFORE';
      case 'mfg':
        return 'MFG';
      case 'pkd':
        return 'PKD';
      default:
        return 'UNLABELED';
    }
  }

  Future<void> _showManualEntryDialog() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expiry Date Not Detected'),
        content: const Text(
          'Could not automatically detect the expiry date.\n\n'
          'Would you like to:\n'
          '• Try again with better lighting\n'
          '• Enter the date manually',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enter Manually'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Return null to indicate manual entry needed
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      final currentFlashMode = _cameraController!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;

      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {});
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Expiry Date',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_cameraController != null)
            IconButton(
              icon: Icon(
                _cameraController!.value.flashMode == FlashMode.torch
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Instruction overlay
          if (_isCameraInitialized && !_isProcessing)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF00FF7F),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Capture button
          if (_isCameraInitialized && !_isProcessing)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndDetect,
                  child: Container(
                    width: 200,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'CAPTURE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
