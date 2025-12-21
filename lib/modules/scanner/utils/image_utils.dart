import 'dart:math';

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/area.dart';
import '../models/contour.dart';
import '../models/filter_type.dart';

class ImageUtils {
  final _methodChannel = const MethodChannel(
    "dev.abhishekthakur/document_companion",
  );

  /// Calculates the rect of the image
  Rect imageRect(Size screenSize) {
    return Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
  }

  /// Apply filters to the image with opencv
  /// Then get the contours and return only the largest one that has four sides
  /// (this is done from native code)
  ///
  /// The [Contour.points] are sorted and returned [Area]
  Future<Area?> findContourPhoto(
    Uint8List byteData, {
    double? minContourArea,
  }) async {
    try {
      final contour = await _methodChannel.invokeMethod("findContourPhoto", {
        "byteData": byteData,
        "minContourArea": minContourArea ?? 80000.0,
      });

      final contourParsed = Contour.fromMap(Map<String, dynamic>.from(contour));
      if (contourParsed.points.isEmpty) return null;
      if (contourParsed.points.length != 4) return null;

      // Identify each side of the contour
      int numTopFound = 0;
      int numBottomFound = 0;

      Point<double> top1 = const Point(0, 0);
      Point<double> top2 = const Point(0, 0);

      Point<double> bottom1 = const Point(0, 0);
      Point<double> bottom2 = const Point(0, 0);

      Point<double> lastTopFound = const Point(0, 1000000);
      Point<double> lastBottomFound = const Point(0, 0);

      for (int i = 0; i < 4; i++) {
        for (final point in contourParsed.points) {
          if (point.y > lastBottomFound.y) {
            if (bottom1.y == 0 || point.y != bottom1.y) {
              lastBottomFound = point;
            }
          }

          if (point.y < lastTopFound.y) {
            if (top1.y == 0 || point.y != top1.y) {
              lastTopFound = point;
            }
          }
        }

        if (numTopFound <= 2) {
          if (numTopFound == 0) {
            top1 = lastTopFound;
          } else {
            top2 = lastTopFound;
          }
        }

        if (numBottomFound <= 2) {
          if (numBottomFound == 0) {
            bottom1 = lastBottomFound;
          } else {
            bottom2 = lastBottomFound;
          }
        }

        numTopFound++;
        numBottomFound++;
        lastTopFound = const Point(0, 1000000);
        lastBottomFound = const Point(0, 0);
      }

      Point<double> topLeft = const Point(0, 0);
      Point<double> topRight = const Point(0, 0);

      Point<double> bottomLeft = const Point(0, 0);
      Point<double> bottomRight = const Point(0, 0);

      if (top1.x < top2.x) {
        topLeft = top1;
        topRight = top2;
      } else {
        topRight = top1;
        topLeft = top2;
      }

      if (bottom1.x < bottom2.x) {
        bottomLeft = bottom1;
        bottomRight = bottom2;
      } else {
        bottomRight = bottom1;
        bottomLeft = bottom2;
      }

      final anyEqualPoints =
          topRight == topLeft ||
          topRight == bottomLeft ||
          topRight == bottomRight ||
          topLeft == bottomLeft ||
          topLeft == bottomRight ||
          bottomLeft == bottomRight;
      if (anyEqualPoints) {
        return null;
      }

      return Area(
        topRight: topRight,
        topLeft: topLeft,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      );
    } catch (e) {
      developer.log('Error in findContourPhoto: $e');
      return null;
    }
  }

