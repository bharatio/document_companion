import 'package:document_companion/config/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app/app_bloc.dart';
import '../../bloc/app/app_state.dart';
import '../../document_scanner_controller.dart';
import '../../utils/crop_photo_document_style.dart';

class AppBarCropPhoto extends StatelessWidget {
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;

  const AppBarCropPhoto({
    Key? key,
    required this.cropPhotoDocumentStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cropPhotoDocumentStyle.hideAppBarDefault) return const SizedBox.shrink();

    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (previous, current) =>
          current.statusCropPhoto != previous.statusCropPhoto,
      builder: (context, state) {
        final isCropping = state.statusCropPhoto == AppStatus.loading;
        
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: isCropping
                          ? null
                          : () => context
                              .read<DocumentScannerController>()
                              .changePage(AppPages.takePhoto),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Crop button
                  ElevatedButton.icon(
                    onPressed: isCropping
                        ? null
                        : () {
                            // Trigger crop
                            context
                                .read<DocumentScannerController>()
                                .cropPhoto();
                          },
                    icon: isCropping
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      isCropping ? 'Cropping...' : cropPhotoDocumentStyle.textButtonSave,
                    ),
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
      },
    );
  }
}
