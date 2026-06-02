import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

abstract class CultureScanRepository {
  const CultureScanRepository();

  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request);
}

class CultureScanRepositoryException implements Exception {
  const CultureScanRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'CultureScanRepositoryException: $message';
}
