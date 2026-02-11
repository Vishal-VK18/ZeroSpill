import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'expiry_detector_service.dart';

/// Utility class for cropping detected expiry regions from images
class ExpiryRegionCropper {
  /// Crop a specific region from an image
  static Uint8List? cropRegion(
    Uint8List imageBytes,
    BoundingBox boundingBox, {
    int padding = 10,
  }) {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Failed to decode image for cropping');
        return null;
      }

      // Add padding and ensure bounds are within image
      final int x = (boundingBox.left - padding).clamp(0, image.width - 1).toInt();
      final int y = (boundingBox.top - padding).clamp(0, image.height - 1).toInt();
      final int width = (boundingBox.width + 2 * padding)
          .clamp(1, image.width - x)
          .toInt();
      final int height = (boundingBox.height + 2 * padding)
          .clamp(1, image.height - y)
          .toInt();

      // Crop the region
      final cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      // Apply preprocessing for better OCR
      final processed = _preprocessForOCR(cropped);

      // Encode back to bytes
      return Uint8List.fromList(img.encodeJpg(processed, quality: 95));
    } catch (e) {
      print('Error cropping region: $e');
      return null;
    }
  }

  /// Crop multiple regions from the same image
  static List<CroppedRegion> cropMultipleRegions(
    Uint8List imageBytes,
    List<DetectionRegion> regions, {
    int padding = 10,
  }) {
    final croppedRegions = <CroppedRegion>[];

    for (final region in regions) {
      final croppedBytes = cropRegion(
        imageBytes,
        region.boundingBox,
        padding: padding,
      );

      if (croppedBytes != null) {
        croppedRegions.add(CroppedRegion(
          imageBytes: croppedBytes,
          className: region.className,
          confidence: region.confidence,
          originalBoundingBox: region.boundingBox,
        ));
      }
    }

    return croppedRegions;
  }

  /// Preprocess cropped image for better OCR accuracy
  static img.Image _preprocessForOCR(img.Image image) {
    // Step 1: Convert to grayscale for better text detection
    final grayscale = img.grayscale(image);

    // Step 2: Apply bilateral filter to reduce noise while preserving edges
    // This helps clean up noisy backgrounds without blurring text edges
    img.Image denoised = grayscale;
    // Note: img package doesn't have built-in bilateral filter,
    // so we use gaussian blur as alternative for noise reduction
    if (grayscale.width > 50 && grayscale.height > 50) {
      denoised = img.gaussianBlur(grayscale, radius: 1);
    }

    // Step 3: Auto-adjust contrast and brightness for better text visibility
    final autoAdjusted = img.adjustColor(
      denoised,
      contrast: 1.5,      // Increased from 1.3
      brightness: 1.15,   // Increased from 1.1
      saturation: 0,      // Remove any remaining color
    );

    // Step 4: Apply adaptive thresholding simulation
    // High contrast makes text stand out more for OCR
    final contrasted = img.contrast(autoAdjusted, contrast: 150);

    // Step 5: Upscale if too small - OCR works much better with larger text
    // Minimum recommended width for good OCR: 400px
    if (contrasted.width < 400 || contrasted.height < 200) {
      final scaleFactorW = 400 / contrasted.width;
      final scaleFactorH = 200 / contrasted.height;
      final scaleFactor = scaleFactorW > scaleFactorH ? scaleFactorW : scaleFactorH;
      final finalScale = scaleFactor.clamp(2.0, 4.0); // More aggressive upscaling
      
      return img.copyResize(
        contrasted,
        width: (contrasted.width * finalScale).toInt(),
        height: (contrasted.height * finalScale).toInt(),
        interpolation: img.Interpolation.cubic, // Cubic gives sharper text
      );
    }

    return contrasted;
  }

  /// Create a composite image showing all detected regions with labels
  static Uint8List? createAnnotatedImage(
    Uint8List imageBytes,
    List<DetectionRegion> detections,
  ) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Draw bounding boxes on the image
      for (final detection in detections) {
        final box = detection.boundingBox;
        
        // Draw rectangle
        img.drawRect(
          image,
          x1: box.left.toInt(),
          y1: box.top.toInt(),
          x2: box.right.toInt(),
          y2: box.bottom.toInt(),
          color: _getColorForClass(detection.className),
          thickness: 3,
        );

        // Draw label background
        final labelText = '${detection.className} ${(detection.confidence * 100).toInt()}%';
        final labelY = (box.top - 25).clamp(0, image.height - 30).toInt();
        
        img.fillRect(
          image,
          x1: box.left.toInt(),
          y1: labelY,
          x2: (box.left + 150).toInt(),
          y2: labelY + 20,
          color: _getColorForClass(detection.className),
        );

        // Draw label text
        img.drawString(
          image,
          labelText,
          font: img.arial24,
          x: box.left.toInt() + 5,
          y: labelY + 2,
          color: img.ColorRgb8(255, 255, 255),
        );
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    } catch (e) {
      print('Error creating annotated image: $e');
      return null;
    }
  }

  /// Merge nearby detection regions into larger boxes
  /// This helps when "USE BY" and "12/2026" are detected separately
  static List<DetectionRegion> mergeNearbyRegions(
    List<DetectionRegion> regions, {
    double proximityThreshold = 50.0, // pixels
  }) {
    if (regions.length <= 1) return regions;

    final merged = <DetectionRegion>[];
    final processed = List.filled(regions.length, false);

    for (int i = 0; i < regions.length; i++) {
      if (processed[i]) continue;

      var mergedBox = regions[i].boundingBox;
      var totalConfidence = regions[i].confidence;
      var count = 1;

      // Find nearby regions
      for (int j = i + 1; j < regions.length; j++) {
        if (processed[j]) continue;

        final distance = _calculateBoxDistance(
          regions[i].boundingBox,
          regions[j].boundingBox,
        );

        if (distance < proximityThreshold) {
          // Merge boxes by taking bounding rectangle
          mergedBox = _mergeBoundingBoxes(mergedBox, regions[j].boundingBox);
          totalConfidence += regions[j].confidence;
          count++;
          processed[j] = true;
        }
      }

      processed[i] = true;
      merged.add(DetectionRegion(
        boundingBox: mergedBox,
        className: regions[i].className,
        confidence: totalConfidence / count, // Average confidence
      ));
    }

    return merged;
  }

  /// Calculate minimum distance between two bounding boxes
  static double _calculateBoxDistance(BoundingBox box1, BoundingBox box2) {
    // Calculate center points
    final cx1 = box1.centerX;
    final cy1 = box1.centerY;
    final cx2 = box2.centerX;
    final cy2 = box2.centerY;

    // Euclidean distance between centers
    final dx = cx2 - cx1;
    final dy = cy2 - cy1;
    return sqrt(dx * dx + dy * dy);
  }

  /// Merge two bounding boxes into one that contains both
  static BoundingBox _mergeBoundingBoxes(BoundingBox box1, BoundingBox box2) {
    final left = box1.left < box2.left ? box1.left : box2.left;
    final top = box1.top < box2.top ? box1.top : box2.top;
    final right = box1.right > box2.right ? box1.right : box2.right;
    final bottom = box1.bottom > box2.bottom ? box1.bottom : box2.bottom;

    return BoundingBox(
      left,
      top,
      right - left,
      bottom - top,
    );
  }

  /// Get color for bounding box based on class
  static img.Color _getColorForClass(String className) {
    switch (className) {
      case 'exp':
        return img.ColorRgb8(255, 0, 0); // Red for expiry
      case 'use_by':
        return img.ColorRgb8(255, 165, 0); // Orange for use by
      case 'best_before':
        return img.ColorRgb8(0, 255, 0); // Green for best before
      case 'mfg':
        return img.ColorRgb8(0, 0, 255); // Blue for manufacturing
      case 'pkd':
        return img.ColorRgb8(147, 112, 219); // Purple for packed
      case 'date_value':
        return img.ColorRgb8(255, 255, 0); // Yellow for date values
      default:
        return img.ColorRgb8(128, 128, 128); // Gray for unknown
    }
  }
}

/// Detection region data
class DetectionRegion {
  final BoundingBox boundingBox;
  final String className;
  final double confidence;

  DetectionRegion({
    required this.boundingBox,
    required this.className,
    required this.confidence,
  });
}

/// Cropped region with metadata
class CroppedRegion {
  final Uint8List imageBytes;
  final String className;
  final double confidence;
  final BoundingBox originalBoundingBox;

  CroppedRegion({
    required this.imageBytes,
    required this.className,
    required this.confidence,
    required this.originalBoundingBox,
  });
}
