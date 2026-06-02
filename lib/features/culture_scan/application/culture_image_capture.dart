import 'dart:typed_data';

class CultureImageCapture {
  const CultureImageCapture({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;

  bool get isEmpty => bytes.isEmpty;
}
