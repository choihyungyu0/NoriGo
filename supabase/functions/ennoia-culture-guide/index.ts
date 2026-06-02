export type CultureRequest = {
  user_language: string;
  current_location: string;
  place_type: string;
  detected_object: string;
  korean_keyword: string;
  user_intent: string;
  user_question?: string | null;
  image_path?: string | null;
};

export type JsonRecord = Record<string, unknown>;

export type CultureGuideEntry = {
  id?: string;
  object_key: string;
  place_type: string;
  category: string;
  title_ko: string;
  title_en: string;
  short_question?: string | null;
  meaning: string;
  etiquette: string;
  story?: string | null;
  korean_phrase?: string | null;
  pronunciation?: string | null;
  phrase_meaning?: string | null;
  allowed_intents?: string[] | null;
  blocked_topics?: string[] | null;
  tags?: string[] | null;
  is_active?: boolean;
};

type CultureGuideResponse = {
  question: string;
  description: string;
  meaning: string;
  etiquette: string;
  story: string;
  korean_phrase: string;
  pronunciation: string;
  phrase_meaning: string;
  confidence: number;
  source_type: string;
  source_badge: string;
  ennoia_succeeded: boolean;
  persisted: boolean;
  cultureScanRecordId: string;
  scope_limited: boolean;
  location_name: string;
  place_type: string;
  detected_object: string;
  korean_keyword: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ennoia-user-id",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const requiredFields: Array<keyof CultureRequest> = [
  "user_language",
  "current_location",
  "place_type",
  "detected_object",
  "korean_keyword",
  "user_intent",
];

const ktoKeywordSearchUrl =
  "https://apis.data.go.kr/B551011/KorService2/searchKeyword2";

export async function handleCultureGuideRequest(
  request: Request,
): Promise<Response> {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const bodyResult = await readJsonBody(request);
  if (!bodyResult.ok) {
    return jsonResponse({ error: bodyResult.error }, 400);
  }

  const validationError = validateFields(bodyResult.body, requiredFields);
  if (validationError) {
    return jsonResponse({ error: validationError }, 400);
  }

  const params = normalizeRequest(bodyResult.body as CultureRequest);
  const hasEnnoiaHash = Boolean(Deno.env.get("ENNOIA_CULTURE_HASH")?.trim());
  const hasKtoKey = Boolean(Deno.env.get("KTO_SERVICE_KEY")?.trim());

  if (isOutOfScope(params)) {
    const response = buildScopeLimitedResponse(params);
    logSafe({
      source_type: response.source_type,
      place_type: params.place_type,
      detected_object: params.detected_object,
      hasEnnoiaHash,
      hasKtoKey,
      ennoia_status: "skipped_scope_limited",
    });
    return jsonResponse(await withPersistence(request, params, response), 200);
  }

  const guideEntries = await loadGuideEntries();
  const entry = findBestEntry(guideEntries.entries, params);
  const ktoContext = hasKtoKey
    ? await fetchKtoLocationContext(params).catch(() => null)
    : null;

  if (!entry || !guideEntries.fromDatabase) {
    const fallback = buildFallbackResponse(params);
    logSafe({
      source_type: fallback.source_type,
      place_type: params.place_type,
      detected_object: params.detected_object,
      hasEnnoiaHash,
      hasKtoKey,
      ennoia_status: guideEntries.fromDatabase
        ? "skipped_no_db_match"
        : "skipped_db_unavailable",
    });
    return jsonResponse(await withPersistence(request, params, fallback), 200);
  }

  try {
    const ennoiaPayload = await requestEnnoiaCultureGuide(
      request,
      params,
      entry,
      ktoContext,
    );
    const response = buildEnnoiaResponse(params, entry, ennoiaPayload);
    logSafe({
      source_type: response.source_type,
      place_type: params.place_type,
      detected_object: params.detected_object,
      hasEnnoiaHash,
      hasKtoKey,
      ennoia_status: "success",
    });
    return jsonResponse(await withPersistence(request, params, response), 200);
  } catch (_) {
    const response = buildBasicResponse(params, entry);
    logSafe({
      source_type: response.source_type,
      place_type: params.place_type,
      detected_object: params.detected_object,
      hasEnnoiaHash,
      hasKtoKey,
      ennoia_status: "failed_basic_fallback",
    });
    return jsonResponse(await withPersistence(request, params, response), 200);
  }
}

