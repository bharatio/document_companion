import 'dart:io';
import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/models/folder_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DocumentService {
  /// Show rename dialog for a document
  Future<void> showRenameDialog(
    BuildContext context,
    ImageModel image,
    String folderId,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: image.name,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document Name',
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
                final updatedImage = ImageModel(
                  id: image.id,
                  folderId: image.folderId,
                  image: image.image,
                  name: nameController.text.trim(),
                  createdOn: image.createdOn,
                  modifiedOn: DateFormat(
                    'yyyy-MM-dd HH:mm:ss',
                  ).format(DateTime.now()),
                  size: image.size,
                  width: image.width,
                  height: image.height,
                );

                await imageDatabaseHandler.updateImage(updatedImage);
                await imageBloc.fetchImagesByFolderId(folderId);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document renamed successfully'),
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

  /// Share a document
  Future<void> shareDocument(BuildContext context, ImageModel image) async {
    try {
      // Save image to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${image.name}.jpg');
      await file.writeAsBytes(image.image);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], subject: image.name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show move document dialog with folder selection
  Future<void> showMoveDialog(
    BuildContext context,
    ImageModel image,
    String currentFolderId,
  ) async {
    // Fetch all folders
    await folderBloc.fetchFolders();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => StreamBuilder<List<FolderViewModel>>(
        stream: folderBloc.folderList,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          final folders = snapshot.data!;
          // Filter out current folder
          final availableFolders = folders
              .where((f) => f.id != currentFolderId)
              .toList();

          if (availableFolders.isEmpty) {
            return AlertDialog(
              title: const Text('Move Document'),
              content: const Text(
                'No other folders available. Create a folder first.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Move Document'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select destination folder for "${image.name}"',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableFolders.length,
                      itemBuilder: (context, index) {
                        final folder = availableFolders[index];
                        return ListTile(
                          leading: const Icon(Icons.folder_rounded),
                          title: Text(folder.folderName),
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            await _moveDocumentToFolder(
                              dialogContext,
                              image,
                              currentFolderId,
                              folder.id,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Move document to a different folder
  Future<void> _moveDocumentToFolder(
    BuildContext context,
    ImageModel image,
    String sourceFolderId,
    String destinationFolderId,
  ) async {
    try {
      // Update the document's folder_id
      final updatedImage = ImageModel(
        id: image.id,
        folderId: destinationFolderId,
        image: image.image,
        name: image.name,
        createdOn: image.createdOn,
        modifiedOn: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        size: image.size,
        width: image.width,
        height: image.height,
      );

      await imageDatabaseHandler.updateImage(updatedImage);

      // Refresh both source and destination folders
      await imageBloc.fetchImagesByFolderId(sourceFolderId);
      await imageBloc.fetchImagesByFolderId(destinationFolderId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${image.name}" moved successfully')),
        );

        // If we're in the document viewer, go back to folder page
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show delete confirmation dialog
  Future<void> showDeleteConfirmation(
    BuildContext context,
    ImageModel image,
    String folderId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${image.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await imageDatabaseHandler.deleteImage(image.id);
              await imageBloc.fetchImagesByFolderId(folderId);

              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                // Close viewer if open (check if we can pop)
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${image.name}" deleted successfully'),
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

final documentService = DocumentService();
