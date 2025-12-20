import 'dart:io';
import 'dart:typed_data';

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
}

final pdfService = PdfService();

