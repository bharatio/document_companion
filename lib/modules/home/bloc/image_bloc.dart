import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/local_database/models/image_model.dart';

class ImageBloc {
  final StreamController<List<ImageModel>> _imageController =
      StreamController<List<ImageModel>>.broadcast();

  Stream<List<ImageModel>> get imageStream => _imageController.stream;

  List<ImageModel> _allImages = [];
  String _searchQuery = '';

  Future<void> fetchImagesByFolderId(String folderId) async {
    try {
      // Clear search query when loading a new folder to prevent stale filters
      _searchQuery = '';
      _allImages = await imageDatabaseHandler.getImagesByFolderId(folderId);
      _applySearch();
    } catch (e) {
      debugPrint('Error fetching images: $e');
      _allImages = [];
      _searchQuery = '';
      _imageController.sink.add([]);
    }
  }

  void searchImages(String query) {
    _searchQuery = query.toLowerCase();
    _applySearch();
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearch();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _imageController.sink.add(_allImages);
    } else {
      final filtered = _allImages.where((image) {
        return image.name.toLowerCase().contains(_searchQuery);
      }).toList();
      _imageController.sink.add(filtered);
    }
  }

  Future<int> getImageCount(String folderId) async {
    try {
      return await imageDatabaseHandler.getImageCountByFolderId(folderId);
    } catch (e) {
      debugPrint('Error getting image count: $e');
      return 0;
    }
  }

  void dispose() {
    _imageController.close();
  }
}

final imageBloc = ImageBloc();
