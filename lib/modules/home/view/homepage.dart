import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/models/folder_view_model.dart';
import 'package:document_companion/modules/home/view/create_bottom_modal_sheet.dart';
import 'package:document_companion/modules/home/view/images_preview.dart';
import 'package:document_companion/utils/constants/constants.dart';
import 'package:flutter/material.dart';

import 'folder_page.dart';

class Homepage extends StatefulWidget {
  static const String route = '/homepage';
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    folderBloc.fetchFolders();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        folderBloc.clearSearch();
      }
    });
  }

  void _onSearchChanged(String query) {
    folderBloc.searchFolders(query);
  }

  void _handleServiceTap(BuildContext context, int index) {
    switch (index) {
      case 0: // PDF to Word
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF to Word conversion coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 1: // Merge PDF
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merge PDF feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 2: // File Compress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File compression feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 3: // Image to PDF
        _handleImageToPdf(context);
        break;
      case 4: // Import PDF
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import PDF feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  Future<void> _handleImageToPdf(BuildContext context) async {
    // Check if there are any images to convert
    final images = await currentImageBloc.getCurrentImagesList();
    if (!context.mounted) return;

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images found. Please scan or import images first.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    // Navigate to images preview where PDF conversion is available
    if (context.mounted) {
      Navigator.pushNamed(context, ImagesPreview.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search folders...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      folderBloc.clearSearch();
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Companion',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Your documents',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              onPressed: _toggleSearch,
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More options',
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CreateBottomModalSheet(),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Services Section
            SizedBox(
              height: 100,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: Constant.availableServices.length,
                itemBuilder: (context, index) => _ServiceCard(
                  icon: Constant.availableServices[index].operationIcon,
                  title: Constant.availableServices[index].title,
                  onTap: () => _handleServiceTap(context, index),
                ),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
              ),
            ),
            // Folders Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CustomColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Folders',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Row(
                            children: [
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.sort_rounded),
                                tooltip: 'Sort',
                                iconSize: 20,
                                onSelected: (value) {
                                  final parts = value.split('_');
                                  final sortBy = parts[0];
                                  final ascending = parts[1] == 'asc';
                                  folderBloc.sortFolders(
                                    sortBy,
                                    ascending: ascending,
                                  );
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'name_asc',
                                    child: Text('Name (A-Z)'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'name_desc',
                                    child: Text('Name (Z-A)'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'created_desc',
                                    child: Text('Newest First'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'created_asc',
                                    child: Text('Oldest First'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'modified_desc',
                                    child: Text('Recently Modified'),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  // Filter functionality can be added later
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Filter feature coming soon',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.filter_list_rounded),
                                tooltip: 'Filter',
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<FolderViewModel>>(
                        stream: folderBloc.folderList,
                        builder:
                            (
                              context,
                              AsyncSnapshot<List<FolderViewModel>> snapshot,
                            ) {
                              if (snapshot.hasData) {
                                final folders = snapshot.data;
                                if (folders?.isEmpty ?? true) {
                                  return _EmptyState();
                                }
                                return GridView.builder(
                                  padding: const EdgeInsets.all(20),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.85,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: folders?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    return _FolderCard(
                                      folder: folders![index],
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          FolderPage.route,
                                          arguments: folders[index],
                                        );
                                      },
                                    );
                                  },
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: CustomColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CustomColors.border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CustomColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: CustomColors.primary, size: 22),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).textTheme.bodySmall?.color ??
                        CustomColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FolderViewModel folder;
  final VoidCallback onTap;

  const _FolderCard({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CustomColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: CustomColors.primary,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                folder.folder_name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FutureBuilder<int>(
                future: imageBloc.getImageCount(folder.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Text(
                    '$count ${count == 1 ? 'document' : 'documents'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CustomColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: CustomColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No folders yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first folder to organize your documents',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
