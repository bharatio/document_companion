import 'package:camera/camera.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app/app_bloc.dart';
import '../../bloc/app/app_state.dart';
import '../../utils/take_photo_document_style.dart';
import '../widgets/button_take_photo.dart';

class TakePhotoDocumentPage extends StatelessWidget {
  final TakePhotoDocumentStyle takePhotoDocumentStyle;

  const TakePhotoDocumentPage({
    Key? key,
    required this.takePhotoDocumentStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppBloc, AppState, AppStatus>(
      selector: (state) => state.statusCamera,
      builder: (context, state) {
        switch (state) {
          case AppStatus.initial:
            return Container();

          case AppStatus.loading:
            return takePhotoDocumentStyle.onLoading;

          case AppStatus.success:
            currentImageBloc.getCurrentImage();
            return _CameraPreview(
              takePhotoDocumentStyle: takePhotoDocumentStyle,
            );

          case AppStatus.failure:
            return Container();
        }
      },
    );
  }
}

class _CameraPreview extends StatefulWidget {
  final TakePhotoDocumentStyle takePhotoDocumentStyle;

  const _CameraPreview({
    Key? key,
    required this.takePhotoDocumentStyle,
  }) : super(key: key);

  @override
  State<_CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<_CameraPreview> {
  bool isTorchOn = false;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppBloc, AppState, CameraController?>(
      selector: (state) => state.cameraController,
      builder: (context, state) {
        if (state == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview - fills entire screen
              SizedBox.expand(
                child: CameraPreview(state),
              ),
              
              // Top bar with close button
              Positioned(
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
                        // Close button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              currentImageBloc.deleteCurrentImages();
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Flash toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              if (state.value.flashMode == FlashMode.off) {
                                await state.setFlashMode(FlashMode.torch);
                                setState(() => isTorchOn = true);
                              } else {
                                await state.setFlashMode(FlashMode.off);
                                setState(() => isTorchOn = false);
                              }
                            },
                            icon: Icon(
                              isTorchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: isTorchOn ? Colors.amber : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // * children
                    if (widget.takePhotoDocumentStyle.children != null)
                      ...widget.takePhotoDocumentStyle.children!,
                    //
                    /// Default
                    const ButtonTakePhoto(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
