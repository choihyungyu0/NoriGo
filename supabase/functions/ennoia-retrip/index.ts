type RetripRequest = {
  plan_id?: string;
  original_item_id?: string;
  user_language: string;
  current_location: string;
  original_place: string;
  original_place_type: string;
  original_place_value: string;
  scheduled_time: string;
  trigger_type: string;
  crowd_level: string;
  estimated_wait: string;
  user_preference: string;
};

type JsonRecord = Record<string, unknown>;

type KtoAlternative = {
  title: string;
  contentid: string;
  contenttypeid: string;
  addr1: string;
  firstimage: string;
  mapx?: number;
  mapy?: number;
  matched_keyword: string;
  score: number;
  distance_km?: number;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ennoia-user-id",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const requiredFields: Array<keyof RetripRequest> = [
  "user_language",
  "current_location",
  "original_place",
  "original_place_type",
  "original_place_value",
  "scheduled_time",
  "trigger_type",
  "crowd_level",
  "estimated_wait",
  "user_preference",
];

const ktoKeywordSearchUrl =
  "https://apis.data.go.kr/B551011/KorService2/searchKeyword2";
const alternativeCount = 3;

const locationHints = [
  { names: ["bukchon", "북촌"], keyword: "북촌", mapx: 126.984, mapy: 37.582 },
  { names: ["jongno", "종로"], keyword: "종로", mapx: 126.991, mapy: 37.573 },
  { names: ["ikseon", "익선동"], keyword: "익선동", mapx: 126.989, mapy: 37.573 },
  { names: ["myeongdong", "명동"], keyword: "명동", mapx: 126.985, mapy: 37.563 },
  { names: ["hongdae", "홍대"], keyword: "홍대", mapx: 126.923, mapy: 37.557 },
  { names: ["seongsu", "성수"], keyword: "성수", mapx: 127.044, mapy: 37.544 },
  { names: ["gangnam", "강남"], keyword: "강남", mapx: 127.027, mapy: 37.498 },
  { names: ["seoul", "서울"], keyword: "서울", mapx: 126.978, mapy: 37.566 },
];

export async function handleRetripRequest(request: Request): Promise<Response> {
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

  const params = bodyResult.body as RetripRequest;
  const ktoServiceKey = Deno.env.get("KTO_SERVICE_KEY")?.trim();
  let candidates: KtoAlternative[] = [];

  if (ktoServiceKey) {
    try {
      candidates = await retrieveKtoAlternatives(params, ktoServiceKey);
    } catch (error) {
      console.error(
        "KTO retrip alternative retrieval failed",
        error instanceof Error ? error.message : "unknown error",
      );
    }
  }

  if (candidates.length < alternativeCount) {
    const retrip = buildFallbackRetrip(
      params,
      ktoServiceKey
        ? "KTO OpenAPI returned fewer than 3 usable alternatives"
        : "KTO_SERVICE_KEY is missing",
    );
    return jsonResponse(await withPersistence(request, params, retrip), 200);
  }

  const alternatives = candidates.slice(0, alternativeCount);

  try {
    const ennoiaPayload = await requestEnnoiaRetrip(request, params, alternatives);
    const retrip = buildKtoRetrip(
      params,
      alternatives,
      candidates.length,
      ennoiaPayload,
    );
    return jsonResponse(await withPersistence(request, params, retrip), 200);
  } catch (error) {
    const ennoiaErrorCode = ennoiaFailureCode(error);
    console.error(
      "ennoia retrip request failed",
      error instanceof Error ? error.message : "unknown error",
    );
    const retrip = buildKtoRetrip(
      params,
      alternatives,
      candidates.length,
      null,
      ennoiaErrorCode,
    );
    return jsonResponse(await withPersistence(request, params, retrip), 200);
  }
}

if (import.meta.main) {
  Deno.serve(handleRetripRequest);
}

