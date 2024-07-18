import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'main.dart';
import 'dart:io';

class PDFViewerScreen extends StatelessWidget {
  final String path;
  final String name;
  final Function(BuildContext, String) showErrorDialog;

  const PDFViewerScreen(this.path, this.name, this.showErrorDialog,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SfPdfViewer.file(
        File(path),
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          showErrorDialog(context, '${details.error}: ${details.description}');
        },
      ),
    );
  }
}
