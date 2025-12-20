import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app/app_bloc.dart';
import '../../bloc/app/app_event.dart';
import '../../bloc/app/app_state.dart';
import '../../bloc/crop/crop_bloc.dart';
import '../../bloc/crop/crop_event.dart';
import '../../bloc/crop/crop_state.dart';
import '../../document_scanner_controller.dart';
import '../../models/area.dart';
import '../../utils/border_crop_area_painter.dart';
import '../../utils/crop_photo_document_style.dart';
import '../../utils/dot_utils.dart';
import '../../utils/image_utils.dart';
import '../widgets/app_bar_crop_photo.dart';
import '../widgets/mask_crop.dart';

class CropPhotoDocumentPage extends StatelessWidget {
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;

  const CropPhotoDocumentPage({
    super.key,
    required this.cropPhotoDocumentStyle,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onPop(context);
        }
      },
      child: BlocSelector<AppBloc, AppState, File?>(
        selector: (state) => state.pictureInitial,
        builder: (context, state) {
          if (state == null) {
            return const Center(child: Text("NO IMAGE"));
          }

          return BlocProvider(
            create: (context) =>
                CropBloc(dotUtils: DotUtils(), imageUtils: ImageUtils())..add(
                  CropAreaInitialized(
                    areaInitial: context.read<AppBloc>().state.contourInitial,
                    defaultAreaInitial:
                        cropPhotoDocumentStyle.defaultAreaInitial,
                    image: state,
                    screenSize: screenSize,
                    positionImage: Rect.fromLTRB(
                      cropPhotoDocumentStyle.left,
                      cropPhotoDocumentStyle.top,
                      cropPhotoDocumentStyle.right,
                      cropPhotoDocumentStyle.bottom,
                    ),
                  ),
                ),
            child: _CropView(
              cropPhotoDocumentStyle: cropPhotoDocumentStyle,
              image: state,
            ),
          );
        },
      ),
    );
  }

  void _onPop(BuildContext context) {
    context.read<DocumentScannerController>().changePage(AppPages.takePhoto);
  }
}

class _CropView extends StatelessWidget {
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;
  final File image;

