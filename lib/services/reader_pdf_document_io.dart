import 'package:pdfx/pdfx.dart';

Future<PdfDocument> openReaderDocument(String assetPath) {
  return PdfDocument.openAsset(assetPath);
}