if (import.meta.main) {
  Deno.serve(handleCultureGuideRequest);
}

async function readJsonBody(
  request: Request,
): Promise<{ ok: true; body: JsonRecord } | { ok: false; error: string }> {
  try {
    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return { ok: false, error: "Request body must be a JSON object." };
    }
    return { ok: true, body: body as JsonRecord };
  } catch (_) {
    return { ok: false, error: "Request body must be valid JSON." };
  }
}

function validateFields(body: JsonRecord, fields: string[]): string | null {
  for (const field of fields) {
    const value = body[field];
    if (typeof value !== "string" || value.trim().length === 0) {
      return `Missing or invalid field: ${field}.`;
    }
  }
  return null;
}

function normalizeRequest(params: CultureRequest): CultureRequest {
  return {
    user_language: clean(params.user_language, "English"),
    current_location: clean(params.current_location, "Bulguksa"),
    place_type: normalizePlaceType(params.place_type),
    detected_object: normalizeDetectedObject(params.detected_object),
    korean_keyword: clean(params.korean_keyword, "소원 성취"),
    user_intent: clean(
      params.user_intent,
      "Understand local culture and etiquette",
    ),
    user_question: cleanOptional(params.user_question),
    image_path: cleanOptional(params.image_path),
  };
}

export function normalizePlaceType(value: string): string {
  const normalized = slug(value);
  const aliases: Record<string, string> = {
    cafe_or_restaurant: "cafe_or_restaurant",
    cafe_restaurant: "cafe_or_restaurant",
    restaurant: "restaurant",
    cafe: "cafe",
    subway: "subway",
    metro: "subway",
    temple: "temple",
    palace: "palace",
    market: "market",
    hanok: "hanok_village",
    hanok_village: "hanok_village",
  };
  return aliases[normalized] ?? normalized;
}

export function normalizeDetectedObject(value: string): string {
  const normalized = slug(value);
  const pairs: Array<[string, string]> = [
    ["temple_stone_stack", "temple_stone_stack"],
    ["stone_stack", "temple_stone_stack"],
    ["call_bell", "restaurant_call_bell"],
    ["restaurant_call_bell", "restaurant_call_bell"],
    ["pregnant_priority_seat", "subway_pregnant_seat"],
    ["pregnant_seat", "subway_pregnant_seat"],
    ["subway_pregnant_seat", "subway_pregnant_seat"],
    ["quiet_cafe", "cafe_quiet_work"],
    ["cafe_quiet_work", "cafe_quiet_work"],
    ["kiosk", "kiosk_ordering"],
    ["kiosk_ordering", "kiosk_ordering"],
    ["queue_ticket", "market_queue_ticket"],
    ["market_queue_ticket", "market_queue_ticket"],
    ["cash_food", "market_cash_food"],
    ["market_cash_food", "market_cash_food"],
    ["photo_etiquette", "palace_photo_etiquette"],
    ["palace_photo_etiquette", "palace_photo_etiquette"],
    ["resident_etiquette", "hanok_resident_etiquette"],
    ["hanok_resident_etiquette", "hanok_resident_etiquette"],
    ["waiting_number_ticket", "waiting_number_ticket"],
  ];
  return pairs.find(([alias]) => normalized.includes(alias))?.[1] ??
    normalized;
}

export function isOutOfScope(params: CultureRequest): boolean {
  const text = [
    params.user_question ?? "",
    params.user_intent,
    params.detected_object,
  ].join(" ").toLowerCase();
  const blockedPatterns = [
    "politic",
    "president",
    "election",
    "government",
    "war",
    "colonial",
    "controversy",
    "conflict",
    "national character",
    "why are koreans",
    "stereotype",
    "dating",
    "meme",
    "gender politics",
    "social issue",
  ];
  return blockedPatterns.some((pattern) => text.includes(pattern));
}

