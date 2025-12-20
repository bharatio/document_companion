import 'dart:async';

import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/local_database/models/image_model.dart';

class ImageBloc {
  final StreamController<List<ImageModel>> _imageController =
      StreamController<List<ImageModel>>.broadcast();
  
  Stream<List<ImageModel>> get imageStream => _imageController.stream;

  Future<void> fetchImagesByFolderId(String folderId) async {
    try {
      final images = await imageDatabaseHandler.getImagesByFolderId(folderId);
      _imageController.sink.add(images);
    } catch (e) {
      print('Error fetching images: $e');
      _imageController.sink.add([]);
    }
  }

  Future<int> getImageCount(String folderId) async {
    try {
      return await imageDatabaseHandler.getImageCountByFolderId(folderId);
    } catch (e) {
      print('Error getting image count: $e');
      return 0;
    }
  }

  void dispose() {
    _imageController.close();
  }
}

final imageBloc = ImageBloc();

