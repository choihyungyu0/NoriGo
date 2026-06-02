import {
  classifyWithHeuristics,
  handleCultureVisionDetectRequest,
} from "./index.ts";

Deno.test("heuristic returns an allowed culture object key", () => {
  const result = classifyWithHeuristics({
    current_location: "Bulguksa",
    user_language: "English",
    hint_place_type: "temple",
  });

  assertEquals(result.detected_object, "temple_stone_stack");
  assertEquals(result.place_type, "temple");
  assertEquals(result.confidence, 0.55);
  assertEquals(result.needs_confirmation, true);
  assertEquals(result.source_type, "vision_heuristic");
  assertEquals(result.source_badge, "Context hint");
});

Deno.test("heuristic maps market queue context to allowed ticket object", () => {
  const result = classifyWithHeuristics({
    current_location: "Gwangjang Market number ticket line",
    user_language: "English",
    hint_place_type: "market",
  });

  assertEquals(result.detected_object, "market_queue_ticket");
  assertEquals(result.alternatives.length > 0, true);
});

Deno.test("handler works without image path or configured provider", async () => {
  const response = await handleCultureVisionDetectRequest(new Request(
    "https://example.test/functions/v1/culture-vision-detect",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        current_location: "Seoul subway",
        user_language: "English",
        hint_place_type: "subway",
      }),
    },
  ));
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.detected_object, "subway_pregnant_seat");
  assertEquals(body.source_type, "vision_heuristic");
});

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)} but got ${String(actual)}`);
  }
}