  const _CropView({required this.cropPhotoDocumentStyle, required this.image});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AppBloc, AppState>(
          listenWhen: (previous, current) =>
              current.statusCropPhoto != previous.statusCropPhoto,
          listener: (context, state) {
            if (state.statusCropPhoto == AppStatus.loading) {
              // Trigger crop operation
              // Use a small delay to ensure the state is properly set
              Future.microtask(() async {
                if (context.mounted) {
                  try {
                    // Verify image file exists before cropping
                    if (await image.exists()) {
                      if (!context.mounted) return;
                      context.read<CropBloc>().add(
                        CropPhotoByAreaCropped(image),
                      );
                    } else {
                      throw Exception('Image file not found');
                    }
                  } catch (e) {
                    // Show error if file doesn't exist
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      // Reset crop status
                      context.read<AppBloc>().add(
                        AppPageChanged(AppPages.cropPhoto),
                      );
                    }
                  }
                }
              });
            }
          },
        ),
        BlocListener<CropBloc, CropState>(
          listenWhen: (previous, current) =>
              current.imageCropped != previous.imageCropped,
          listener: (context, state) {
            if (state.imageCropped != null && state.areaParsed != null) {
              // Load cropped photo and navigate to edit page
              context.read<AppBloc>().add(
                AppLoadCroppedPhoto(
                  image: state.imageCropped!,
                  area: state.areaParsed!,
                ),
              );
            }
          },
        ),
        // Separate listener for timeout handling
        BlocListener<AppBloc, AppState>(
          listenWhen: (previous, current) =>
              current.statusCropPhoto == AppStatus.loading &&
              previous.statusCropPhoto != AppStatus.loading,
          listener: (context, state) {
            // Set a timeout to detect if cropping is taking too long
            Future.delayed(const Duration(seconds: 5), () {
              if (context.mounted) {
                final currentState = context.read<AppBloc>().state;
                final cropState = context.read<CropBloc>().state;

                // If still loading and no cropped image, show error
                if (currentState.statusCropPhoto == AppStatus.loading &&
                    cropState.imageCropped == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cropping is taking too long. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  // Reset crop status to allow retry
                  context.read<AppBloc>().add(
                    AppPageChanged(AppPages.cropPhoto),
                  );
                }
              }
            });
          },
        ),
      ],
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image and crop area
            Positioned(
              top: cropPhotoDocumentStyle.top,
              bottom: cropPhotoDocumentStyle.bottom,
              left: cropPhotoDocumentStyle.left,
              right: cropPhotoDocumentStyle.right,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // * Photo
                  Positioned.fill(child: Image.file(image, fit: BoxFit.fill)),

                  // * Mask
                  BlocSelector<CropBloc, CropState, Area>(
                    selector: (state) => state.area,
                    builder: (context, state) {
                      return MaskCrop(
                        area: state,
                        cropPhotoDocumentStyle: cropPhotoDocumentStyle,
                      );
                    },
                  ),

                  // * Border Mask
                  BlocSelector<CropBloc, CropState, Area>(
                    selector: (state) => state.area,
                    builder: (context, state) {
                      return CustomPaint(
                        painter: BorderCropAreaPainter(area: state),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),

                  // * Dot - All
                  BlocSelector<CropBloc, CropState, Area>(
                    selector: (state) => state.area,
                    builder: (context, state) {
                      return GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                            CropDotMoved(
                              deltaX: details.delta.dx,
                              deltaY: details.delta.dy,
                              dotPosition: DotPosition.all,
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: state.topLeft.x + state.topRight.x,
                          height: state.topLeft.y + state.topRight.y,
                        ),
                      );
                    },
                  ),

                  // * Dot - Top Left
                  BlocSelector<CropBloc, CropState, Point>(
                    selector: (state) => state.area.topLeft,
                    builder: (context, state) {
                      return Positioned(
                        left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                        top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            context.read<CropBloc>().add(
                              CropDotMoved(
                                deltaX: details.delta.dx,
                                deltaY: details.delta.dy,
                                dotPosition: DotPosition.topLeft,
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: cropPhotoDocumentStyle.dotSize,
                            height: cropPhotoDocumentStyle.dotSize,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  cropPhotoDocumentStyle.dotRadius,
                                ),
                                child: Container(
                                  width:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // * Dot - Top Right
                  BlocSelector<CropBloc, CropState, Point>(
                    selector: (state) => state.area.topRight,
                    builder: (context, state) {
                      return Positioned(
                        left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                        top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            context.read<CropBloc>().add(
                              CropDotMoved(
                                deltaX: details.delta.dx,
                                deltaY: details.delta.dy,
                                dotPosition: DotPosition.topRight,
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: cropPhotoDocumentStyle.dotSize,
                            height: cropPhotoDocumentStyle.dotSize,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  cropPhotoDocumentStyle.dotRadius,
                                ),
                                child: Container(
                                  width:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // * Dot - Bottom Left
                  BlocSelector<CropBloc, CropState, Point>(
                    selector: (state) => state.area.bottomLeft,
                    builder: (context, state) {
                      return Positioned(
                        left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                        top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            context.read<CropBloc>().add(
                              CropDotMoved(
                                deltaX: details.delta.dx,
                                deltaY: details.delta.dy,
                                dotPosition: DotPosition.bottomLeft,
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: cropPhotoDocumentStyle.dotSize,
                            height: cropPhotoDocumentStyle.dotSize,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  cropPhotoDocumentStyle.dotRadius,
                                ),
                                child: Container(
                                  width:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // * Dot - Bottom Right
                  BlocSelector<CropBloc, CropState, Point>(
                    selector: (state) => state.area.bottomRight,
                    builder: (context, state) {
                      return Positioned(
                        left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                        top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            context.read<CropBloc>().add(
                              CropDotMoved(
                                deltaX: details.delta.dx,
                                deltaY: details.delta.dy,
                                dotPosition: DotPosition.bottomRight,
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: cropPhotoDocumentStyle.dotSize,
                            height: cropPhotoDocumentStyle.dotSize,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  cropPhotoDocumentStyle.dotRadius,
                                ),
                                child: Container(
                                  width:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // * Default App Bar - Must be on top
            AppBarCropPhoto(cropPhotoDocumentStyle: cropPhotoDocumentStyle),

            // * children
            if (cropPhotoDocumentStyle.children != null)
              ...cropPhotoDocumentStyle.children!,
          ],
        ),
      ),
    );
  }
}
