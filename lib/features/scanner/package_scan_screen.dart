import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

class PackageScanScreen extends StatefulWidget {
  final String barcode;
  final String barcodeFormat;

  const PackageScanScreen({
    super.key,
    required this.barcode,
    required this.barcodeFormat,
  });

  @override
  State<PackageScanScreen> createState() => _PackageScanScreenState();
}

class _PackageScanScreenState extends State<PackageScanScreen> {
  CameraController? _cameraController;
  final _textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
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

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (mounted) {
        Navigator.pop(context, {
          'barcode': widget.barcode,
          'barcodeFormat': widget.barcodeFormat,
          'ocrText': recognizedText.text,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Failed to capture: ${e.toString()}');
      }
    }
  }

  void _skipPackageScan() {
    Navigator.pop(context, {
      'barcode': widget.barcode,
      'barcodeFormat': widget.barcodeFormat,
      'ocrText': null,
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Package', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_cameraReady && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            ),
          if (!_cameraReady)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00FF7F)),
                    SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _cameraReady ? const Color(0xFF00FF7F) : Colors.grey,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_cameraReady && !_isProcessing)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Point camera at package text',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Focus on EXP/MFG date and product name',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00FF7F)),
                    SizedBox(height: 16),
                    Text(
                      'Processing text...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          if (_cameraReady && !_isProcessing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _captureAndProcess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF7F),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera, color: Colors.black, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Capture Package',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _skipPackageScan,
                    child: const Text(
                      'Skip (Enter manually)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
