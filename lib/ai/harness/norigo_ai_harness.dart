import 'dart:developer' as developer;

import 'package:norigo/ai/context/ai_context.dart';
import 'package:norigo/ai/harness/ai_client.dart';
import 'package:norigo/ai/harness/ai_response_validator.dart';
import 'package:norigo/ai/prompts/norigo_prompt_templates.dart';

class AiUserMessage {
  const AiUserMessage({
    required this.title,
    required this.message,
    required this.suggestedAction,
  });

  final String title;
  final String message;
  final String suggestedAction;
}

class NoriGoAiHarness {
  const NoriGoAiHarness({required this.client});

  final AiClient client;

  Future<AiUserMessage> explainCrowdAlert(AiTravelContext context) async {
    if (context.currentLocation.trim().isEmpty) {
      return _fallback();
    }

    try {
      final response = await client.complete(
        prompt: NoriGoPromptTemplates.crowdAlertExplanation(),
        context: context.toCompactMap(),
      );

      final valid = AiResponseValidator.hasRequiredStringFields(response, [
        'title',
        'message',
        'suggestedAction',
      ]);
      if (!valid) {
        return _fallback();
      }

      return AiUserMessage(
        title: AiResponseValidator.safeText(response, 'title', 'Crowd alert'),
        message: AiResponseValidator.safeText(
          response,
          'message',
          'A nearby alternative may be easier right now.',
        ),
        suggestedAction: AiResponseValidator.safeText(
          response,
          'suggestedAction',
          'Check a low-crowd option nearby.',
        ),
      );
    } catch (error) {
      developer.log(
        'AI harness failed. Returning fallback response.',
        name: 'NoriGoAiHarness',
        error: error.runtimeType,
      );
      return _fallback();
    }
  }

  AiUserMessage _fallback() {
    return const AiUserMessage(
      title: 'Crowd alert',
      message:
          'This place may have a hidden waitlist. NoriGo found calmer nearby options.',
      suggestedAction: 'Compare alternatives before you leave.',
    );
  }
}
