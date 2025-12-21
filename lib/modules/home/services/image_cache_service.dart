import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};
  static const int maxMemoryCacheSize = 50; // Max images in memory cache
  static const int thumbnailSize = 200; // Thumbnail max dimension

  /// Get cached thumbnail or generate one
  Future<Uint8List?> getThumbnail(String imageId, Uint8List fullImage) async {
    // Check memory cache first
    if (_memoryCache.containsKey(imageId)) {
      return _memoryCache[imageId];
    }

    // Check disk cache
    final thumbnail = await _getThumbnailFromDisk(imageId);
    if (thumbnail != null) {
      _memoryCache[imageId] = thumbnail;
      return thumbnail;
    }

    // Generate thumbnail
    final generated = await _generateThumbnail(fullImage);
    if (generated != null) {
      await _saveThumbnailToDisk(imageId, generated);
      _addToMemoryCache(imageId, generated);
      return generated;
    }

    return null;
  }

  /// Generate thumbnail from full image
  Future<Uint8List?> _generateThumbnail(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      // Calculate thumbnail dimensions maintaining aspect ratio
      int width = image.width;
      int height = image.height;
      
      if (width > height) {
        if (width > thumbnailSize) {
          height = (height * thumbnailSize / width).round();
          width = thumbnailSize;
        }
      } else {
        if (height > thumbnailSize) {
          width = (width * thumbnailSize / height).round();
          height = thumbnailSize;
        }
      }

      // Resize image
      final thumbnail = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG for smaller size
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Save thumbnail to disk cache
  Future<void> _saveThumbnailToDisk(String imageId, Uint8List thumbnail) async {
    try {
      final directory = await _getCacheDirectory();
      final file = File(path.join(directory.path, 'thumb_$imageId.jpg'));
      await file.writeAsBytes(thumbnail);
    } catch (e) {
      debugPrint('Error saving thumbnail to disk: $e');
    }
  }

  /// Get thumbnail from disk cache
  Future<Uint8List?> _getThumbnailFromDisk(String imageId) async {
    try {
      final directory = await _getCacheDirectory();
      final file = File(path.join(directory.path, 'thumb_$imageId.jpg'));
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error reading thumbnail from disk: $e');
    }
    return null;
  }

  /// Get cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'image_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Add to memory cache with size limit
  void _addToMemoryCache(String imageId, Uint8List thumbnail) {
    if (_memoryCache.length >= maxMemoryCacheSize) {
      // Remove oldest entry (simple FIFO)
      final firstKey = _memoryCache.keys.first;
      _memoryCache.remove(firstKey);
    }
    _memoryCache[imageId] = thumbnail;
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// Clear disk cache
  Future<void> clearDiskCache() async {
    try {
      final directory = await _getCacheDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing disk cache: $e');
    }
  }

  /// Clear cache for specific image
  Future<void> clearImageCache(String imageId) async {
    _memoryCache.remove(imageId);
    try {
      final directory = await _getCacheDirectory();
      final file = File(path.join(directory.path, 'thumb_$imageId.jpg'));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    try {
      final directory = await _getCacheDirectory();
      if (!await directory.exists()) return 0;
      
      int totalSize = 0;
      await for (var entity in directory.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }
}

final imageCacheService = ImageCacheService();

