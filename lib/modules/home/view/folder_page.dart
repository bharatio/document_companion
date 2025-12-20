import 'dart:async';

import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/scan/view/scan.dart';
import 'package:flutter/material.dart';

import '../models/folder_view_model.dart';

class FolderPage extends StatefulWidget {
  static const route = '/folder/folder_page';
  const FolderPage({Key? key, required this.folder}) : super(key: key);

  final FolderViewModel folder;
  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  bool _isGridView = true;
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
    super.dispose();
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
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CustomColors.primary.withOpacity(0.1),
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
                    widget.folder.folder_name,
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
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
          ),
        ],
      ),
      body: StreamBuilder<List<ImageModel>>(
        stream: imageBloc.imageStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final images = snapshot.data ?? [];
            if (images.isEmpty) {
              return _EmptyFolderState(folderName: widget.folder.folder_name);
            }
            return _ImageGridView(
              images: images,
              isGridView: _isGridView,
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

  const _ImageGridView({
    required this.images,
    required this.isGridView,
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
          return _ImageCard(image: images[index]);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _ImageListTile(image: images[index]);
        },
      );
    }
  }
}

class _ImageCard extends StatelessWidget {
  final ImageModel image;

  const _ImageCard({required this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Open image viewer
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.memory(
                  image.image,
                  fit: BoxFit.cover,
                ),
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

  const _ImageListTile({required this.image});

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
        title: Text(
          image.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          image.createdOn,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {
            // TODO: Show options menu
          },
        ),
        onTap: () {
          // TODO: Open image viewer
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
                color: CustomColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: CustomColors.primary.withOpacity(0.5),
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
                    // TODO: Navigate to scan
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Scan'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to import
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
