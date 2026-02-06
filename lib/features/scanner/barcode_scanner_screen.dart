import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _cameraReady = false;
  String? _lastScannedValue;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _cameraReady = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_cameraReady) return;
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    
    final String? scannedValue = barcode.rawValue;
    
    debugPrint('=== BARCODE SCAN DEBUG ===');
    debugPrint('Format: ${barcode.format.name}');
    debugPrint('Raw Value: $scannedValue');
    debugPrint('Raw Value Length: ${scannedValue?.length ?? 0}');
    debugPrint('========================');
    
    if (scannedValue == null || scannedValue.isEmpty) {
      return;
    }

    if (scannedValue.length < 8) {
      return;
    }

    final now = DateTime.now();
    if (_lastScannedValue == scannedValue && _lastScanTime != null) {
      final timeSinceLastScan = now.difference(_lastScanTime!);
      if (timeSinceLastScan.inSeconds < 2) {
        return;
      }
    }

    _lastScannedValue = scannedValue;
    _lastScanTime = now;

    setState(() => _isProcessing = true);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pop(context, {
          'rawValue': scannedValue,
          'format': barcode.format.name,
        });
      }
    });
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
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _cameraReady ? const Color(0xFF00FF7F) : Colors.grey,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (!_cameraReady)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
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
          if (_cameraReady && !_isProcessing)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Hold steady - Align barcode inside frame',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (_isProcessing)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF7F).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.black, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Scanned! Processing...',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_cameraReady)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        final torchState = value.torchState;
                        return Icon(
                          torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 32,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    onPressed: () => _controller.switchCamera(),
                    icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
