import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';

class FileImportService {
  final ImagePicker _picker = ImagePicker();

  /// Import single image from gallery
  Future<void> importImageFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        await currentImageBloc.saveCurrentImage(imageBytes);
        await currentImageBloc.getCurrentImage();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image imported successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing image: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Import multiple images from gallery
  Future<void> importMultipleImagesFromGallery(BuildContext context) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 90,
      );

      if (images.isEmpty) return;

      int successCount = 0;
      for (var image in images) {
        try {
          final Uint8List imageBytes = await image.readAsBytes();
          await currentImageBloc.saveCurrentImage(imageBytes);
          successCount++;
        } catch (e) {
          print('Error importing image ${image.name}: $e');
        }
      }

      await currentImageBloc.getCurrentImage();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported $successCount of ${images.length} image(s) successfully',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing images: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show import options dialog
  Future<void> showImportOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Import Single Image'),
                subtitle: const Text('Select one image from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  importImageFromGallery(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Import Multiple Images'),
                subtitle: const Text('Select multiple images from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  importMultipleImagesFromGallery(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

final fileImportService = FileImportService();

