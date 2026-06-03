import {
  classifyWithHeuristics,
  handleCultureVisionDetectRequest,
  noMatchResult,
} from "./index.ts";

Deno.test("heuristic returns an allowed culture object key", () => {
  const result = classifyWithHeuristics({
    current_location: "Bulguksa",
    user_language: "English",
    hint_place_type: "temple",
  });

  assertEquals(result.detected_object, "temple_stone_stack");
  assertEquals(result.place_type, "temple");
  assertEquals(result.confidence, 0.42);
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

Deno.test("no match result requires manual selection", () => {
  const result = noMatchResult({
    current_location: "Korean restaurant",
    user_language: "English",
    hint_place_type: "restaurant",
  });

  assertEquals(result.detected_object, "unsupported");
  assertEquals(result.place_type, "restaurant");
  assertEquals(result.confidence, 0);
  assertEquals(result.needs_confirmation, true);
  assertEquals(result.source_type, "vision_no_match");
  assertEquals(result.source_badge, "Manual selection");
  assertEquals(result.detected_object_source, "no_match");
  assertEquals(result.final_decision, "manual_required");
});

Deno.test("handler does not infer objects from context without provider", async () => {
  const response = await handleCultureVisionDetectRequest(
    new Request(
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
    ),
  );
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.detected_object, "unsupported");
  assertEquals(body.source_type, "vision_no_match");
  assertEquals(body.detected_object_source, "no_match");
});

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)} but got ${String(actual)}`);
  }
}