async function loadGuideEntries(): Promise<{
  entries: CultureGuideEntry[];
  fromDatabase: boolean;
}> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) {
    return { entries: defaultGuideEntries, fromDatabase: false };
  }

  const url = new URL(
    `${supabaseUrl.replace(/\/+$/, "")}/rest/v1/culture_guide_entries`,
  );
  url.searchParams.set("select", "*");
  url.searchParams.set("is_active", "eq.true");
  url.searchParams.set("limit", "100");

  const response = await fetch(url, {
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json; charset=utf-8",
    },
  });

  if (!response.ok) {
    return { entries: defaultGuideEntries, fromDatabase: false };
  }
  const decoded = await response.json();
  if (!Array.isArray(decoded)) {
    return { entries: defaultGuideEntries, fromDatabase: false };
  }
  const entries = decoded
    .filter((item): item is JsonRecord =>
      typeof item === "object" && item !== null && !Array.isArray(item)
    )
    .map((item) => ({
      object_key: readString(item, "object_key"),
      place_type: normalizePlaceType(readString(item, "place_type")),
      category: readString(item, "category"),
      title_ko: readString(item, "title_ko"),
      title_en: readString(item, "title_en"),
      short_question: readOptionalString(item, "short_question"),
      meaning: readString(item, "meaning"),
      etiquette: readString(item, "etiquette"),
      story: readOptionalString(item, "story"),
      korean_phrase: readOptionalString(item, "korean_phrase"),
      pronunciation: readOptionalString(item, "pronunciation"),
      phrase_meaning: readOptionalString(item, "phrase_meaning"),
      allowed_intents: readStringArray(item, "allowed_intents"),
      blocked_topics: readStringArray(item, "blocked_topics"),
      tags: readStringArray(item, "tags"),
      is_active: item.is_active !== false,
    }))
    .filter((item) => item.object_key && item.place_type && item.meaning);
  return entries.length > 0
    ? { entries, fromDatabase: true }
    : { entries: defaultGuideEntries, fromDatabase: false };
}

export function findBestEntry(
  entries: CultureGuideEntry[],
  params: CultureRequest,
): CultureGuideEntry | null {
  let best: { entry: CultureGuideEntry; score: number } | null = null;
  const questionTokens = new Set(
    slug(
      `${params.user_question ?? ""} ${params.user_intent} ${params.current_location}`,
    ).split("_").filter((token) => token.length > 2),
  );

  for (const entry of entries) {
    if (entry.is_active === false) continue;
    let score = 0;
    if (entry.object_key === params.detected_object) score += 100;
    if (entry.place_type === params.place_type) score += 35;
    if (
      entry.place_type === "cafe_or_restaurant" &&
      ["cafe", "restaurant"].includes(params.place_type)
    ) {
      score += 30;
    }
    if (params.detected_object.includes(entry.category)) score += 12;
    for (const tag of entry.tags ?? []) {
      const tagSlug = slug(tag);
      if (params.detected_object.includes(tagSlug)) score += 8;
      if (questionTokens.has(tagSlug)) score += 4;
    }
    if (!best || score > best.score) best = { entry, score };
  }

  if (!best || best.score < 30) return null;
  return best.entry;
}

