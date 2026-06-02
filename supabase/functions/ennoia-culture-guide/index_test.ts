import {
  buildCultureContext,
  buildEnnoiaCulturePayload,
  buildBasicResponse,
  buildEnnoiaResponse,
  handleCultureGuideRequest,
  isOutOfScope,
  parseAgentPayload,
  readEnnoiaCultureConfig,
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

Deno.test("ennoia culture config reads ENNOIA_CULTURE_HASH only", () => {
  const config = readEnnoiaCultureConfig((key) => {
    const values: Record<string, string> = {
      ENNOIA_API_ENDPOINT: "https://example.test/chat",
      ENNOIA_PROJECT: "KNTO-PROMPTON-2026-278",
      ENNOIA_API_KEY: "api-key",
      ENNOIA_CULTURE_HASH: "culture-hash",
      ENNOIA_ITINERARY_HASH: "wrong-itinerary-hash",
      ENNOIA_ITINERARY_API_HASH: "wrong-itinerary-api-hash",
      ENNOIA_RETRIP_HASH: "wrong-retrip-hash",
    };
    return values[key];
  });

  assertEquals(config.hash, "culture-hash");
  assertEquals(config.missing.length, 0);
});

Deno.test("ennoia culture payload includes compact culture_context", () => {
  const context = buildCultureContext(request(), entry, null);
  const payload = buildEnnoiaCulturePayload(
    request(),
    entry,
    context,
    "culture-hash",
  );
  const params = payload.params as Record<string, unknown>;
  const messages = payload.messages as Array<Record<string, unknown>>;
  const firstMessage = messages[0];
  const content = firstMessage.content as Array<Record<string, unknown>>;

  assertEquals(payload.hash, "culture-hash");
  assertEquals(typeof params.culture_context, "string");
  assertEquals(params.detected_object, "temple_stone_stack");
  assertEquals(content[0].type, "text");
  assertIncludes(String(content[0].text), "Do not call tools.");
});

Deno.test("vision metadata is returned with final culture guide response", async () => {
  const response = await handleCultureGuideRequest(new Request(
    "https://example.test/functions/v1/ennoia-culture-guide",
    {
      method: "POST",
      body: JSON.stringify(request({
        user_question: "Explain Korean election politics",
        detected_object_source: "vision_confirmed",
        vision_confidence: 0.86,
        vision_source_type: "vision_ai",
        vision_source_badge: "Vision AI",
        vision_alternatives: [
          {
            detected_object: "temple_stone_stack",
            confidence: 0.86,
          },
        ],
        image_path: "user-1/frame.jpg",
      })),
      headers: { "Content-Type": "application/json" },
    },
  ));
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.detected_object_source, "vision_confirmed");
  assertEquals(body.vision_confidence, 0.86);
  assertEquals(body.vision_source_badge, "Vision AI");
  assertEquals(body.image_path, "user-1/frame.jpg");
});

Deno.test("vision metadata is included in culture scan record insert", async () => {
  const originalFetch = globalThis.fetch;
  const originalUrl = Deno.env.get("SUPABASE_URL");
  const originalServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  let insertedRow: Record<string, unknown> | null = null;

  Deno.env.set("SUPABASE_URL", "https://project.supabase.co");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-role");
  globalThis.fetch = async (_input: RequestInfo | URL, init?: RequestInit) => {
    insertedRow = JSON.parse(String(init?.body ?? "{}"));
    return new Response(JSON.stringify([{ id: "record-1" }]), {
      status: 201,
      headers: { "Content-Type": "application/json" },
    });
  };

  try {
    const response = await handleCultureGuideRequest(new Request(
      "https://example.test/functions/v1/ennoia-culture-guide",
      {
        method: "POST",
        body: JSON.stringify(request({
          user_question: "Explain Korean election politics",
          detected_object_source: "vision_confirmed",
          vision_confidence: 0.78,
          vision_source_badge: "Vision AI",
          image_path: "user-1/frame.jpg",
        })),
        headers: { "Content-Type": "application/json" },
      },
    ));
    const body = await response.json();
    const row = insertedRow as Record<string, unknown> | null;
    if (!row) throw new Error("Expected culture_scan_records insert row.");

    assertEquals(body.persisted, true);
    assertEquals(row["detected_object_source"], "vision_confirmed");
    assertEquals(row["vision_confidence"], 0.78);
    assertEquals(row["image_path"], "user-1/frame.jpg");
  } finally {
    globalThis.fetch = originalFetch;
    restoreEnv("SUPABASE_URL", originalUrl);
    restoreEnv("SUPABASE_SERVICE_ROLE_KEY", originalServiceRole);
  }
});

Deno.test("markdown JSON is parsed from ennoia content", () => {
  const payload = parseAgentPayload(JSON.stringify({
    output_text: "```json\n{\"question\":\"Q\",\"korean_phrase\":\"P\"}\n```",
  }));

  assertEquals(payload?.question, "Q");
  assertEquals(payload?.korean_phrase, "P");
});

Deno.test("array text parts are parsed from choices message content", () => {
  const payload = parseAgentPayload(JSON.stringify({
    choices: [
      {
        message: {
          content: [
            {
              type: "text",
              text: "{\"question\":\"Array Q\",\"korean_phrase\":\"Array P\"}",
            },
          ],
        },
      },
    ],
  }));

  assertEquals(payload?.question, "Array Q");
  assertEquals(payload?.korean_phrase, "Array P");
});

Deno.test("minor prose around JSON is parsed", () => {
  const payload = parseAgentPayload(JSON.stringify({
    data: {
      message: {
        content:
          "Here is the result: {\"question\":\"Prose Q\",\"confidence\":0.8}",
      },
    },
  }));

  assertEquals(payload?.question, "Prose Q");
  assertEquals(payload?.confidence, 0.8);
});

Deno.test("scope-limited questions return before ennoia config is required", async () => {
  const response = await handleCultureGuideRequest(new Request(
    "https://example.test/functions/v1/ennoia-culture-guide",
    {
      method: "POST",
      body: JSON.stringify(request({
        user_question: "Explain Korean election politics",
      })),
      headers: { "Content-Type": "application/json" },
    },
  ));
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body.source_type, "culture_scope_limited");
  assertEquals(body.source_badge, "Travel behavior only");
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

function assertIncludes(actual: string, expected: string): void {
  if (!actual.includes(expected)) {
    throw new Error(`Expected ${actual} to include ${expected}`);
  }
}

function restoreEnv(key: string, value: string | undefined): void {
  if (value === undefined) {
    Deno.env.delete(key);
  } else {
    Deno.env.set(key, value);
  }
}
