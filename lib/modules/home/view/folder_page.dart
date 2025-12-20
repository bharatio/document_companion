import 'dart:async';

import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/services/document_service.dart';
import 'package:document_companion/modules/home/services/folder_service.dart';
import 'package:document_companion/modules/home/view/document_viewer_page.dart';
import 'package:document_companion/modules/scan/view/scan.dart';
import 'package:flutter/material.dart';

import '../models/folder_view_model.dart';

class FolderPage extends StatefulWidget {
  static const route = '/folder/folder_page';
  const FolderPage({super.key, required this.folder});

  final FolderViewModel folder;
  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  bool _isGridView = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<ImageModel>>? _imageSubscription;
  int _imageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _updateImageCount();
  }

  @override
  void dispose() {
    _imageSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        imageBloc.clearSearch();
      }
    });
  }

  void _onSearchChanged(String query) {
    imageBloc.searchImages(query);
  }

  Future<void> _loadImages() async {
    imageBloc.fetchImagesByFolderId(widget.folder.id);
    _imageSubscription = imageBloc.imageStream.listen((images) {
      if (mounted) {
        setState(() {
          _imageCount = images.length;
        });
      }
    });
  }

  Future<void> _updateImageCount() async {
    final count = await imageBloc.getImageCount(widget.folder.id);
    if (mounted) {
      setState(() {
        _imageCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      imageBloc.clearSearch();
                      _toggleSearch();
                    },
                  ),
                ),
                onChanged: _onSearchChanged,
              )
            : Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CustomColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: CustomColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.folder.folderName,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$_imageCount ${_imageCount == 1 ? 'document' : 'documents'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
              tooltip: _isGridView ? 'List view' : 'Grid view',
            ),
            IconButton(
              onPressed: _toggleSearch,
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More options',
              onSelected: (value) {
                if (value == 'rename') {
                  folderService.showRenameDialog(context, widget.folder);
                } else if (value == 'delete') {
                  folderService.showDeleteConfirmation(context, widget.folder);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Rename Folder'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Delete Folder',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: StreamBuilder<List<ImageModel>>(
        stream: imageBloc.imageStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final images = snapshot.data ?? [];
            if (images.isEmpty) {
              return _EmptyFolderState(folderName: widget.folder.folderName);
            }
            return _ImageGridView(
              images: images,
              isGridView: _isGridView,
              folderId: widget.folder.id,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Scan.route);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Document'),
      ),
    );
  }
}

class _ImageGridView extends StatelessWidget {
  final List<ImageModel> images;
  final bool isGridView;
  final String folderId;

  const _ImageGridView({
    required this.images,
    required this.isGridView,
    required this.folderId,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _ImageCard(
            image: images[index],
            folderId: folderId,
            images: images,
            index: index,
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _ImageListTile(
            image: images[index],
            folderId: folderId,
            images: images,
            index: index,
          );
        },
      );
    }
  }
}

class _ImageCard extends StatelessWidget {
  final ImageModel image;
  final String folderId;
  final List<ImageModel> images;
  final int index;

  const _ImageCard({
    required this.image,
    required this.folderId,
    required this.images,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            DocumentViewerPage.route,
            arguments: {
              'images': images,
              'initialIndex': index,
              'folderId': folderId,
            },
          );
        },
        onLongPress: () {
          documentService.showDeleteConfirmation(context, image, folderId);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.memory(image.image, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    image.createdOn,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageListTile extends StatelessWidget {
  final ImageModel image;
  final String folderId;
  final List<ImageModel> images;
  final int index;

  const _ImageListTile({
    required this.image,
    required this.folderId,
    required this.images,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            image.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(image.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          image.createdOn,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  _DocumentOptionsSheet(image: image, folderId: folderId),
            );
          },
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            DocumentViewerPage.route,
            arguments: {
              'images': images,
              'initialIndex': index,
              'folderId': folderId,
            },
          );
        },
      ),
    );
  }
}

class _EmptyFolderState extends StatelessWidget {
  final String folderName;

  const _EmptyFolderState({required this.folderName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: CustomColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: CustomColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No documents yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by scanning a document or importing files',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, Scan.route);
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Scan'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Import functionality can be accessed from homepage
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.file_upload_rounded),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentOptionsSheet extends StatelessWidget {
  final ImageModel image;
  final String folderId;

  const _DocumentOptionsSheet({required this.image, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                documentService.showRenameDialog(context, image, folderId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_rounded),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(context);
                documentService.showMoveDialog(context, image, folderId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                documentService.shareDocument(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                documentService.showDeleteConfirmation(
                  context,
                  image,
                  folderId,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
