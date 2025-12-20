import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../local_database/handler/current_images_database_handler.dart';
import '../../../local_database/models/current_image.dart';

class CurrentImageBloc {
  final StreamController<List<CurrentImage>> _currentImageController =
      StreamController<List<CurrentImage>>.broadcast();
  Stream<List<CurrentImage>> get currentImageStream =>
      _currentImageController.stream;

  final CurrentImageDatabaseHandler _databaseHandler =
      CurrentImageDatabaseHandler();
  final Uuid _uuid = Uuid();
  Future<void> saveCurrentImage(Uint8List currentImage) async {
    try {
      _databaseHandler.insertImage(
        CurrentImage(
          image: currentImage,
          timestamp: DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
          isShootThroughFastCamera: false,
          lowResImage: currentImage,
          id: _uuid.v4(),
        ),
      );
    } catch (e) {
      developer.log('Error saving current image', error: e);
    }
  }

  Future<void> getCurrentImage() async {
    try {
      final currentImage = await _databaseHandler.getCurrentImage();
      _currentImageController.sink.add(currentImage);
    } catch (e) {
      developer.log('Error getting current image', error: e);
      return;
    }
  }

  Future<void> deleteCurrentImages() async {
    try {
      _databaseHandler.deleteCurrentImage();
      await getCurrentImage(); // Refresh stream after deletion
    } catch (e) {
      developer.log('Error deleting current images', error: e);
    }
  }

  Future<List<CurrentImage>> getCurrentImagesList() async {
    try {
      return await _databaseHandler.getCurrentImage();
    } catch (e) {
      developer.log('Error getting current images list', error: e);
      return [];
    }
  }
}

final currentImageBloc = CurrentImageBloc();
