import 'dart:io';
import 'dart:typed_data';

import 'package:document_companion/local_database/models/current_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

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

  /// Merges multiple PDFs into a single PDF using pdf_combiner
  Future<Uint8List?> mergePdfsFromFiles(List<File> pdfFiles) async {
    try {
      if (pdfFiles.isEmpty) {
        return null;
      }

      // Get temporary directory for merging
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Convert File objects to paths
      final inputPaths = pdfFiles.map((file) => file.path).toList();
      
      // Merge PDFs using pdf_combiner
      final response = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      // Check if merge was successful (response.response contains the output path)
      if (response.response != null && response.response!.isNotEmpty) {
        // Read the merged PDF file
        final mergedFile = File(response.response!);
        if (await mergedFile.exists()) {
          final mergedBytes = await mergedFile.readAsBytes();
          
          // Clean up temporary file
          try {
            await mergedFile.delete();
          } catch (e) {
            // Ignore cleanup errors
          }
          
          return mergedBytes;
        } else {
          print('Error: Merged PDF file not found at ${response.response}');
          return null;
        }
      } else {
        print('Error merging PDFs: ${response.message ?? "Unknown error"}');
        return null;
      }
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
}

final pdfService = PdfService();

