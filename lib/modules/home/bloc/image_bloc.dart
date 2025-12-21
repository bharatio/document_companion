import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/local_database/handler/tag_database_handler.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/models/date_filter_model.dart';
import 'package:intl/intl.dart';

class ImageBloc {
  final StreamController<List<ImageModel>> _imageController =
      StreamController<List<ImageModel>>.broadcast();

  Stream<List<ImageModel>> get imageStream => _imageController.stream;

  List<ImageModel> _allImages = [];
  String _searchQuery = '';
  DateFilter _dateFilter = DateFilter.all();
  Set<String> _selectedTagIds = {};

  Future<void> fetchImagesByFolderId(String folderId) async {
    try {
      // Clear search query when loading a new folder to prevent stale filters
      _searchQuery = '';
      _dateFilter = DateFilter.all();
      _selectedTagIds.clear();
      _allImages = await imageDatabaseHandler.getImagesByFolderId(folderId);
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching images: $e');
      _allImages = [];
      _searchQuery = '';
      _dateFilter = DateFilter.all();
      _selectedTagIds.clear();
      _imageController.sink.add([]);
    }
  }

  void searchImages(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  void applyDateFilter(DateFilter filter) {
    _dateFilter = filter;
    _applyFilters();
  }

  void clearDateFilter() {
    _dateFilter = DateFilter.all();
    _applyFilters();
  }

  void applyTagFilter(Set<String> tagIds) {
    _selectedTagIds = Set.from(tagIds);
    _applyFilters();
  }

  void clearTagFilter() {
    _selectedTagIds.clear();
    _applyFilters();
  }

  Set<String> get selectedTagIds => Set.from(_selectedTagIds);

  DateFilter get currentDateFilter => _dateFilter;

  void _applyFilters() {
    var filtered = List<ImageModel>.from(_allImages);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((image) {
        return image.name.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply date filter
    if (_dateFilter.isActive && _dateFilter.startDate != null) {
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      filtered = filtered.where((image) {
        try {
          final imageDate = dateFormat.parse(image.createdOn);
          final start = _dateFilter.startDate!;
          final end = _dateFilter.endDate ?? DateTime.now();

          return imageDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              imageDate.isBefore(end);
        } catch (e) {
          debugPrint('Error parsing date: $e');
          return false;
        }
      }).toList();
    }

    // Apply tag filter (will be applied asynchronously if tags are selected)
    _imageController.sink.add(filtered);

    // Apply tag filter asynchronously if needed
    if (_selectedTagIds.isNotEmpty) {
      _applyTagFilter(filtered);
    }
  }

  Future<void> _applyTagFilter(List<ImageModel> images) async {
    final filteredImages = <ImageModel>[];

    for (var image in images) {
      final imageTags = await tagDatabaseHandler.getTagsByDocumentId(image.id);
      final imageTagIds = imageTags.map((tag) => tag.id).toSet();

      if (_selectedTagIds.any((tagId) => imageTagIds.contains(tagId))) {
        filteredImages.add(image);
      }
    }

    _imageController.sink.add(filteredImages);
  }

  Future<int> getImageCount(String folderId) async {
    try {
      return await imageDatabaseHandler.getImageCountByFolderId(folderId);
    } catch (e) {
      debugPrint('Error getting image count: $e');
      return 0;
    }
  }

  Future<ImageModel?> getImageById(String id) async {
    try {
      return await imageDatabaseHandler.getImageById(id);
    } catch (e) {
      debugPrint('Error getting image by id: $e');
      return null;
    }
  }

  Future<List<ImageModel>> getImagesByFolderId(String folderId) async {
    try {
      return await imageDatabaseHandler.getImagesByFolderId(folderId);
    } catch (e) {
      debugPrint('Error getting images by folder id: $e');
      return [];
    }
  }

  void dispose() {
    _imageController.close();
  }
}

final imageBloc = ImageBloc();
