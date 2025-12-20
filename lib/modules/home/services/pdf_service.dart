import 'dart:io';
import 'dart:typed_data';

import 'package:document_companion/local_database/models/current_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
}

final pdfService = PdfService();

