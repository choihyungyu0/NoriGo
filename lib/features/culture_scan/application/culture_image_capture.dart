import 'dart:typed_data';

class CultureImageCapture {
  const CultureImageCapture({
    required this.bytes,
    required this.contentType,
    required this.extension,
    this.filePath,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;
  final String? filePath;

  bool get isEmpty => bytes.isEmpty;
}
