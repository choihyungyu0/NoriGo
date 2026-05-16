abstract class AiClient {
  Future<Map<String, Object?>> completeJson({
    required String prompt,
    required Map<String, Object?> context,
  });
}
