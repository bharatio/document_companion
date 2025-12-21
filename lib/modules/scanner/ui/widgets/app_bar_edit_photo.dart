import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/custom_colors.dart';
import '../../bloc/app/app_state.dart';
import '../../document_scanner_controller.dart';
import '../../utils/edit_photo_document_style.dart';

class AppBarEditPhoto extends StatelessWidget {
  final EditPhotoDocumentStyle editPhotoDocumentStyle;

  const AppBarEditPhoto({super.key, required this.editPhotoDocumentStyle});

  @override
  Widget build(BuildContext context) {
    if (editPhotoDocumentStyle.hideAppBarDefault) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => context
                      .read<DocumentScannerController>()
                      .changePage(AppPages.cropPhoto),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),

              // Save button
              ElevatedButton.icon(
                onPressed: () => context
                    .read<DocumentScannerController>()
                    .savePhotoDocument(),
                icon: const Icon(Icons.check_rounded),
                label: Text(editPhotoDocumentStyle.textButtonSave),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
