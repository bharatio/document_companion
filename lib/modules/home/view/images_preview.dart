import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/local_database/models/current_image.dart';
import 'package:document_companion/modules/home/bloc/current_image_bloc.dart';
import 'package:document_companion/modules/home/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bloc/save_image_bloc.dart';

class ImagesPreview extends StatefulWidget {
  static const route = '/images_preview';
  const ImagesPreview({Key? key}) : super(key: key);

  @override
  State<ImagesPreview> createState() => _ImagesPreviewState();
}

class _ImagesPreviewState extends State<ImagesPreview> {
  PageController _pageController = PageController();
  bool _isCreatingPdf = false;

  @override
  void initState() {
    super.initState();
    currentImageBloc.getCurrentImage();
  }

  Future<void> _createPdf(List<CurrentImage> images) async {
    if (images.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images to convert to PDF')),
        );
      }
      return;
    }

    setState(() => _isCreatingPdf = true);

    try {
      final pdfBytes = await pdfService.createPdfFromImages(images);
      final fileName = 'Document_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      
      if (mounted) {
        await pdfService.showPdfOptions(context, pdfBytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<List<CurrentImage>>(
          stream: currentImageBloc.currentImageStream,
          builder: (context, AsyncSnapshot<List<CurrentImage>> snapshot) {
            final list = snapshot.data ?? [];
            
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 64,
                      color: CustomColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No images',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    itemCount: list.length,
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final imageData = list.elementAt(index);
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Image.memory(
                            imageData.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _pageController.hasClients &&
                                (_pageController.page?.toInt() ?? 0) > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: Colors.white,
                      ),
                      Builder(
                        builder: (context) {
                          final currentPage = _pageController.hasClients
                              ? (_pageController.page?.toInt() ?? 0)
                              : 0;
                          return Text(
                            '${currentPage + 1} / ${list.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: _pageController.hasClients &&
                                (_pageController.page?.toInt() ?? 0) < list.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: CustomColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            saveImageBloc.openSaveImageSheet();
                          },
                          label: const Text('Save'),
                          icon: const Icon(Icons.save_rounded),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isCreatingPdf
                              ? null
                              : () => _createPdf(list),
                          label: _isCreatingPdf
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
                              : const Text('PDF'),
                          icon: _isCreatingPdf
                              ? const SizedBox.shrink()
                              : const Icon(Icons.picture_as_pdf),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
