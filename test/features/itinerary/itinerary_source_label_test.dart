import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/itinerary/application/itinerary_source_label.dart';

void main() {
  test('source_type kto_openapi_ennoia displays KTO OpenAPI + ennoia', () {
    expect(itinerarySourceLabel('kto_openapi_ennoia'), 'KTO OpenAPI + ennoia');
    expect(itineraryEnnoiaSucceeded('kto_openapi_ennoia'), isTrue);
  });

  test('KTO-only source displays KTO OpenAPI', () {
    expect(itinerarySourceLabel('kto_openapi'), 'KTO OpenAPI');
    expect(itinerarySourceLabel('kto_openapi_basic'), 'KTO OpenAPI');
    expect(itinerarySourceLabel('kto_openapi_direct'), 'KTO OpenAPI');
    expect(itineraryEnnoiaSucceeded('kto_openapi_basic'), isFalse);
  });

  test('fallback source displays Demo fallback', () {
    expect(itinerarySourceLabel('kto_openapi_fallback'), 'Demo fallback');
    expect(itinerarySourceLabel('demo_fallback'), 'Demo fallback');
  });

  test('mock_ennoia source displays Mock ennoia', () {
    expect(itinerarySourceLabel('mock_ennoia'), 'Mock ennoia');
  });
}
