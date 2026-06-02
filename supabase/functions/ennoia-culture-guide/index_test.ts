import {
  buildBasicResponse,
  buildEnnoiaResponse,
  isOutOfScope,
} from "./index.ts";
import type { CultureGuideEntry, CultureRequest } from "./index.ts";

Deno.test("scope guard blocks broad politics and social questions", () => {
  assertEquals(
    isOutOfScope(request({ user_question: "Explain Korean election politics" })),
    true,
  );
  assertEquals(
    isOutOfScope(request({ user_question: "Why do Koreans use call bells?" })),
    false,
  );
});

Deno.test("DB/basic fallback returns culture_db_basic", () => {
  const response = buildBasicResponse(request(), entry);

  assertEquals(response.source_type, "culture_db_basic");
  assertEquals(response.source_badge, "Culture DB");
  assertEquals(response.ennoia_succeeded, false);
});

Deno.test("ennoia success returns culture_db_ennoia", () => {
  const response = buildEnnoiaResponse(request(), entry, {
    question: "Why do people stack stones?",
    description: "Use this as a quiet wish practice.",
    meaning: "Each stone carries a wish.",
    etiquette: "Do not touch existing stacks.",
    korean_phrase: "소원 성취하세요",
    confidence: 0.9,
  });

  assertEquals(response.source_type, "culture_db_ennoia");
  assertEquals(response.source_badge, "Culture DB + ennoia");
  assertEquals(response.ennoia_succeeded, true);
});

function request(overrides: Partial<CultureRequest> = {}): CultureRequest {
  return {
    user_language: "English",
    current_location: "Bulguksa",
    place_type: "temple",
    detected_object: "temple_stone_stack",
    korean_keyword: "소원 성취",
    user_intent: "Understand local culture and etiquette",
    user_question: "Why do Koreans stack stones here?",
    image_path: null,
    ...overrides,
  };
}

const entry: CultureGuideEntry = {
  object_key: "temple_stone_stack",
  place_type: "temple",
  category: "temple_etiquette",
  title_ko: "사찰 돌탑",
  title_en: "Temple stone stack",
  short_question: "Why do people stack stones at temples?",
  meaning: "Small stone stacks often express a quiet wish.",
  etiquette: "Look without touching existing stacks.",
  story: "A quiet temple tradition.",
  korean_phrase: "소원 성취하세요",
  pronunciation: "so-won seong-chwi-ha-se-yo",
  phrase_meaning: "May your wish come true.",
  tags: ["stone_stack", "temple"],
};

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)} but got ${String(actual)}`);
  }
}
