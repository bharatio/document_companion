import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/models/folder_view_model.dart';
import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:flutter/material.dart';

class FolderService {
  /// Show rename dialog for a folder
  Future<void> showRenameDialog(
    BuildContext context,
    FolderViewModel folder,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: folder.folderName,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await folderBloc.updateFolder(
                  folder.id,
                  nameController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Folder renamed successfully'),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<void> showDeleteConfirmation(
    BuildContext context,
    FolderViewModel folder,
  ) async {
    // Check if folder has images
    final imageCount = await imageBloc.getImageCount(folder.id);

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          imageCount > 0
              // ignore: unnecessary_brace_in_string_interps
              ? 'Are you sure you want to delete "${folder.folderName}"? This will also delete all ${imageCount} document${imageCount == 1 ? '' : 's'} in this folder.'
              : 'Are you sure you want to delete "${folder.folderName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete all images in the folder first
              if (imageCount > 0) {
                await imageDatabaseHandler.deleteImagesByFolderId(folder.id);
              }

              // Delete the folder
              await folderBloc.deleteFolder(folder.id);

              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to homepage
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '"${folder.folderName}" deleted successfully',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

final folderService = FolderService();
