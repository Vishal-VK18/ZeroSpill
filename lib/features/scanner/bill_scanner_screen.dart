import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'bill_ocr_parser.dart';
import 'scan_result_preview_screen.dart';

class BillScannerScreen extends StatefulWidget {
  const BillScannerScreen({super.key});

  @override
  State<BillScannerScreen> createState() => _BillScannerScreenState();
}

class _BillScannerScreenState extends State<BillScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final BillOcrParser _billParser = BillOcrParser();
  bool _isProcessing = false;

  Future<void> _captureWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        await _processBillImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        _showError('Camera error: ${e.toString()}');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        await _processBillImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gallery error: ${e.toString()}');
      }
    }
  }

  Future<void> _processBillImage(String imagePath) async {
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _billParser.parseBill(imagePath);

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (result.success && result.products.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultPreviewScreen(
              products: result.products,
              billImagePath: imagePath,
            ),
          ),
        ).then((_) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else if (result.success && result.products.isEmpty) {
        _showError('No products detected in bill. Please try again.');
      } else {
        _showError(result.errorMessage ?? 'Failed to process bill');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Processing error: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Bill',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Processing bill...',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Extracting product names',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.receipt_long,
                    size: 100,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Scan Your Bill',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Automatically extract products from your grocery bill',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildOptionButton(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Capture Bill',
                    subtitle: 'Take a photo with camera',
                    onTap: _captureWithCamera,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _buildOptionButton(
                    context,
                    icon: Icons.photo_library,
                    title: 'Upload Bill',
                    subtitle: 'Choose from gallery',
                    onTap: _pickFromGallery,
                    colorScheme: colorScheme,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Make sure the bill is clear and well-lit for best results',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
