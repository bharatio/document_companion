import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:flutter/material.dart';

class CreateFolderBottomModalSheet extends StatefulWidget {
  const CreateFolderBottomModalSheet({Key? key}) : super(key: key);

  @override
  State<CreateFolderBottomModalSheet> createState() =>
      _CreateFolderBottomModalSheetState();
}

class _CreateFolderBottomModalSheetState
    extends State<CreateFolderBottomModalSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await folderBloc.createFolder(_controller.text.trim());
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CustomColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create new folder',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter folder name',
                    prefixIcon: Icon(Icons.folder_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createFolder(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createFolder,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