  /// Based on the given [Contour.points], the perspective is created
  /// and a new image is returned [Uint8List]
  /// Falls back to rectangular crop if native perspective adjustment fails
  Future<Uint8List?> adjustingPerspective(
    Uint8List byteData,
    Contour contour,
  ) async {
    try {
      // Try native perspective adjustment first
      final newImage = await _methodChannel.invokeMethod(
        "adjustingPerspective",
        {
          "byteData": byteData,
          "points": contour.points.map((e) => {"x": e.x, "y": e.y}).toList(),
        },
      );

      if (newImage != null && newImage.isNotEmpty) {
        return newImage;
      }

      // Fallback to rectangular crop if native method fails
      developer.log(
        'Native perspective adjustment failed, using fallback rectangular crop',
      );
      return _fallbackRectangularCrop(byteData, contour);
    } catch (e) {
      developer.log('Error in adjustingPerspective', error: e);
      // Fallback to rectangular crop on error
      try {
        return _fallbackRectangularCrop(byteData, contour);
      } catch (fallbackError) {
        developer.log('Fallback crop also failed', error: fallbackError);
        return null;
      }
    }
  }

  /// Fallback rectangular crop when perspective adjustment is not available
  Uint8List? _fallbackRectangularCrop(Uint8List byteData, Contour contour) {
    try {
      // Decode the image
      final image = img.decodeImage(byteData);
      if (image == null) {
        return null;
      }

      // Calculate bounding rectangle from contour points
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final point in contour.points) {
        minX = min(minX, point.x);
        minY = min(minY, point.y);
        maxX = max(maxX, point.x);
        maxY = max(maxY, point.y);
      }

      // Ensure coordinates are within image bounds
      final x = max(0, minX.round());
      final y = max(0, minY.round());
      final width = min(image.width - x, (maxX - minX).round());
      final height = min(image.height - y, (maxY - minY).round());

      if (width <= 0 || height <= 0) {
        return null;
      }

      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      // Encode back to bytes (JPEG format)
      return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 95));
    } catch (e) {
      developer.log('Error in fallback crop', error: e);
      return null;
    }
  }

  /// Apply the selected [filter] using Dart image processing
  /// Falls back to Dart implementation if native method is not available
  Future<Uint8List> applyFilter(Uint8List byteData, FilterType filter) async {
    try {
      // Try native implementation first
      try {
        final newImage = await _methodChannel.invokeMethod("applyFilter", {
          "byteData": byteData,
          "filter": filter.name,
        });

        if (newImage != null && newImage.isNotEmpty) {
          return newImage;
        }
      } catch (e) {
        // Native method not available, fall back to Dart implementation
        developer.log(
          'Native applyFilter not available, using Dart implementation',
        );
      }

      // Use compute to run heavy image processing in an isolate
      return await compute(_applyFilterDartIsolate, {
        'byteData': byteData,
        'filter': filter.name,
      });
    } catch (e) {
      developer.log('Error in applyFilter', error: e);
      return byteData;
    }
  }
}

/// Top-level function for isolate processing
/// This function runs in a separate isolate to avoid blocking the main thread
Uint8List _applyFilterDartIsolate(Map<String, dynamic> params) {
  final byteData = params['byteData'] as Uint8List;
  final filterName = params['filter'] as String;
  
  try {
    // Decode the image
    final image = img.decodeImage(byteData);
    if (image == null) {
      return byteData;
    }

    // Optimize: Limit max dimensions for better performance
    // Process at max 2048px on the longest side to maintain quality while improving speed
    const maxDimension = 2048;
    img.Image imageToProcess = image;
    
    if (image.width > maxDimension || image.height > maxDimension) {
      final scale = maxDimension / max(image.width, image.height);
      imageToProcess = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    img.Image filteredImage;

    // Parse filter type
    final filter = FilterType.values.firstWhere(
      (f) => f.name == filterName,
      orElse: () => FilterType.natural,
    );

    switch (filter) {
      case FilterType.natural:
        // Natural filter: return original image (no changes)
        filteredImage = imageToProcess;
        break;

      case FilterType.gray:
        // Grayscale filter: convert to grayscale
        filteredImage = img.grayscale(imageToProcess);
        break;

      case FilterType.eco:
        // Eco filter: grayscale (eco-friendly, reduces color processing)
        filteredImage = img.grayscale(imageToProcess);
        break;
    }

    // Encode back to JPEG with high quality
    return Uint8List.fromList(img.encodeJpg(filteredImage, quality: 95));
  } catch (e) {
    developer.log('Error in _applyFilterDartIsolate', error: e);
    return byteData;
  }

}
