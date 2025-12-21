import 'package:document_companion/local_database/models/tag_model.dart';
import 'package:document_companion/modules/home/bloc/tag_bloc.dart';
import 'package:flutter/material.dart';

class TagService {
  static const List<String> defaultColors = [
    '#6366F1', // Indigo
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#F97316', // Orange
  ];

  Future<void> showTagManagementDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const _TagManagementDialog(),
    );
  }

  Future<void> showAddTagToFolderDialog(
    BuildContext context,
    String folderId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => _AddTagDialog(folderId: folderId, isFolder: true),
    );
  }

  Future<void> showAddTagToDocumentDialog(
    BuildContext context,
    String documentId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) =>
          _AddTagDialog(documentId: documentId, isFolder: false),
    );
  }
}

class _TagManagementDialog extends StatefulWidget {
  const _TagManagementDialog();

  @override
  State<_TagManagementDialog> createState() => _TagManagementDialogState();
}

class _TagManagementDialogState extends State<_TagManagementDialog> {
  @override
  void initState() {
    super.initState();
    tagBloc.fetchTags();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<TagModel>>(
          stream: tagBloc.tagsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final tags = snapshot.data ?? [];
              if (tags.isEmpty) {
                return const Center(
                  child: Text('No tags yet. Create your first tag!'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _parseColor(tag.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(tag.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () async {
                        await tagBloc.deleteTag(tag.id);
                      },
                    ),
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _showCreateTagDialog(context);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Tag'),
        ),
      ],
    );
  }

  Future<void> _showCreateTagDialog(BuildContext context) async {
    final nameController = TextEditingController();
    String selectedColor = TagService.defaultColors[0];

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tag Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TagService.defaultColors.map((color) {
                  final isSelected = selectedColor == color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  await tagBloc.createTag(
                    nameController.text.trim(),
                    selectedColor,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

class _AddTagDialog extends StatefulWidget {
  final String? folderId;
  final String? documentId;
  final bool isFolder;

  const _AddTagDialog({this.folderId, this.documentId, required this.isFolder});

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    tagBloc.fetchTags();
    _loadExistingTags();
  }

  Future<void> _loadExistingTags() async {
    List<TagModel> existingTags;
    if (widget.isFolder && widget.folderId != null) {
      existingTags = await tagBloc.getTagsByFolderId(widget.folderId!);
    } else if (!widget.isFolder && widget.documentId != null) {
      existingTags = await tagBloc.getTagsByDocumentId(widget.documentId!);
    } else {
      return;
    }
    setState(() {
      _selectedTagIds.addAll(existingTags.map((tag) => tag.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.isFolder ? 'Folder' : 'Document'} Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<TagModel>>(
          stream: tagBloc.tagsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final tags = snapshot.data ?? [];
              if (tags.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No tags available. Create tags first.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        TagService().showTagManagementDialog(context);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Tag'),
                    ),
                  ],
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected = _selectedTagIds.contains(tag.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedTagIds.add(tag.id);
                        } else {
                          _selectedTagIds.remove(tag.id);
                        }
                      });
                    },
                    title: Text(tag.name),
                    secondary: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _parseColor(tag.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            TagService().showTagManagementDialog(context);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Manage Tags'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (widget.isFolder && widget.folderId != null) {
              await _updateFolderTags(widget.folderId!);
            } else if (!widget.isFolder && widget.documentId != null) {
              await _updateDocumentTags(widget.documentId!);
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _updateFolderTags(String folderId) async {
    // Get current tags
    final currentTags = await tagBloc.getTagsByFolderId(folderId);
    final currentTagIds = currentTags.map((tag) => tag.id).toSet();

    // Add new tags
    for (var tagId in _selectedTagIds) {
      if (!currentTagIds.contains(tagId)) {
        await tagBloc.addTagToFolder(folderId, tagId);
      }
    }

    // Remove unselected tags
    for (var tagId in currentTagIds) {
      if (!_selectedTagIds.contains(tagId)) {
        await tagBloc.removeTagFromFolder(folderId, tagId);
      }
    }
  }

  Future<void> _updateDocumentTags(String documentId) async {
    // Get current tags
    final currentTags = await tagBloc.getTagsByDocumentId(documentId);
    final currentTagIds = currentTags.map((tag) => tag.id).toSet();

    // Add new tags
    for (var tagId in _selectedTagIds) {
      if (!currentTagIds.contains(tagId)) {
        await tagBloc.addTagToDocument(documentId, tagId);
      }
    }

    // Remove unselected tags
    for (var tagId in currentTagIds) {
      if (!_selectedTagIds.contains(tagId)) {
        await tagBloc.removeTagFromDocument(documentId, tagId);
      }
    }
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

final tagService = TagService();
