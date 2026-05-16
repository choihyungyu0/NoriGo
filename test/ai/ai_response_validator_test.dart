import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/ai/harness/ai_response_validator.dart';

void main() {
  test('validator accepts required non-empty strings', () {
    final valid = AiResponseValidator.hasRequiredStringFields(
      {'title': 'Switch plans', 'message': 'The queue may be full.'},
      ['title', 'message'],
    );

    expect(valid, isTrue);
  });

  test('validator rejects missing fields and returns safe fallback text', () {
    final response = {'title': '  '};

    expect(
      AiResponseValidator.hasRequiredStringFields(response, [
        'title',
        'message',
      ]),
      isFalse,
    );
    expect(
      AiResponseValidator.safeText(response, 'message', 'Fallback'),
      'Fallback',
    );
  });
}
