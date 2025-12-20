import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';

import 'package:document_companion/local_database/handler/image_database_handler.dart';
import 'package:document_companion/local_database/models/current_image.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/models/folder_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:uuid/uuid.dart';

class PdfService {
  /// Creates a PDF from a list of images
  Future<Uint8List> createPdfFromImages(List<CurrentImage> images) async {
    final pdf = pw.Document();

    for (var currentImage in images) {
      final image = pw.MemoryImage(currentImage.image);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Creates a PDF from Uint8List images
  Future<Uint8List> createPdfFromImageBytes(List<Uint8List> imageBytes) async {
    final pdf = pw.Document();

    for (var imageData in imageBytes) {
      final image = pw.MemoryImage(imageData);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Saves PDF to device storage
  Future<File?> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  /// Shares PDF using system share sheet
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      final file = await savePdfToDevice(pdfBytes, fileName);
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: fileName,
        );
      }
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }

  /// Prints PDF
  Future<void> printPdf(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      print('Error printing PDF: $e');
    }
  }

  /// Shows PDF preview and options (save, share, print)
  Future<void> showPdfOptions(
    BuildContext context,
    Uint8List pdfBytes,
    String fileName,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Created'),
        content: Text('$fileName.pdf has been created successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sharePdf(pdfBytes, fileName);
            },
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              printPdf(pdfBytes, fileName);
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  /// Merges multiple PDFs into a single PDF
  /// Converts PDF pages to images and merges them (lossy but reliable)
  Future<Uint8List?> mergePdfsFromFiles(List<File> pdfFiles) async {
    try {
      if (pdfFiles.isEmpty) {
        return null;
      }

      final mergedPdf = pw.Document();

      for (var pdfFile in pdfFiles) {
        try {
          final pdfBytes = await pdfFile.readAsBytes();
          
          // Render PDF pages as images using printing package
          // Printing.raster returns a Stream<PdfRaster>
          await for (var img in Printing.raster(pdfBytes, dpi: 150)) {
            try {
              final imgBytes = await img.toPng();
              final pdfImage = pw.MemoryImage(imgBytes);
              
              mergedPdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context context) {
                    return pw.Center(
                      child: pw.Image(
                        pdfImage,
                        fit: pw.BoxFit.contain,
                      ),
                    );
                  },
                ),
              );
            } catch (e) {
              print('Error converting page to image: $e');
              // Continue with next page
            }
          }
        } catch (e) {
          print('Error processing PDF ${pdfFile.path}: $e');
          // Continue with next PDF even if one fails
        }
      }