async function fetchKtoLocationContext(
  params: CultureRequest,
): Promise<JsonRecord | null> {
  const serviceKey = Deno.env.get("KTO_SERVICE_KEY")?.trim();
  if (!serviceKey || !looksLikeTouristPlace(params.current_location)) {
    return null;
  }

  const url = new URL(ktoKeywordSearchUrl);
  url.searchParams.set("MobileOS", "ETC");
  url.searchParams.set("MobileApp", "NoriGo");
  url.searchParams.set("_type", "json");
  url.searchParams.set("numOfRows", "1");
  url.searchParams.set("pageNo", "1");
  url.searchParams.set("keyword", params.current_location);

  const key = serviceKey.includes("%") ? serviceKey : encodeURIComponent(
    serviceKey,
  );
  const response = await fetch(`${url.toString()}&serviceKey=${key}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) return null;

  const decoded = await response.json();
  const items =
    decoded?.response?.body?.items?.item;
  const first = Array.isArray(items) ? items[0] : items;
  if (!first || typeof first !== "object") return null;
  return {
    title: readString(first, "title"),
    addr1: readString(first, "addr1"),
    contentid: readString(first, "contentid"),
  };
}

function looksLikeTouristPlace(location: string): boolean {
  const normalized = slug(location);
  if (["cafe", "restaurant", "market", "subway"].includes(normalized)) {
    return false;
  }
  return normalized.length >= 4;
}

async function requestEnnoiaCultureGuide(
  request: Request,
  params: CultureRequest,
  entry: CultureGuideEntry,
  ktoContext: JsonRecord | null,
): Promise<JsonRecord> {
  const endpoint = Deno.env.get("ENNOIA_API_ENDPOINT")?.trim();
  const project = Deno.env.get("ENNOIA_PROJECT")?.trim();
  const apiKey = Deno.env.get("ENNOIA_API_KEY")?.trim();
  const hash = Deno.env.get("ENNOIA_CULTURE_HASH")?.trim();
  if (!endpoint || !project || !apiKey || !hash) {
    throw new Error("ennoia culture configuration missing");
  }

  const cultureContext = buildCultureContext(params, entry, ktoContext);
  const ennoiaPayload = {
    hash,
    params: {
      user_language: params.user_language,
      current_location: params.current_location,
      place_type: params.place_type,
      detected_object: params.detected_object,
      user_intent: params.user_intent,
      user_question: params.user_question ?? "",
      CULTURE_CONTEXT: JSON.stringify(cultureContext),
    },
    messages: [
      {
        role: "user",
        content: buildEnnoiaPrompt(cultureContext),
      },
    ],
  };
  const ennoiaUserId = request.headers.get("x-ennoia-user-id")?.trim() ||
    Deno.env.get("ENNOIA_USER_ID")?.trim() ||
    "norigo-culture-guide";

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      project,
      apiKey,
      "X-ENNOIA-USER-ID": ennoiaUserId,
      "Content-Type": "application/json; charset=utf-8",
    },
    body: JSON.stringify(ennoiaPayload),
  });

  if (!response.ok) {
    throw new Error(`ennoia returned HTTP ${response.status}`);
  }

  const parsed = parseAgentPayload(await response.text());
  if (!parsed) throw new Error("ennoia returned invalid JSON");
  return parsed;
}

export function buildCultureContext(
  params: CultureRequest,
  entry: CultureGuideEntry,
  ktoContext: JsonRecord | null,
): JsonRecord {
  return {
    user_language: params.user_language,
    current_location: params.current_location,
    place_type: params.place_type,
    detected_object: params.detected_object,
    korean_keyword: params.korean_keyword,
    user_intent: params.user_intent,
    user_question: params.user_question ?? "",
    guide_entry: {
      object_key: entry.object_key,
      category: entry.category,
      title_en: entry.title_en,
      short_question: entry.short_question ?? "",
      meaning: entry.meaning,
      etiquette: entry.etiquette,
      story: entry.story ?? "",
      korean_phrase: entry.korean_phrase ?? "",
      pronunciation: entry.pronunciation ?? "",
      phrase_meaning: entry.phrase_meaning ?? "",
      allowed_intents: entry.allowed_intents ?? [],
      blocked_topics: entry.blocked_topics ?? [],
      tags: entry.tags ?? [],
    },
    kto_location_context: ktoContext ?? {},
  };
}

function buildEnnoiaPrompt(cultureContext: JsonRecord): string {
  return [
    "Use only CULTURE_CONTEXT.",
    "Do not answer broad culture, politics, dating, stereotypes, memes, or social controversy.",
    "Return valid JSON only.",
    "Keep answers practical and action-oriented.",
    "If a field is unknown, use an empty string.",
    JSON.stringify({
      CULTURE_CONTEXT: cultureContext,
      response_shape: {
        question: "short traveler question",
        description: "one practical overview",
        meaning: "what this means here",
        etiquette: "what the traveler should do",
        story: "brief context without controversy",
        korean_phrase: "useful Korean phrase",
        pronunciation: "simple romanization",
        phrase_meaning: "phrase meaning",
        confidence: 0.86,
      },
    }),
  ].join("\n");
}

export function buildEnnoiaResponse(
  params: CultureRequest,
  entry: CultureGuideEntry,
  ennoiaPayload: JsonRecord,
): CultureGuideResponse {
  const basic = buildBasicResponse(params, entry);
  return {
    ...basic,
    question: readPayloadString(ennoiaPayload, ["question", "headline"]) ||
      basic.question,
    description: readPayloadString(ennoiaPayload, [
      "description",
      "summary",
      "overview",
    ]) || basic.description,
    meaning: readPayloadString(ennoiaPayload, ["meaning"]) || basic.meaning,
    etiquette: readPayloadString(ennoiaPayload, ["etiquette", "manners"]) ||
      basic.etiquette,
    story: readPayloadString(ennoiaPayload, ["story", "background"]) ||
      basic.story,
    korean_phrase: readPayloadString(ennoiaPayload, [
      "korean_phrase",
      "koreanPhrase",
    ]) || basic.korean_phrase,
    pronunciation: readPayloadString(ennoiaPayload, ["pronunciation"]) ||
      basic.pronunciation,
    phrase_meaning: readPayloadString(ennoiaPayload, [
      "phrase_meaning",
      "phraseMeaning",
    ]) || basic.phrase_meaning,
    confidence: readPayloadNumber(ennoiaPayload, "confidence") ?? 0.86,
    source_type: "culture_db_ennoia",
    source_badge: "Culture DB + ennoia",
    ennoia_succeeded: true,
  };
}

export function buildBasicResponse(
  params: CultureRequest,
  entry: CultureGuideEntry,
): CultureGuideResponse {
  const question = params.user_question || entry.short_question ||
    "What should I do here?";
  return {
    question,
    description:
      `${entry.title_en}: ${entry.meaning}`,
    meaning: entry.meaning,
    etiquette: entry.etiquette,
    story: entry.story ?? "",
    korean_phrase: entry.korean_phrase ?? params.korean_keyword,
    pronunciation: entry.pronunciation ?? "",
    phrase_meaning: entry.phrase_meaning ?? "",
    confidence: 0.72,
    source_type: "culture_db_basic",
    source_badge: "Culture DB",
    ennoia_succeeded: false,
    persisted: false,
    cultureScanRecordId: "",
    scope_limited: false,
    location_name: params.current_location,
    place_type: params.place_type,
    detected_object: entry.object_key,
    korean_keyword: params.korean_keyword,
  };
}

function buildScopeLimitedResponse(params: CultureRequest): CultureGuideResponse {
  return {
    question: params.user_question || "Can NoriGo answer this?",
    description:
      "NoriGo Culture Scan only answers immediate travel behavior, etiquette, and practical phrase questions for the current place.",
    meaning: "This topic is outside the Culture Scan guide scope.",
    etiquette:
      "For this feature, ask about what to do here as a traveler: where to stand, how to order, when to be quiet, or what phrase to use.",
    story: "",
    korean_phrase: "",
    pronunciation: "",
    phrase_meaning: "",
    confidence: 1.0,
    source_type: "culture_scope_limited",
    source_badge: "Travel behavior only",
    ennoia_succeeded: false,
    persisted: false,
    cultureScanRecordId: "",
    scope_limited: true,
    location_name: params.current_location,
    place_type: params.place_type,
    detected_object: params.detected_object,
    korean_keyword: params.korean_keyword,
  };
}

function buildFallbackResponse(params: CultureRequest): CultureGuideResponse {
  return {
    question: params.user_question || "What should I do here?",
    description:
      "NoriGo does not have a curated entry for this exact situation yet, so it is showing a limited travel-behavior fallback.",
    meaning:
      "Use the current place and visible signs as the source of truth until this situation is added to the culture guide.",
    etiquette:
      "Move slowly, avoid blocking others, follow posted signs, and ask staff politely if you are unsure.",
    story: "",
    korean_phrase: "도와주실 수 있나요?",
    pronunciation: "do-wa-ju-sil su in-na-yo",
    phrase_meaning: "Could you help me?",
    confidence: 0.35,
    source_type: "culture_fallback",
    source_badge: "Demo fallback",
    ennoia_succeeded: false,
    persisted: false,
    cultureScanRecordId: "",
    scope_limited: false,
    location_name: params.current_location,
    place_type: params.place_type,
    detected_object: params.detected_object,
    korean_keyword: params.korean_keyword,
  };
}

async function withPersistence(
  request: Request,
  params: CultureRequest,
  response: CultureGuideResponse,
): Promise<CultureGuideResponse> {
  const recordId = await saveScanRecord(request, params, response).catch(
    () => "",
  );
  return {
    ...response,
    persisted: recordId.length > 0,
    cultureScanRecordId: recordId,
  };
}

async function saveScanRecord(
  request: Request,
  params: CultureRequest,
  response: CultureGuideResponse,
): Promise<string> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) return "";

  const userId = userIdFromAuthHeader(request.headers.get("authorization"));
  const row = {
    user_id: userId,
    location_name: params.current_location,
    place_type: params.place_type,
    detected_object: response.detected_object || params.detected_object,
    korean_keyword: params.korean_keyword,
    user_intent: params.user_intent,
    user_language: params.user_language,
    source_type: response.source_type,
    source_badge: response.source_badge,
    ennoia_succeeded: response.ennoia_succeeded,
    response_json: response,
    image_path: params.image_path ?? null,
  };

  const url = new URL(
    `${supabaseUrl.replace(/\/+$/, "")}/rest/v1/culture_scan_records`,
  );
  url.searchParams.set("select", "id");
  const insertResponse = await fetch(url, {
    method: "POST",
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json; charset=utf-8",
      Prefer: "return=representation",
    },
    body: JSON.stringify(row),
  });

  if (!insertResponse.ok) return "";
  const decoded = await insertResponse.json();
  const first = Array.isArray(decoded) ? decoded[0] : decoded;
  return first && typeof first === "object" ? readString(first, "id") : "";
}

function userIdFromAuthHeader(value: string | null): string | null {
  if (!value) return null;
  const token = value.replace(/^Bearer\s+/i, "").trim();
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const payload = JSON.parse(base64UrlDecode(parts[1]));
    return typeof payload.sub === "string" && payload.sub.trim()
      ? payload.sub.trim()
      : null;
  } catch (_) {
    return null;
  }
}

function base64UrlDecode(value: string): string {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64.padEnd(
    base64.length + ((4 - base64.length % 4) % 4),
    "=",
  );
  return atob(padded);
}

export function parseAgentPayload(body: string): JsonRecord | null {
  try {
    const decoded = JSON.parse(body);
    const payload = extractAgentContent(decoded) ?? decoded;
    const parsed = typeof payload === "string"
      ? parseContentString(payload)
      : payload;
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      return parsed as JsonRecord;
    }
  } catch (_) {
    return null;
  }
  return null;
}

function extractAgentContent(decoded: unknown): unknown {
  if (!decoded || typeof decoded !== "object" || Array.isArray(decoded)) {
    return null;
  }
  const record = decoded as JsonRecord;
  if (typeof record.output_text === "string") return record.output_text;
  if (typeof record.content === "string") return record.content;
  if (record.content && typeof record.content === "object") {
    return record.content;
  }
  if (record.data) return extractAgentContent(record.data);

  const message = record.message;
  if (message && typeof message === "object" && !Array.isArray(message)) {
    const content = (message as JsonRecord).content;
    if (typeof content === "string") return content;
    if (Array.isArray(content)) return textFromContentParts(content);
  }

  const choices = record.choices;
  if (Array.isArray(choices) && choices.length > 0) {
    const firstChoice = choices[0];
    if (firstChoice && typeof firstChoice === "object") {
      const choice = firstChoice as JsonRecord;
      if (typeof choice.text === "string") return choice.text;
      return extractAgentContent(choice.message);
    }
  }

  return null;
}

function textFromContentParts(parts: unknown[]): string {
  return parts.map((part) => {
    if (typeof part === "string") return part;
    if (part && typeof part === "object") {
      const record = part as JsonRecord;
      if (typeof record.text === "string") return record.text;
      if (typeof record.content === "string") return record.content;
    }
    return "";
  }).filter((part) => part.length > 0).join("\n");
}

function parseContentString(content: string): unknown {
  const stripped = content.trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/, "")
    .trim();
  try {
    return JSON.parse(stripped);
  } catch (_) {
    const start = stripped.indexOf("{");
    const end = stripped.lastIndexOf("}");
    if (start >= 0 && end > start) {
      return JSON.parse(stripped.slice(start, end + 1));
    }
    throw new Error("content is not JSON");
  }
}

function readPayloadString(
  payload: JsonRecord,
  keys: string[],
): string | null {
  const nested = nestedPayload(payload);
  for (const source of [payload, nested]) {
    if (!source) continue;
    for (const key of keys) {
      const value = source[key];
      if (typeof value === "string" && value.trim()) return value.trim();
    }
  }
  return null;
}

function readPayloadNumber(payload: JsonRecord, key: string): number | null {
  const value = payload[key];
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function nestedPayload(payload: JsonRecord): JsonRecord | null {
  for (const key of ["cultureGuide", "culture_guide", "guide", "result"]) {
    const value = payload[key];
    if (value && typeof value === "object" && !Array.isArray(value)) {
      return value as JsonRecord;
    }
  }
  return null;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function logSafe(payload: JsonRecord): void {
  console.log("culture-guide", JSON.stringify(payload));
}

function slug(value: string): string {
  return clean(value, "")
    .toLowerCase()
    .replace(/[^a-z0-9가-힣]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function clean(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function cleanOptional(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function readString(record: unknown, key: string): string {
  if (!record || typeof record !== "object") return "";
  const value = (record as JsonRecord)[key];
  return typeof value === "string" && value.trim() ? value.trim() : "";
}

function readOptionalString(record: JsonRecord, key: string): string | null {
  const value = record[key];
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function readStringArray(record: JsonRecord, key: string): string[] {
  const value = record[key];
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => typeof item === "string" ? item.trim() : "")
    .filter((item) => item.length > 0);
}

const defaultGuideEntries: CultureGuideEntry[] = [
  {
    object_key: "temple_stone_stack",
    place_type: "temple",
    category: "temple_etiquette",
    title_ko: "사찰 돌탑",
    title_en: "Temple stone stack",
    short_question: "Why do people stack stones at temples?",
    meaning:
      "Small stone stacks often express a quiet wish for health, peace, or good fortune.",
    etiquette:
      "Look without touching existing stacks. If signs allow it, add one small stone gently and keep the area tidy.",
    story:
      "At Korean temples, stone stacks are treated as personal wishes rather than photo props.",
    korean_phrase: "소원 성취하세요",
    pronunciation: "so-won seong-chwi-ha-se-yo",
    phrase_meaning: "May your wish come true.",
    tags: ["stone_stack", "wish", "temple", "bulguksa"],
  },
  {
    object_key: "restaurant_call_bell",
    place_type: "restaurant",
    category: "restaurant_etiquette",
    title_ko: "식당 호출벨",
    title_en: "Restaurant call bell",
    short_question: "Is it polite to press the call bell?",
    meaning:
      "Many Korean restaurants use call bells so guests can ask for service without waving loudly.",
    etiquette:
      "Press once, wait, and keep your request short and polite. Repeated pressing can feel impatient.",
    story:
      "The bell helps staff cover many tables quickly while keeping the dining room calm.",
    korean_phrase: "여기요",
    pronunciation: "yeo-gi-yo",
    phrase_meaning: "Excuse me, over here please.",
    tags: ["call_bell", "restaurant", "service", "ordering"],
  },
  {
    object_key: "subway_pregnant_seat",
    place_type: "subway",
    category: "transit_etiquette",
    title_ko: "임산부 배려석",
    title_en: "Pregnant priority seat",
    short_question: "Can I sit in the pink subway seat?",
    meaning:
      "Pink subway seats are reserved to make pregnancy support visible and easy.",
    etiquette:
      "Avoid sitting there even when the train looks quiet. Choose another seat unless you are pregnant.",
    story:
      "The color helps people offer space without asking personal questions.",
    korean_phrase: "먼저 앉으세요",
    pronunciation: "meon-jeo an-jeu-se-yo",
    phrase_meaning: "Please sit first.",
    tags: ["subway", "pregnant_seat", "priority_seat", "transit"],
  },
  {
    object_key: "cafe_quiet_work",
    place_type: "cafe",
    category: "cafe_etiquette",
    title_ko: "조용한 카페 이용",
    title_en: "Quiet cafe culture",
    short_question: "Why is everyone so quiet in this cafe?",
    meaning:
      "Many cafes are used for studying, working, and calm conversation.",
    etiquette:
      "Keep calls short, use headphones, and avoid taking a large table during busy hours if you are alone.",
    story:
      "Cafe culture in Korea often blends social space with study and work space.",
    korean_phrase: "조용히 할게요",
    pronunciation: "jo-yong-hi hal-ge-yo",
    phrase_meaning: "I will keep it quiet.",
    tags: ["cafe", "quiet", "work", "study"],
  },
  {
    object_key: "kiosk_ordering",
    place_type: "cafe_or_restaurant",
    category: "ordering_etiquette",
    title_ko: "키오스크 주문",
    title_en: "Kiosk ordering",
    short_question: "Should I order at the kiosk?",
    meaning:
      "Many cafes and casual restaurants use kiosks for ordering and payment before pickup.",
    etiquette:
      "Check whether you need a table number, keep the line moving, and ask staff politely if the screen is confusing.",
    story:
      "Kiosks reduce waiting time but can be difficult for travelers, so asking for help is normal.",
    korean_phrase: "도와주실 수 있나요?",
    pronunciation: "do-wa-ju-sil su in-na-yo",
    phrase_meaning: "Could you help me?",
    tags: ["kiosk", "ordering", "cafe", "restaurant", "payment"],
  },
  {
    object_key: "market_queue_ticket",
    place_type: "market",
    category: "market_etiquette",
    title_ko: "시장 대기표",
    title_en: "Market queue ticket",
    short_question: "Why are people taking number tickets?",
    meaning:
      "Popular stalls may use numbered tickets so the line stays fair even in a crowded market.",
    etiquette:
      "Take one ticket, stay nearby, and listen or watch for your number before ordering.",
    story:
      "The ticket system keeps busy stalls orderly without a long physical line.",
    korean_phrase: "몇 번이에요?",
    pronunciation: "myeot beo-ni-e-yo",
    phrase_meaning: "What number is it?",
    tags: ["market", "queue", "ticket", "waiting_number"],
  },
  {
    object_key: "market_cash_food",
    place_type: "market",
    category: "market_etiquette",
    title_ko: "시장 현금과 음식 예절",
    title_en: "Market cash and food manners",
    short_question: "Can I pay by card and eat while walking?",
    meaning:
      "Many market stalls accept cards, but small cash can still help at older or very small stalls.",
    etiquette:
      "Ask before paying, avoid blocking the stall while eating, and use the nearby bins or trays as directed.",
    story:
      "Traditional markets move quickly, so small courtesies help everyone share tight space.",
    korean_phrase: "카드 돼요?",
    pronunciation: "ka-deu dwae-yo",
    phrase_meaning: "Do you take cards?",
    tags: ["market", "cash", "card", "food", "manners"],
  },
  {
    object_key: "palace_photo_etiquette",
    place_type: "palace",
    category: "photo_etiquette",
    title_ko: "궁궐 사진 예절",
    title_en: "Palace photo etiquette",
    short_question: "Can I take photos here?",
    meaning:
      "Palaces welcome photos in many outdoor areas, but some interiors, ceremonies, or protected zones may restrict them.",
    etiquette:
      "Follow signs, avoid flash where restricted, and do not block paths or step over low barriers for photos.",
    story:
      "Historic sites balance beautiful travel photos with preservation and visitor flow.",
    korean_phrase: "사진 찍어도 되나요?",
    pronunciation: "sa-jin jji-geo-do dwe-na-yo",
    phrase_meaning: "May I take a photo?",
    tags: ["palace", "photo", "etiquette", "historic_site"],
  },
  {
    object_key: "hanok_resident_etiquette",
    place_type: "hanok_village",
    category: "resident_etiquette",
    title_ko: "한옥마을 주민 배려",
    title_en: "Hanok village resident etiquette",
    short_question: "Why are there quiet signs in the village?",
    meaning:
      "Some hanok villages are real residential neighborhoods, not only photo zones.",
    etiquette:
      "Keep voices low, avoid photographing private doors or windows, and stay on public paths.",
    story:
      "The best visit respects both the beauty of hanok and the privacy of people living there.",
    korean_phrase: "조용히 지나갈게요",
    pronunciation: "jo-yong-hi ji-na-gal-ge-yo",
    phrase_meaning: "I will pass quietly.",
    tags: ["hanok", "resident", "quiet", "photo", "village"],
  },
  {
    object_key: "waiting_number_ticket",
    place_type: "restaurant",
    category: "restaurant_etiquette",
    title_ko: "식당 대기번호",
    title_en: "Restaurant waiting number ticket",
    short_question: "How do waiting numbers work?",
    meaning:
      "Busy restaurants may ask guests to register or take a number before being seated.",
    etiquette:
      "Enter your party size, watch the display, and return quickly when your number is called.",
    story:
      "Number systems make busy restaurants fairer and reduce crowding at the door.",
    korean_phrase: "대기번호가 몇 번인가요?",
    pronunciation: "dae-gi-beon-ho-ga myeot beo-nin-ga-yo",
    phrase_meaning: "What waiting number am I?",
    tags: ["restaurant", "waiting_number", "queue", "ticket"],
  },
];