async function retrieveKtoAlternatives(
  params: RetripRequest,
  serviceKey: string,
): Promise<KtoAlternative[]> {
  const searches = buildSearchPlan(params);
  const byId = new Map<string, KtoAlternative>();

  for (let index = 0; index < searches.length; index += 4) {
    const batch = searches.slice(index, index + 4);
    const results = await Promise.allSettled(
      batch.map((keyword) => fetchKtoKeyword(keyword, params, serviceKey)),
    );

    results.forEach((result) => {
      if (result.status === "rejected") return;
      for (const candidate of result.value) {
        const existing = byId.get(candidate.contentid);
        if (existing) {
          existing.score = Math.max(existing.score, candidate.score);
          if (!existing.firstimage && candidate.firstimage) {
            existing.firstimage = candidate.firstimage;
          }
        } else {
          byId.set(candidate.contentid, candidate);
        }
      }
    });

    if (byId.size >= 10) break;
  }

  return [...byId.values()]
    .map((candidate) => scoreAlternative(candidate, params))
    .filter((candidate) =>
      normalize(candidate.title) !== normalize(params.original_place)
    )
    .sort((a, b) => b.score - a.score);
}

async function fetchKtoKeyword(
  keyword: string,
  params: RetripRequest,
  serviceKey: string,
): Promise<KtoAlternative[]> {
  const url = new URL(ktoKeywordSearchUrl);
  url.searchParams.set("MobileOS", "ETC");
  url.searchParams.set("MobileApp", "NoriGo");
  url.searchParams.set("_type", "json");
  url.searchParams.set("arrange", "O");
  url.searchParams.set("numOfRows", "10");
  url.searchParams.set("pageNo", "1");
  url.searchParams.set("areaCode", "1");
  url.searchParams.set("keyword", keyword);

  const key = serviceKey.includes("%") ? serviceKey : encodeURIComponent(serviceKey);
  const response = await fetch(`${url.toString()}&serviceKey=${key}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    throw new Error(`KTO returned HTTP ${response.status}`);
  }

  const decoded = await response.json();
  const items = getNested(decoded, ["response", "body", "items", "item"]);
  const records = Array.isArray(items) ? items.filter(isRecord) : isRecord(items) ? [items] : [];

  return records
    .map((record) => normalizeKtoAlternative(record, keyword))
    .filter((candidate): candidate is KtoAlternative => candidate !== null);
}

function buildSearchPlan(params: RetripRequest): string[] {
  const base = locationHintFor(params.current_location)?.keyword ?? "서울";
  const haystack = normalize(
    `${params.original_place_type} ${params.original_place_value} ${params.user_preference} ${params.trigger_type}`,
  );
  const keywords = new Set<string>();

  if (haystack.includes("cafe") || haystack.includes("dessert") || haystack.includes("카페")) {
    keywords.add(`${base} 카페`);
    keywords.add(`${base} 디저트`);
    keywords.add("익선동 카페");
    keywords.add("한옥 카페");
    keywords.add("종로 카페");
  }
  if (haystack.includes("hanok") || haystack.includes("한옥")) {
    keywords.add("북촌한옥마을");
    keywords.add("익선동");
  }
  if (haystack.includes("quiet") || haystack.includes("local")) {
    keywords.add("북촌");
    keywords.add("서촌");
    keywords.add("서울숲");
  }
  if (keywords.size === 0) {
    keywords.add(`${base} 관광`);
    keywords.add(`${base} 맛집`);
    keywords.add(`${base} 카페`);
  }

  if (haystack.includes("night") || haystack.includes("view")) {
    keywords.add(`${base} 야경`);
    keywords.add("남산");
  }
  if (haystack.includes("shop") || haystack.includes("shopping")) {
    keywords.add(`${base} 쇼핑`);
    keywords.add("시장");
  }

  keywords.add("광장시장");
  keywords.add("인사동");

  return [...keywords].slice(0, 10);
}

function normalizeKtoAlternative(
  rawItem: JsonRecord,
  keyword: string,
): KtoAlternative | null {
  const title = readString(rawItem, "title");
  const contentid = readString(rawItem, "contentid");
  if (!title || !contentid) return null;

  return {
    title,
    contentid,
    contenttypeid: readString(rawItem, "contenttypeid"),
    addr1: readString(rawItem, "addr1"),
    firstimage: readString(rawItem, "firstimage") ||
      readString(rawItem, "firstimage2"),
    mapx: readNumber(rawItem, "mapx"),
    mapy: readNumber(rawItem, "mapy"),
    matched_keyword: keyword,
    score: 0,
  };
}

function scoreAlternative(
  candidate: KtoAlternative,
  params: RetripRequest,
): KtoAlternative {
  const base = locationHintFor(params.current_location);
  const preference = normalize(
    `${params.original_place_type} ${params.original_place_value} ${params.user_preference}`,
  );
  let score = 40;

  if (candidate.firstimage) score += 8;
  if (candidate.addr1.includes("서울")) score += 8;
  if (candidate.contenttypeid === "39") score += 14;
  if (candidate.contenttypeid === "12") score += 7;
  if (preference.includes("cafe") && candidate.title.includes("카페")) score += 16;
  if (preference.includes("dessert") && candidate.matched_keyword.includes("디저트")) {
    score += 10;
  }
  if (preference.includes("hanok") && (
    candidate.title.includes("한옥") ||
    candidate.addr1.includes("종로") ||
    candidate.matched_keyword.includes("한옥")
  )) {
    score += 8;
  }
  if (preference.includes("quiet") && !candidate.title.includes("시장")) {
    score += 5;
  }

  let distance: number | undefined;
  if (
    base &&
    candidate.mapx !== undefined &&
    candidate.mapy !== undefined
  ) {
    distance = haversineKm(base.mapy, base.mapx, candidate.mapy, candidate.mapx);
    if (distance <= 1.5) score += 12;
    else if (distance <= 3) score += 8;
    else if (distance <= 6) score += 4;
    else score -= 4;
  }

  return {
    ...candidate,
    score: Math.max(1, Math.round(score)),
    distance_km: distance,
  };
}

async function requestEnnoiaRetrip(
  request: Request,
  params: RetripRequest,
  alternatives: KtoAlternative[],
): Promise<JsonRecord | null> {
  const endpoint = Deno.env.get("ENNOIA_API_ENDPOINT")?.trim();
  const project = Deno.env.get("ENNOIA_PROJECT")?.trim();
  const apiKey = Deno.env.get("ENNOIA_API_KEY")?.trim();
  const retripApiHash = Deno.env.get("ENNOIA_RETRIP_API_HASH")?.trim();
  const hash = retripApiHash || Deno.env.get("ENNOIA_RETRIP_HASH")?.trim();

  if (!endpoint || !project || !apiKey || !hash) {
    throw new Error("ennoia Edge Function secrets are missing");
  }

  const ktoAlternatives = alternatives.map(toEnnoiaAlternative);
  const payload = {
    hash,
    params: buildRetripEnnoiaParams(params, ktoAlternatives),
    messages: [
      {
        role: "user",
        content: buildRetripEnnoiaPrompt(params, ktoAlternatives),
      },
    ],
  };
  const ennoiaUserId = request.headers.get("x-ennoia-user-id")?.trim() ||
    Deno.env.get("ENNOIA_USER_ID")?.trim() ||
    "norigo-demo-user";

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      project,
      apiKey,
      "X-ENNOIA-USER-ID": ennoiaUserId,
      "Content-Type": "application/json; charset=utf-8",
    },
    body: JSON.stringify(payload),
  });

  const text = await response.text();
  if (!response.ok) {
    console.error("ennoia retrip HTTP failure", {
      ennoia_status: response.status,
      ennoia_status_text: response.statusText,
      ennoia_body_preview: safeBodyPreview(text),
      hasApiKey: Boolean(apiKey),
      hasProject: Boolean(project),
      hasEndpoint: Boolean(endpoint),
      hasRetripApiHash: Boolean(retripApiHash),
      hasRetripHash: Boolean(hash),
      hashSuffix: hash.slice(-8),
    });
    throw new EnnoiaRetripError(
      `ennoia returned HTTP ${response.status}`,
      response.status,
      readEnnoiaErrorCode(text),
    );
  }

  return parseAgentPayload(text);
}

function buildRetripEnnoiaParams(
  params: RetripRequest,
  ktoAlternatives: JsonRecord[],
): JsonRecord {
  return {
    ...params,
    KTO_DATA: JSON.stringify(ktoAlternatives),
  };
}

function buildRetripEnnoiaPrompt(
  params: RetripRequest,
  ktoAlternatives: JsonRecord[],
): string {
  return [
    "Use only the provided KTO_DATA.",
    "Do not call tools.",
    "Do not invent place names.",
    "Do not invent kto_content_id.",
    "Return valid JSON only.",
    "Return exactly 3 alternatives.",
    "Each alternative must preserve the selected KTO contentid as kto_content_id.",
    "If a field is unknown, use an empty string.",
    JSON.stringify({
      user_request: params,
      KTO_DATA: ktoAlternatives,
      response_shape: {
        source_type: "kto_openapi_ennoia",
        alert_message: "short alert message",
        foreigner_queue_tip: "practical queue tip",
        recommended_action: "short action",
        alternatives: [
          {
            place_name: "KTO title",
            kto_content_id: "contentid from KTO_DATA",
            recommendation_copy: "why this alternative fits",
            reason: "short reason",
            walking_time: "5 min walk",
            diversity_score: 90,
            crowd_level: "Low",
          },
        ],
      },
    }),
  ].join("\n");
}

function buildKtoRetrip(
  params: RetripRequest,
  alternatives: KtoAlternative[],
  candidateCount: number,
  ennoiaPayload: JsonRecord | null,
  ennoiaErrorCode?: string | null,
): JsonRecord {
  const payloadAlternatives = readPayloadAlternatives(ennoiaPayload);
  const usedEnnoia = payloadAlternatives.length >= alternativeCount;
  const sourceType = usedEnnoia ? "kto_openapi_ennoia" : "kto_openapi_basic";
  const sourceBadge = usedEnnoia ? "KTO OpenAPI + ennoia" : "KTO OpenAPI";
  const sourceNote = usedEnnoia
    ? "KTO OpenAPI data succeeded; ennoia generated the Re-Trip recommendation copy from selected KTO_DATA."
    : "KTO OpenAPI data succeeded; ennoia generation failed and basic descriptions were generated by the backend.";

  return {
    source: sourceType,
    source_type: sourceType,
    source_badge: sourceBadge,
    source_note: sourceNote,
    fallback: false,
    ennoia_fallback: !usedEnnoia,
    ...(usedEnnoia ? {} : { ennoia_error_code: ennoiaErrorCode ?? "ennoia_generation_failed" }),
    candidate_count: candidateCount,
    plan_id: params.plan_id ?? null,
    original_item_id: params.original_item_id ?? null,
    id: `kto-retrip-${shortHash(
      `${params.current_location}|${params.original_place}|${params.user_preference}`,
    )}`,
    originalPlace: params.original_place,
    original_place: params.original_place,
    scheduledTime: params.scheduled_time,
    scheduled_time: params.scheduled_time,
    crowdLevel: params.crowd_level,
    crowd_level: params.crowd_level,
    estimatedWait: params.estimated_wait,
    estimated_wait: params.estimated_wait,
    alertMessage:
      `${params.original_place} may become very busy within 30 minutes.`,
    alert_message:
      `${params.original_place} may become very busy within 30 minutes.`,
    foreignerQueueTip:
      "Even if no visible line, app-based queues may already be full.",
    foreigner_queue_tip:
      "Even if no visible line, app-based queues may already be full.",
    recommended_action: `Switch to ${alternatives[0]?.title ?? "a lower-crowd nearby stop"}`,
    persisted: false,
    alternatives: alternatives.slice(0, alternativeCount).map((candidate, index) =>
      alternativeFromCandidate(
        candidate,
        usedEnnoia
          ? payloadAlternatives.find((item) => itemMatchesCandidate(item, candidate)) ??
            payloadAlternatives[index]
          : undefined,
      )
    ),
  };
}

function buildFallbackRetrip(params: RetripRequest, reason: string): JsonRecord {
  return {
    source: "kto_openapi_fallback",
    source_type: "kto_openapi_fallback",
    source_badge: "Demo fallback",
    fallback: true,
    source_note:
      `Demo fallback was used because ${reason}. Real KTO OpenAPI success is not claimed for this response.`,
    plan_id: params.plan_id ?? null,
    original_item_id: params.original_item_id ?? null,
    recommended_action: "Review demo fallback alternatives.",
    persisted: false,
    id: "cafe-arte-crowd-alert",
    originalPlace: params.original_place,
    original_place: params.original_place,
    scheduledTime: params.scheduled_time,
    scheduled_time: params.scheduled_time,
    crowdLevel: params.crowd_level,
    crowd_level: params.crowd_level,
    estimatedWait: params.estimated_wait,
    estimated_wait: params.estimated_wait,
    alertMessage:
      `${params.original_place} may become very busy within 30 minutes.`,
    foreignerQueueTip:
      "Even if no visible line, app-based queues may already be full.",
    alternatives: [
      {
        id: "cafe-owall",
        name: "Cafe Owall",
        description: "Demo fallback dessert option while live KTO data is unavailable.",
        recommendation_copy: "Demo fallback dessert option while live KTO data is unavailable.",
        walkingTime: "5 min walk",
        distance: "5 min walk",
        diversityScore: 92,
        crowdLevel: "Low",
        kto_content_id: "",
      },
      {
        id: "seosullan-small-book-cafe",
        name: "Seosullan Small Book Cafe",
        description: "Demo fallback quiet cafe while live KTO data is unavailable.",
        recommendation_copy: "Demo fallback quiet cafe while live KTO data is unavailable.",
        walkingTime: "7 min walk",
        distance: "7 min walk",
        diversityScore: 88,
        crowdLevel: "Low",
        kto_content_id: "",
      },
      {
        id: "yunsul-bakery",
        name: "Yunsul Bakery",
        description: "Demo fallback bakery while live KTO data is unavailable.",
        recommendation_copy: "Demo fallback bakery while live KTO data is unavailable.",
        walkingTime: "8 min walk",
        distance: "8 min walk",
        diversityScore: 90,
        crowdLevel: "Low",
        kto_content_id: "",
      },
    ],
  };
}

function alternativeFromCandidate(
  candidate: KtoAlternative,
  ennoiaItem: JsonRecord | undefined,
): JsonRecord {
  const name = readPayloadString(ennoiaItem, ["name", "place_name", "placeName"]) ||
    candidate.title;
  const description = readPayloadString(ennoiaItem, [
    "description",
    "reason",
    "value",
  ]) || descriptionFor(candidate);
  const walkingTime = readPayloadString(ennoiaItem, [
    "walkingTime",
    "walking_time",
    "distance",
  ]) || walkingTimeFor(candidate.distance_km);
  const diversityScore = readPayloadNumber(ennoiaItem, [
    "diversityScore",
    "diversity_score",
    "score",
  ]) ?? diversityScoreFor(candidate.score);
  const crowdLevel = readPayloadString(ennoiaItem, [
    "crowdLevel",
    "crowd_level",
    "crowd",
  ]) || "Low";

  return {
    id: slug(name),
    name,
    place_name: name,
    description,
    recommendation_copy: readPayloadString(ennoiaItem, [
      "recommendation_copy",
      "recommendationCopy",
      "copy",
    ]) || description,
    walkingTime,
    walking_time: walkingTime,
    distance: walkingTime,
    diversityScore,
    diversity_score: diversityScore,
    crowdLevel,
    crowd_level: crowdLevel,
    contentId: candidate.contentid,
    content_id: candidate.contentid,
    kto_content_id: candidate.contentid,
    contentTypeId: candidate.contenttypeid,
    content_type_id: candidate.contenttypeid,
    firstimage: candidate.firstimage,
    image_url: candidate.firstimage,
    imageUrl: candidate.firstimage,
    addr1: candidate.addr1,
    address: candidate.addr1,
    mapx: candidate.mapx,
    mapy: candidate.mapy,
  };
}

function descriptionFor(candidate: KtoAlternative): string {
  if (candidate.contenttypeid === "39" || candidate.title.includes("카페")) {
    return "KTO-listed food or cafe option near the current route.";
  }
  if (candidate.title.includes("한옥") || candidate.addr1.includes("종로")) {
    return "KTO-listed nearby stop that keeps the hanok-area route compact.";
  }
  return "KTO-listed nearby alternative selected to reduce crowd friction.";
}

function walkingTimeFor(distanceKm: number | undefined): string {
  if (distanceKm === undefined) return "8 min walk";
  if (distanceKm <= 0.8) return "5 min walk";
  if (distanceKm <= 1.4) return "8 min walk";
  if (distanceKm <= 2.2) return "12 min walk";
  return "15 min walk";
}

function diversityScoreFor(score: number): number {
  return Math.max(82, Math.min(96, Math.round(score)));
}

function toEnnoiaAlternative(candidate: KtoAlternative): JsonRecord {
  return {
    title: candidate.title,
    contentid: candidate.contentid,
    contenttypeid: candidate.contenttypeid,
    addr1: candidate.addr1,
    firstimage: candidate.firstimage,
    mapx: candidate.mapx,
    mapy: candidate.mapy,
    matched_keyword: candidate.matched_keyword,
    score: candidate.score,
    distance_km: candidate.distance_km,
  };
}

function parseAgentPayload(text: string): JsonRecord | null {
  try {
    const decoded = JSON.parse(text);
    const content = extractOpenAiContent(decoded);
    if (typeof content === "string") {
      return parseJsonLike(content);
    }
    if (isRecord(content)) return content;
    if (isRecord(decoded)) return decoded;
  } catch (_) {
    return parseJsonLike(text);
  }
  return null;
}

function extractOpenAiContent(decoded: unknown): unknown {
  if (!isRecord(decoded)) return null;
  if (typeof decoded.output_text === "string") return decoded.output_text;
  if (typeof decoded.content === "string") return decoded.content;
  if (isRecord(decoded.content)) return decoded.content;
  if (isRecord(decoded.data)) return decoded.data;
  if (isRecord(decoded.message)) {
    const messageContent = decoded.message.content;
    if (typeof messageContent === "string") return messageContent;
    if (Array.isArray(messageContent)) return textFromContentParts(messageContent);
  }
  const choices = decoded.choices;
  if (!Array.isArray(choices) || choices.length === 0) return null;
  const first = choices[0];
  if (!isRecord(first)) return null;
  if (typeof first.text === "string") return first.text;
  if (isRecord(first.message) && typeof first.message.content === "string") {
    return first.message.content;
  }
  if (isRecord(first.message) && Array.isArray(first.message.content)) {
    return textFromContentParts(first.message.content);
  }
  return null;
}

function textFromContentParts(parts: unknown[]): string {
  return parts.map((part) => {
    if (typeof part === "string") return part;
    if (!isRecord(part)) return "";
    if (typeof part.text === "string") return part.text;
    if (typeof part.content === "string") return part.content;
    return "";
  }).filter(Boolean).join("\n");
}

function parseJsonLike(content: string): JsonRecord | null {
  const trimmed = stripJsonFence(content.trim());
  if (!trimmed) return null;

  try {
    const decoded = JSON.parse(trimmed);
    return isRecord(decoded) ? decoded : null;
  } catch (_) {
    const objectStart = trimmed.indexOf("{");
    const objectEnd = trimmed.lastIndexOf("}");
    if (objectStart === -1 || objectEnd <= objectStart) return null;
    try {
      const decoded = JSON.parse(trimmed.slice(objectStart, objectEnd + 1));
      return isRecord(decoded) ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

function stripJsonFence(content: string): string {
  return content
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();
}

function readPayloadAlternatives(payload: JsonRecord | null): JsonRecord[] {
  if (!payload) return [];
  const nested = firstRecord(payload, ["retrip", "reTrip", "result", "data"]) ?? payload;
  for (const key of ["alternatives", "places", "recommendations", "items"]) {
    const value = nested[key];
    if (Array.isArray(value)) return value.filter(isRecord);
  }
  return [];
}

function itemMatchesCandidate(item: JsonRecord, candidate: KtoAlternative): boolean {
  const id = readPayloadString(item, [
    "content_id",
    "contentId",
    "kto_content_id",
    "contentid",
  ]);
  return id === candidate.contentid;
}

async function withPersistence(
  request: Request,
  params: RetripRequest,
  retrip: JsonRecord,
): Promise<JsonRecord> {
  const retripEventId = await persistRetripEvent(request, params, retrip);
  return {
    ...retrip,
    persisted: Boolean(retripEventId),
    retripEventId: retripEventId ?? null,
    retrip_event_id: retripEventId ?? null,
  };
}

async function persistRetripEvent(
  request: Request,
  params: RetripRequest,
  retrip: JsonRecord,
): Promise<string | null> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) return null;

  const row = {
    user_id: readJwtSub(request),
    plan_id: uuidOrNull(params.plan_id),
    original_item_id: params.original_item_id ?? null,
    original_place_name: params.original_place,
    trigger_type: params.trigger_type,
    crowd_level: params.crowd_level,
    estimated_wait: params.estimated_wait,
    source_type: readPayloadString(retrip, ["source_type", "source"]) ??
      "kto_openapi_basic",
    source_badge: readPayloadString(retrip, ["source_badge"]),
    recommended_action: readPayloadString(retrip, ["recommended_action"]),
    raw_json: retrip,
  };

  try {
    const response = await fetch(
      `${supabaseUrl.replace(/\/+$/, "")}/rest/v1/retrip_events`,
      {
        method: "POST",
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json; charset=utf-8",
          Prefer: "return=representation",
        },
        body: JSON.stringify(row),
      },
    );

    const text = await response.text();
    if (!response.ok) {
      console.error("retrip event persistence failed", {
        status: response.status,
        body_preview: safeBodyPreview(text),
      });
      return null;
    }

    const decoded = JSON.parse(text);
    if (Array.isArray(decoded) && isRecord(decoded[0])) {
      const id = decoded[0].id;
      return typeof id === "string" ? id : null;
    }
  } catch (error) {
    console.error(
      "retrip event persistence failed",
      error instanceof Error ? error.message : "unknown error",
    );
  }
  return null;
}

function readJwtSub(request: Request): string | null {
  const authorization = request.headers.get("authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "").trim();
  const payload = token.split(".")[1];
  if (!payload) return null;

  try {
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, "=");
    const decoded = JSON.parse(atob(padded));
    return typeof decoded.sub === "string" && decoded.sub ? decoded.sub : null;
  } catch (_) {
    return null;
  }
}

function uuidOrNull(value: string | undefined): string | null {
  if (!value) return null;
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    .test(value)
    ? value
    : null;
}

function ennoiaFailureCode(error: unknown): string {
  if (error instanceof EnnoiaRetripError && error.errorCode) {
    return error.errorCode;
  }
  const message = error instanceof Error ? error.message : "";
  if (message.toLowerCase().includes("mcp connection")) {
    return "MCP_CONNECTION_REQUIRED";
  }
  return "ennoia_generation_failed";
}

function safeBodyPreview(text: string): string {
  return text
    .replace(/Bearer\s+[A-Za-z0-9._-]+/g, "Bearer [redacted]")
    .replace(
      /("?(?:apiKey|apikey|authorization|token)"?\s*[:=]\s*")([^"]+)(")/gi,
      "$1[redacted]$3",
    )
    .slice(0, 320);
}

function readEnnoiaErrorCode(text: string): string | null {
  try {
    const decoded = JSON.parse(text);
    if (!isRecord(decoded)) return null;
    const errorCode = decoded.error_code;
    if (errorCode === 40065 || errorCode === "40065") {
      return "MCP_CONNECTION_REQUIRED";
    }
    if (typeof errorCode === "string" && errorCode.trim()) {
      return errorCode.trim();
    }
    const errorType = decoded.error_type;
    if (typeof errorType === "string" && errorType.trim()) {
      return errorType.trim();
    }
    const message = decoded.message;
    if (
      typeof message === "string" &&
      message.toLowerCase().includes("mcp connection")
    ) {
      return "MCP_CONNECTION_REQUIRED";
    }
  } catch (_) {
    return null;
  }
  return null;
}

class EnnoiaRetripError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly errorCode: string | null,
  ) {
    super(message);
    this.name = "EnnoiaRetripError";
  }
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

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function locationHintFor(value: string) {
  const normalized = normalize(value);
  return locationHints.find((hint) =>
    hint.names.some((name) => normalized.includes(normalize(name)))
  );
}

function normalize(value: string): string {
  return value.toLowerCase().replace(/\s+/g, " ").trim();
}

function readString(record: JsonRecord, key: string): string {
  const value = record[key];
  return typeof value === "string" ? value.trim() : "";
}

function readNumber(record: JsonRecord, key: string): number | undefined {
  const value = record[key];
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

function readPayloadString(
  record: JsonRecord | undefined | null,
  keys: string[],
): string | null {
  if (!record) return null;
  for (const key of keys) {
    const value = record[key];
    if (typeof value === "string" && value.trim()) return value.trim();
    if (typeof value === "number") return String(value);
  }
  return null;
}

function readPayloadNumber(
  record: JsonRecord | undefined | null,
  keys: string[],
): number | null {
  if (!record) return null;
  for (const key of keys) {
    const value = record[key];
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string") {
      const parsed = Number.parseInt(value, 10);
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return null;
}

function firstRecord(record: JsonRecord, keys: string[]): JsonRecord | null {
  for (const key of keys) {
    const value = record[key];
    if (isRecord(value)) return value;
  }
  return null;
}

function getNested(value: unknown, path: string[]): unknown {
  let current = value;
  for (const key of path) {
    if (!isRecord(current)) return undefined;
    current = current[key];
  }
  return current;
}

function isRecord(value: unknown): value is JsonRecord {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const earthKm = 6371;
  const dLat = degreesToRadians(lat2 - lat1);
  const dLon = degreesToRadians(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(degreesToRadians(lat1)) *
      Math.cos(degreesToRadians(lat2)) *
      Math.sin(dLon / 2) ** 2;
  return earthKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function degreesToRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

function slug(value: string): string {
  const ascii = value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return ascii || `place-${shortHash(value)}`;
}

function shortHash(value: string): string {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = ((hash << 5) - hash + value.charCodeAt(index)) | 0;
  }
  return Math.abs(hash).toString(36);
}
