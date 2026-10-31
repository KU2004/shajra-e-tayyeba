import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../services/reader_pdf_document.dart';

class ReaderPdfView extends StatefulWidget {
  const ReaderPdfView({
    super.key,
    required this.assetPath,
    required this.requestedPage,
    required this.fitToScreenSignal,
    required this.onDocumentLoaded,
    required this.onDocumentError,
    required this.onPageChanged,
  });

  final String assetPath;
  final int requestedPage;
  final int fitToScreenSignal;
  final ValueChanged<int> onDocumentLoaded;
  final ValueChanged<Object> onDocumentError;
  final ValueChanged<int> onPageChanged;

  @override
  State<ReaderPdfView> createState() => _ReaderPdfViewState();
}

class _ReaderPdfViewState extends State<ReaderPdfView> {
  late final PdfController _controller = PdfController(
    document: openReaderDocument(widget.assetPath),
  );

  @override
  void didUpdateWidget(covariant ReaderPdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestedPage != oldWidget.requestedPage) {
      _controller.jumpToPage(widget.requestedPage);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfView(
      key: ValueKey(widget.fitToScreenSignal),
      controller: _controller,
      renderer: (page) => page.render(
        width: page.width * 4,
        height: page.height * 4,
        format: PdfPageImageFormat.png,
        backgroundColor: '#ffffff',
      ),
      scrollDirection: Axis.vertical,
      pageSnapping: false,
      physics: const ClampingScrollPhysics(),
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) => Center(
          child: Text(
            'Could not load the PDF.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      onDocumentLoaded: (document) =>
          widget.onDocumentLoaded(document.pagesCount),
      onPageChanged: widget.onPageChanged,
      onDocumentError: widget.onDocumentError,
    );
  }
}
