import 'dart:developer' as developer;

import 'package:norigo/ai/clients/ai_client.dart';
import 'package:norigo/ai/prompts/culture_guide_prompts.dart';
import 'package:norigo/features/culture_scan/data/culture_guide_mock_data.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_context.dart';

class CultureGuideHarness {
  const CultureGuideHarness({required this.client});

  final AiClient client;

  Future<CultureGuide> generateGuide(CultureScanContext context) async {
    final safeContext = context.withFallbacks();

    try {
      final response = await client.completeJson(
        prompt: CultureGuidePrompts.generateGuide(),
        context: safeContext.toJson(),
      );

      return CultureGuide.fromJson(
        response,
        fallback: CultureGuideMockData.fallbackGuide,
      );
    } catch (error) {
      developer.log(
        'Culture guide generation failed; using fallback content.',
        name: 'CultureGuideHarness',
        error: error.runtimeType,
      );
      return CultureGuideMockData.fallbackGuide;
    }
  }
}
