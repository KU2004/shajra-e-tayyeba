import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

Future<PdfDocument> openReaderDocument(String assetPath) async {
  final asset = await rootBundle.load(assetPath);
  return PdfDocument.openData(asset.buffer.asUint8List());
}
