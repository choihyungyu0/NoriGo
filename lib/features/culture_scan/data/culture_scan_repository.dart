import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

abstract class CultureScanRepository {
  const CultureScanRepository();

  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request);

  Future<String?> uploadScanImage(CultureImageCapture capture) async => null;
}

class CultureScanRepositoryException implements Exception {
  const CultureScanRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'CultureScanRepositoryException: $message';
}