      return mergedPdf.save();
    } catch (e) {
      print('Error merging PDFs: $e');
      return null;
    }
  }

  /// Merges PDFs from Uint8List (creates temporary files first)
  Future<Uint8List?> mergePdfs(List<Uint8List> pdfBytesList) async {
    try {
      if (pdfBytesList.isEmpty) {
        return null;
      }

      // Create temporary files from PDF bytes
      final directory = await getTemporaryDirectory();
      final tempFiles = <File>[];
      
      for (var i = 0; i < pdfBytesList.length; i++) {
        final tempFile = File('${directory.path}/temp_pdf_${DateTime.now().millisecondsSinceEpoch}_$i.pdf');
        await tempFile.writeAsBytes(pdfBytesList[i]);
        tempFiles.add(tempFile);
      }

      // Merge the temporary files
      final result = await mergePdfsFromFiles(tempFiles);
      
      // Clean up temporary files
      for (var file in tempFiles) {
        try {
          await file.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
      
      return result;
    } catch (e) {
      print('Error merging PDFs from bytes: $e');
      return null;
    }
  }

  /// Shows PDF selection dialog and merges selected PDFs
  Future<void> showMergePdfDialog(BuildContext context) async {
    try {
      // Show file picker to select multiple PDFs
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No PDFs selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (result.files.length < 2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least 2 PDFs to merge'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Convert PlatformFile to File objects
      final pdfFiles = <File>[];
      for (var platformFile in result.files) {
        if (platformFile.path != null) {
          pdfFiles.add(File(platformFile.path!));
        } else if (platformFile.bytes != null) {
          // Handle web platform where path might be null
          final directory = await getTemporaryDirectory();
          final tempFile = File('${directory.path}/${platformFile.name}');
          await tempFile.writeAsBytes(platformFile.bytes!);
          pdfFiles.add(tempFile);
        }
      }

      // Merge PDFs
      final mergedBytes = await mergePdfsFromFiles(pdfFiles);

      if (!context.mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      if (mergedBytes != null) {
        // Show success dialog with options
        final fileName = 'merged_${DateTime.now().millisecondsSinceEpoch}';
        await showPdfOptions(context, mergedBytes, fileName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error merging PDFs. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Imports PDF file and converts pages to images, saving them to a folder
  Future<void> importPdfToFolder(
    BuildContext context,
    File pdfFile,
    String folderId,
    String pdfFileName,
  ) async {
    try {
      final pdfBytes = await pdfFile.readAsBytes();
      final uuid = Uuid();
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      int pageNumber = 1;

      // Convert PDF pages to images and save to folder
      await for (var img in Printing.raster(pdfBytes, dpi: 150)) {
        try {
          final imgBytes = await img.toPng();
          
          // Create image name based on PDF filename and page number
          final imageName = '${pdfFileName}_Page_$pageNumber';
          
          final imageModel = ImageModel(
            id: uuid.v4(),
            folderId: folderId,
            image: imgBytes,
            name: imageName,
            createdOn: timestamp,
            modifiedOn: timestamp,
            size: imgBytes.lengthInBytes,
            width: img.width,
            height: img.height,
          );
          
          await imageDatabaseHandler.insertImage(imageModel);
          pageNumber++;
        } catch (e) {
          print('Error converting PDF page $pageNumber to image: $e');
          // Continue with next page
        }
      }

      // Refresh folder images
      imageBloc.fetchImagesByFolderId(folderId);
    } catch (e) {
      print('Error importing PDF: $e');
      rethrow;
    }
  }

  /// Shows PDF import dialog with folder selection
  Future<void> showImportPdfDialog(BuildContext context) async {
    try {
      // Show file picker to select PDF
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No PDF selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final platformFile = result.files.first;
      File? pdfFile;
      
      if (platformFile.path != null) {
        pdfFile = File(platformFile.path!);
      } else if (platformFile.bytes != null) {
        // Handle web platform where path might be null
        final directory = await getTemporaryDirectory();
        pdfFile = File('${directory.path}/${platformFile.name}');
        await pdfFile.writeAsBytes(platformFile.bytes!);
      }

      if (pdfFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error reading PDF file'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Get PDF filename without extension
      final pdfFileName = platformFile.name.replaceAll('.pdf', '');

      if (!context.mounted) return;

      // Show folder selection dialog
      await _showFolderSelectionDialog(
        context,
        pdfFile,
        pdfFileName,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Shows folder selection dialog for PDF import
  Future<void> _showFolderSelectionDialog(
    BuildContext context,
    File pdfFile,
    String pdfFileName,
  ) async {
    // Fetch folders first
    await folderBloc.fetchFolders();

    await showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<FolderViewModel>>(
        stream: folderBloc.folderList,
        builder: (context, snapshot) {
          final folders = snapshot.data ?? [];

          if (folders.isEmpty) {
            return AlertDialog(
              title: const Text('No Folders'),
              content: const Text(
                'Please create a folder first before importing PDFs.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          return StatefulBuilder(
            builder: (context, setState) {
              String? selectedFolderId;

              return AlertDialog(
                title: const Text('Select Folder'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Import "$pdfFileName.pdf" to:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];

                            return RadioListTile<String>(
                              title: Text(folder.folder_name),
                              value: folder.id,
                              groupValue: selectedFolderId,
                              onChanged: (value) {
                                setState(() {
                                  selectedFolderId = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: selectedFolderId == null
                        ? null
                        : () async {
                            Navigator.pop(context); // Close dialog

                            if (!context.mounted) return;

                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              await importPdfToFolder(
                                context,
                                pdfFile,
                                selectedFolderId!,
                                pdfFileName,
                              );

                              if (!context.mounted) return;

                              // Close loading dialog
                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'PDF imported successfully to folder',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              // Close loading dialog
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error importing PDF: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                    child: const Text('Import'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Splits a PDF into multiple PDFs based on page ranges
  /// Returns list of split PDF bytes
  Future<List<Uint8List>> splitPdfByRanges(
    Uint8List pdfBytes,
    List<PageRange> pageRanges,
  ) async {
    final splitPdfs = <Uint8List>[];

    for (var range in pageRanges) {
      final splitPdf = pw.Document();
      int pageIndex = 0;

      await for (var img in Printing.raster(pdfBytes, dpi: 150)) {
        // Check if this page is in the range
        if (pageIndex >= range.start && pageIndex <= range.end) {
          try {
            final imgBytes = await img.toPng();
            final pdfImage = pw.MemoryImage(imgBytes);

            splitPdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context context) {
                  return pw.Center(
                    child: pw.Image(
                      pdfImage,
                      fit: pw.BoxFit.contain,
                    ),
                  );
                },
              ),
            );
          } catch (e) {
            print('Error converting page ${pageIndex + 1} to image: $e');
          }
        }
        pageIndex++;
      }

      splitPdfs.add(await splitPdf.save());
    }

    return splitPdfs;
  }

  /// Gets the page count of a PDF
  Future<int> getPdfPageCount(Uint8List pdfBytes) async {
    int count = 0;
    await for (var _ in Printing.raster(pdfBytes, dpi: 72)) {
      count++;
    }
    return count;
  }

  /// Shows PDF split dialog with page range selection
  Future<void> showSplitPdfDialog(BuildContext context) async {
    try {
      // Show file picker to select PDF
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No PDF selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final platformFile = result.files.first;
      File? pdfFile;

      if (platformFile.path != null) {
        pdfFile = File(platformFile.path!);
      } else if (platformFile.bytes != null) {
        final directory = await getTemporaryDirectory();
        pdfFile = File('${directory.path}/${platformFile.name}');
        await pdfFile.writeAsBytes(platformFile.bytes!);
      }

      if (pdfFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error reading PDF file'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final pdfBytes = await pdfFile.readAsBytes();
      final pdfFileName = platformFile.name.replaceAll('.pdf', '');

      if (!context.mounted) return;

      // Get page count
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pageCount = await getPdfPageCount(pdfBytes);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (pageCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read PDF pages'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Show page range selection dialog
      await _showPageRangeSelectionDialog(
        context,
        pdfBytes,
        pdfFileName,
        pageCount,
      );
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Shows page range selection dialog
  Future<void> _showPageRangeSelectionDialog(
    BuildContext context,
    Uint8List pdfBytes,
    String pdfFileName,
    int pageCount,
  ) async {
    final pageRanges = <PageRange>[];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Split PDF ($pageCount pages)'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select pages to extract:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _PageRangeSelector(
                    pageCount: pageCount,
                    onRangesChanged: (ranges) {
                      setState(() {
                        pageRanges.clear();
                        pageRanges.addAll(ranges);
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: pageRanges.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context); // Close dialog

                        if (!context.mounted) return;

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          final splitPdfs = await splitPdfByRanges(
                            pdfBytes,
                            pageRanges,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading

                          // Show success and options
                          await _showSplitPdfOptions(
                            context,
                            splitPdfs,
                            pdfFileName,
                            pageRanges,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error splitting PDF: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                child: const Text('Split'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows options for split PDFs (save/share)
  Future<void> _showSplitPdfOptions(
    BuildContext context,
    List<Uint8List> splitPdfs,
    String pdfFileName,
    List<PageRange> pageRanges,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Split Successfully'),
        content: Text(
          'Created ${splitPdfs.length} PDF file(s). What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Share all split PDFs
              for (var i = 0; i < splitPdfs.length; i++) {
                final range = pageRanges[i];
                final fileName = '${pdfFileName}_pages_${range.start + 1}-${range.end + 1}';
                sharePdf(splitPdfs[i], fileName);
              }
            },
            child: const Text('Share All'),
          ),
        ],
      ),
    );
  }

  /// Compresses a PDF by re-rendering at lower DPI
  /// quality: 'low' (72 DPI), 'medium' (100 DPI), 'high' (120 DPI)
  Future<Uint8List?> compressPdf(
    Uint8List pdfBytes,
    CompressionQuality quality,
  ) async {
    try {
      final compressedPdf = pw.Document();
      final dpi = quality.dpi.toDouble();

      // Re-render PDF pages at lower DPI
      await for (var img in Printing.raster(pdfBytes, dpi: dpi)) {
        try {
          final imgBytes = await img.toPng();
          final pdfImage = pw.MemoryImage(imgBytes);

          compressedPdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(
                    pdfImage,
                    fit: pw.BoxFit.contain,
                  ),
                );
              },
            ),
          );
        } catch (e) {
          print('Error compressing page: $e');
        }
      }

      return await compressedPdf.save();
    } catch (e) {
      print('Error compressing PDF: $e');
      return null;
    }
  }

  /// Formats file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Shows PDF compression dialog with quality selection
  Future<void> showCompressPdfDialog(BuildContext context) async {
    try {
      // Show file picker to select PDF
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No PDF selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final platformFile = result.files.first;
      File? pdfFile;

      if (platformFile.path != null) {
        pdfFile = File(platformFile.path!);
      } else if (platformFile.bytes != null) {
        final directory = await getTemporaryDirectory();
        pdfFile = File('${directory.path}/${platformFile.name}');
        await pdfFile.writeAsBytes(platformFile.bytes!);
      }

      if (pdfFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error reading PDF file'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final pdfBytes = await pdfFile.readAsBytes();
      final originalSize = pdfBytes.length;
      final pdfFileName = platformFile.name.replaceAll('.pdf', '');

      if (!context.mounted) return;

      // Show compression quality selection dialog
      await _showCompressionQualityDialog(
        context,
        pdfBytes,
        pdfFileName,
        originalSize,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Shows compression quality selection dialog
  Future<void> _showCompressionQualityDialog(
    BuildContext context,
    Uint8List pdfBytes,
    String pdfFileName,
    int originalSize,
  ) async {
    CompressionQuality? selectedQuality;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Compress PDF'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Original size: ${_formatFileSize(originalSize)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select compression quality:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<CompressionQuality>(
                    title: const Text('Low (Smaller file)'),
                    subtitle: Text('~${_formatFileSize((originalSize * 0.3).round())} estimated'),
                    value: CompressionQuality.low,
                    groupValue: selectedQuality,
                    onChanged: (value) {
                      setState(() {
                        selectedQuality = value;
                      });
                    },
                  ),
                  RadioListTile<CompressionQuality>(
                    title: const Text('Medium (Balanced)'),
                    subtitle: Text('~${_formatFileSize((originalSize * 0.5).round())} estimated'),
                    value: CompressionQuality.medium,
                    groupValue: selectedQuality,
                    onChanged: (value) {
                      setState(() {
                        selectedQuality = value;
                      });
                    },
                  ),
                  RadioListTile<CompressionQuality>(
                    title: const Text('High (Better quality)'),
                    subtitle: Text('~${_formatFileSize((originalSize * 0.7).round())} estimated'),
                    value: CompressionQuality.high,
                    groupValue: selectedQuality,
                    onChanged: (value) {
                      setState(() {
                        selectedQuality = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedQuality == null
                    ? null
                    : () async {
                        Navigator.pop(context); // Close dialog

                        if (!context.mounted) return;

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          final compressedBytes = await compressPdf(
                            pdfBytes,
                            selectedQuality!,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading

                          if (compressedBytes != null) {
                            final compressedSize = compressedBytes.length;
                            final reduction = ((originalSize - compressedSize) / originalSize * 100);

                            // Show success with size comparison
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('PDF Compressed'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Original: ${_formatFileSize(originalSize)}'),
                                    Text('Compressed: ${_formatFileSize(compressedSize)}'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reduced by ${reduction.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: reduction > 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final fileName = '${pdfFileName}_compressed';
                                      // Use pdfService instance to call showPdfOptions
                                      final service = PdfService();
                                      await service.showPdfOptions(context, compressedBytes, fileName);
                                    },
                                    child: const Text('Save/Share'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error compressing PDF'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                child: const Text('Compress'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Extracts text from PDF using Syncfusion
  Future<String> extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      final document = sf.PdfDocument(inputBytes: pdfBytes);
      final textExtractor = sf.PdfTextExtractor(document);
      final extractedText = textExtractor.extractText();
      document.dispose();
      return extractedText;
    } catch (e) {
      print('Error extracting text from PDF: $e');
      return '';
    }
  }

  /// Creates a basic Word document (.docx) from text
  /// Note: This creates a simple .docx file structure
  Future<Uint8List?> createWordDocumentFromText(String text) async {
    try {
      // Create a simple .docx file structure
      // .docx is essentially a ZIP file containing XML files
      final archive = Archive();

      // Create [Content_Types].xml
      final contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

      // Create word/document.xml with the text content
      // Escape XML special characters
      final escapedText = text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');

      final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
<w:p>
<w:r>
<w:t>$escapedText</w:t>
</w:r>
</w:p>
</w:body>
</w:document>''';

      // Create _rels/.rels
      final rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

      // Create word/_rels/document.xml.rels
      final wordRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';

      // Add files to archive
      archive.addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, utf8.encode(contentTypes)));
      archive.addFile(ArchiveFile('word/document.xml', documentXml.length, utf8.encode(documentXml)));
      archive.addFile(ArchiveFile('_rels/.rels', rels.length, utf8.encode(rels)));
      archive.addFile(ArchiveFile('word/_rels/document.xml.rels', wordRels.length, utf8.encode(wordRels)));

      // Create ZIP file
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      
      return Uint8List.fromList(zipData);
    } catch (e) {
      print('Error creating Word document: $e');
      return null;
    }
  }

  /// Converts PDF to Word document
  Future<Uint8List?> convertPdfToWord(Uint8List pdfBytes) async {
    try {
      // Extract text from PDF
      final extractedText = await extractTextFromPdf(pdfBytes);
      
      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from PDF. The PDF might be image-based or scanned.');
      }

      // Create Word document from extracted text
      final wordBytes = await createWordDocumentFromText(extractedText);
      return wordBytes;
    } catch (e) {
      print('Error converting PDF to Word: $e');
      rethrow;
    }
  }

  /// Shows PDF to Word conversion dialog
  Future<void> showPdfToWordDialog(BuildContext context) async {
    try {
      // Show file picker to select PDF
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No PDF selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final platformFile = result.files.first;
      File? pdfFile;

      if (platformFile.path != null) {
        pdfFile = File(platformFile.path!);
      } else if (platformFile.bytes != null) {
        final directory = await getTemporaryDirectory();
        pdfFile = File('${directory.path}/${platformFile.name}');
        await pdfFile.writeAsBytes(platformFile.bytes!);
      }

      if (pdfFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error reading PDF file'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final pdfBytes = await pdfFile.readAsBytes();
      final pdfFileName = platformFile.name.replaceAll('.pdf', '');

      if (!context.mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Convert PDF to Word
        final wordBytes = await convertPdfToWord(pdfBytes);

        if (!context.mounted) return;
        Navigator.pop(context); // Close loading

        if (wordBytes != null) {
          // Save Word document
          final directory = await getApplicationDocumentsDirectory();
          final wordFile = File('${directory.path}/${pdfFileName}.docx');
          await wordFile.writeAsBytes(wordBytes);

          // Show success dialog
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('PDF Converted to Word'),
              content: Text('Word document saved as "${pdfFileName}.docx"'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Share the Word document
                    await Share.shareXFiles(
                      [XFile(wordFile.path)],
                      subject: pdfFileName,
                    );
                  },
                  child: const Text('Share'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error converting PDF to Word'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Represents a page range for PDF splitting
class PageRange {
  final int start;
  final int end;

  PageRange(this.start, this.end);

  @override
  String toString() => 'Pages ${start + 1}-${end + 1}';
}

/// Widget for selecting page ranges
class _PageRangeSelector extends StatefulWidget {
  final int pageCount;
  final Function(List<PageRange>) onRangesChanged;

  const _PageRangeSelector({
    required this.pageCount,
    required this.onRangesChanged,
  });

  @override
  State<_PageRangeSelector> createState() => _PageRangeSelectorState();
}

class _PageRangeSelectorState extends State<_PageRangeSelector> {
  final List<PageRange> _ranges = [];
  int? _startPage;
  int? _endPage;

  @override
  void initState() {
    super.initState();
    // Default: select all pages as one range
    _ranges.add(PageRange(0, widget.pageCount - 1));
    widget.onRangesChanged(_ranges);
  }

  void _addRange() {
    if (_startPage != null && _endPage != null) {
      if (_startPage! <= _endPage! &&
          _startPage! >= 0 &&
          _endPage! < widget.pageCount) {
        setState(() {
          _ranges.add(PageRange(_startPage!, _endPage!));
          _ranges.sort((a, b) => a.start.compareTo(b.start));
          widget.onRangesChanged(_ranges);
          _startPage = null;
          _endPage = null;
        });
      }
    }
  }

  void _removeRange(int index) {
    setState(() {
      _ranges.removeAt(index);
      widget.onRangesChanged(_ranges);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page range input
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Start Page',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _startPage = int.tryParse(value);
                  if (_startPage != null) {
                    _startPage = _startPage! - 1; // Convert to 0-based
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'End Page',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _endPage = int.tryParse(value);
                  if (_endPage != null) {
                    _endPage = _endPage! - 1; // Convert to 0-based
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _addRange,
              tooltip: 'Add Range',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Selected ranges list
        if (_ranges.isEmpty)
          Text(
            'No ranges selected',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _ranges.length,
              itemBuilder: (context, index) {
                final range = _ranges[index];
                return ListTile(
                  dense: true,
                  title: Text('Pages ${range.start + 1}-${range.end + 1}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeRange(index),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Tip: Add multiple ranges to split into multiple PDFs',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Compression quality levels
enum CompressionQuality {
  low(72),
  medium(100),
  high(120);

  final int dpi;
  const CompressionQuality(this.dpi);
}

final pdfService = PdfService();

