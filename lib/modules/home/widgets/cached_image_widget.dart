import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';

class CachedImageWidget extends StatefulWidget {
  final Uint8List imageData;
  final String imageId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    super.key,
    required this.imageData,
    required this.imageId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  Uint8List? _thumbnail;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final thumbnail = await imageCacheService.getThumbnail(
        widget.imageId,
        widget.imageData,
      );

      if (mounted) {
        setState(() {
          _thumbnail = thumbnail ?? widget.imageData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _thumbnail = widget.imageData; // Fallback to full image
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    if (_isLoading && widget.placeholder != null) {
      return widget.placeholder!;
    }

    if (_thumbnail == null) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    final imageWidget = Image.memory(
      _thumbnail!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            );
      },
    );

    // If width/height are not specified, expand to fill available space
    if (widget.width == null && widget.height == null) {
      return SizedBox.expand(child: imageWidget);
    }

    return imageWidget;
  }
}

