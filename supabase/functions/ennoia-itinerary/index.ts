export type ItineraryRequest = {
  preferred_language?: string;
  user_language: string;
  destination?: string;
  trip_days: string;
  base_location: string;
  travel_date: string;
  interests: string;
  companion_type: string;
  crowd_preference: string;
  food_needs?: string;
};

export type KeywordSearch = {
  interest: string;
  keyword: string;
};

export type KtoCandidate = {
  title: string;
  contentid: string;
  contenttypeid: string;
  addr1: string;
  firstimage: string;
  mapx?: number;
  mapy?: number;
  matched_interest: string;
  matched_interests: string[];
  matched_keywords: string[];
  candidate_score: number;
  category: string;
  area_key: string;
  distance_km?: number;
};

type JsonRecord = Record<string, unknown>;

export type EnnoiaFailureDetails = {
  ennoia_status?: number;
  ennoia_status_text?: string;
  ennoia_body_preview?: string;
  ennoia_error_code?: string;
  hasApiKey: boolean;
  hasProject: boolean;
  hasEndpoint: boolean;
  hasItineraryApiHash: boolean;
  hashSuffix: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-ennoia-user-id",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const requiredFields: Array<keyof ItineraryRequest> = [
  "user_language",
  "trip_days",
  "base_location",
  "travel_date",
  "interests",
  "companion_type",
  "crowd_preference",
];

const ktoKeywordSearchUrl =
  "https://apis.data.go.kr/B551011/KorService2/searchKeyword2";
const targetCandidateCount = 20;
const routeItemCount = 5;
const maxKeywordSearches = 24;
const ennoiaBodyPreviewLength = 500;

const interestKeywords: Record<string, string[]> = {
  "Palace": ["경복궁", "창덕궁", "덕수궁", "창경궁"],
  "Hanok village": ["북촌한옥마을", "익선동", "은평한옥마을", "남산골한옥마을"],
  "Traditional market": ["광장시장", "남대문시장", "망원시장", "통인시장"],
  "Dessert cafe": ["익선동 카페", "명동 카페", "성수 카페", "연남동 카페"],
  "Photo spot": ["경복궁", "익선동", "남산서울타워", "동대문디자인플라자"],
  "Night view": ["남산서울타워", "낙산공원", "한강공원", "석촌호수"],
  "Shopping": ["명동거리", "성수 편집샵", "더현대 서울", "홍대거리"],
  "K-pop": ["하이브 인사이트", "홍대", "명동", "강남"],
  "Local food": ["광장시장", "망원시장", "남대문시장", "을지로"],
  "Museum": ["국립중앙박물관", "국립고궁박물관", "서울역사박물관", "대한민국역사박물관"],
  "Nature": ["서울숲", "낙산공원", "한강공원", "북서울꿈의숲"],
  "Wellness": ["서울숲", "한강공원", "북악산", "스파"],
  "Cafe": ["성수 카페", "연남동 카페", "익선동 카페", "망원동 카페"],
  "Culture": ["인사동", "국립중앙박물관", "예술의전당", "세종문화회관"],
  "Family": ["어린이대공원", "서울대공원", "롯데월드", "서울식물원"],
  "Couple": ["남산서울타워", "석촌호수", "연남동 카페", "반포한강공원"],
  "Solo": ["경복궁", "서울책보고", "망원시장", "서울숲"],
  "Quiet": ["서울숲", "북서울꿈의숲", "국립중앙박물관", "창덕궁"],
};

const interestAliases = new Map<string, string>([
  ["palace", "Palace"],
  ["palaces", "Palace"],
  ["hanok", "Hanok village"],
  ["hanok village", "Hanok village"],
  ["traditional market", "Traditional market"],
  ["market", "Traditional market"],
  ["dessert cafe", "Dessert cafe"],
  ["dessert", "Dessert cafe"],
  ["photo spot", "Photo spot"],
  ["photo", "Photo spot"],
  ["night view", "Night view"],
  ["night", "Night view"],
  ["shopping", "Shopping"],
  ["k pop", "K-pop"],
  ["k-pop", "K-pop"],
  ["kpop", "K-pop"],
  ["local food", "Local food"],
  ["food", "Local food"],
  ["museum", "Museum"],
  ["museums", "Museum"],
  ["nature", "Nature"],
  ["wellness", "Wellness"],
  ["cafe", "Cafe"],
  ["coffee", "Cafe"],
  ["culture", "Culture"],
  ["family", "Family"],
  ["couple", "Couple"],
  ["solo", "Solo"],
  ["quiet", "Quiet"],
]);

const baseLocations = [
  { names: ["myeongdong", "명동"], keyword: "명동", mapx: 126.985, mapy: 37.563 },
  { names: ["hongdae", "홍대"], keyword: "홍대", mapx: 126.923, mapy: 37.557 },
  {
    names: ["seoul station", "서울역"],
    keyword: "서울역",
    mapx: 126.972,
    mapy: 37.554,
  },
  { names: ["jongno", "종로"], keyword: "종로", mapx: 126.991, mapy: 37.573 },
  { names: ["gangnam", "강남"], keyword: "강남", mapx: 127.027, mapy: 37.498 },
  { names: ["seongsu", "성수"], keyword: "성수", mapx: 127.044, mapy: 37.544 },
  { names: ["itaewon", "이태원"], keyword: "이태원", mapx: 126.994, mapy: 37.534 },
];

const fallbackCandidates: KtoCandidate[] = [
  fallbackCandidate("Gyeongbokgung Palace", "fallback-gyeongbokgung", "12", "서울 종로구 사직로", "Palace", "palace", 126.977, 37.579),
  fallbackCandidate("Bukchon Hanok Village", "fallback-bukchon", "12", "서울 종로구 계동길", "Hanok village", "hanok", 126.984, 37.582),
  fallbackCandidate("Gwangjang Market", "fallback-gwangjang", "38", "서울 종로구 창경궁로", "Traditional market", "market", 127.001, 37.57),
  fallbackCandidate("Myeongdong Street", "fallback-myeongdong", "38", "서울 중구 명동길", "Shopping", "shopping", 126.985, 37.563),
  fallbackCandidate("N Seoul Tower", "fallback-n-seoul-tower", "12", "서울 용산구 남산공원길", "Night view", "night_view", 126.988, 37.551),
  fallbackCandidate("Seoul Forest", "fallback-seoul-forest", "12", "서울 성동구 뚝섬로", "Nature", "nature", 127.037, 37.544),
  fallbackCandidate("National Museum of Korea", "fallback-national-museum", "14", "서울 용산구 서빙고로", "Museum", "museum", 126.98, 37.523),
  fallbackCandidate("Seongsu Cafe Street", "fallback-seongsu-cafe", "39", "서울 성동구 성수이로", "Cafe", "cafe", 127.054, 37.543),
  fallbackCandidate("Hongdae Street", "fallback-hongdae", "12", "서울 마포구 홍익로", "K-pop", "kpop", 126.923, 37.557),
  fallbackCandidate("The Hyundai Seoul", "fallback-the-hyundai", "38", "서울 영등포구 여의대로", "Shopping", "shopping", 126.929, 37.526),
  fallbackCandidate("Ikseon-dong Cafe Alley", "fallback-ikseon", "39", "서울 종로구 수표로", "Dessert cafe", "cafe", 126.989, 37.573),
  fallbackCandidate("Banpo Hangang Park", "fallback-banpo", "12", "서울 서초구 신반포로", "Couple", "night_view", 126.995, 37.51),
];

export async function handleItineraryRequest(request: Request): Promise<Response> {
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

  const params = bodyResult.body as ItineraryRequest;
  const ktoServiceKey = Deno.env.get("KTO_SERVICE_KEY")?.trim();

  if (!ktoServiceKey) {
    return jsonResponse(
      buildFallbackItinerary(params, "KTO_SERVICE_KEY is missing"),
      200,
    );
  }

  let candidates: KtoCandidate[] = [];
  try {
    candidates = await retrieveKtoCandidates(params, ktoServiceKey);
  } catch (error) {
    console.error(
      "KTO itinerary candidate retrieval failed",
      error instanceof Error ? error.message : "unknown error",
    );
    return jsonResponse(
      buildFallbackItinerary(params, "KTO OpenAPI request failed"),
      200,
    );
  }

  if (candidates.length < routeItemCount) {
    return jsonResponse(
      buildFallbackItinerary(
        params,
        `KTO OpenAPI returned fewer than ${routeItemCount} usable candidates`,
      ),
      200,
    );
  }

  const route = selectRoute(candidates, params);

  try {
    const ennoiaPayload = await requestEnnoiaItinerary(
      request,
      params,
      route,
    );
    return jsonResponse(
      buildKtoEnnoiaItinerary(params, route, candidates.length, ennoiaPayload),
      200,
    );
  } catch (error) {
    const failureDetails = ennoiaFailureDetailsFromError(error);
    logEnnoiaFailure(failureDetails);
    return jsonResponse(
      buildKtoDirectItinerary(params, route, candidates.length, failureDetails),
      200,
    );
  }
}

if (import.meta.main) {
  Deno.serve(handleItineraryRequest);
}

async function retrieveKtoCandidates(
  params: ItineraryRequest,
  serviceKey: string,
): Promise<KtoCandidate[]> {
  const searches = buildKeywordSearchPlan(params);
  const candidatesById = new Map<string, KtoCandidate>();
  let successfulCalls = 0;
  let failedCalls = 0;

  for (let index = 0; index < searches.length; index += 4) {
    const batch = searches.slice(index, index + 4);
    const results = await Promise.allSettled(
      batch.map((search) => fetchKtoKeyword(search, params, serviceKey)),
    );

    results.forEach((result, resultIndex) => {
      if (result.status === "rejected") {
        failedCalls += 1;
        console.warn(
          "KTO keyword search failed",
          batch[resultIndex].keyword,
          result.reason instanceof Error ? result.reason.message : "unknown",
        );
        return;
      }

      successfulCalls += 1;
      for (const rawItem of result.value) {
        const candidate = normalizeKtoCandidate(rawItem, batch[resultIndex]);
        if (!candidate) continue;

        const existing = candidatesById.get(candidate.contentid);
        if (existing) {
          mergeCandidate(existing, candidate);
        } else {
          candidatesById.set(candidate.contentid, candidate);
        }
      }
    });

    if (
      candidatesById.size >= targetCandidateCount &&
      index + batch.length >= Math.min(searches.length, 12)
    ) {
      break;
    }
  }

  if (successfulCalls === 0 && failedCalls > 0) {
    throw new Error("all KTO keyword searches failed");
  }

  return scoreCandidates([...candidatesById.values()], params)
    .sort((a, b) => b.candidate_score - a.candidate_score);
}

async function fetchKtoKeyword(
  search: KeywordSearch,
  params: ItineraryRequest,
  serviceKey: string,
): Promise<JsonRecord[]> {
  const url = new URL(ktoKeywordSearchUrl);
  url.searchParams.set("MobileOS", "ETC");
  url.searchParams.set("MobileApp", "NoriGo");
  url.searchParams.set("_type", "json");
  url.searchParams.set("arrange", "O");
  url.searchParams.set("numOfRows", "10");
  url.searchParams.set("pageNo", "1");
  url.searchParams.set("keyword", search.keyword);
  if (isSeoulBase(params.base_location)) {
    url.searchParams.set("areaCode", "1");
  }

  const key = serviceKey.includes("%") ? serviceKey : encodeURIComponent(serviceKey);
  const response = await fetch(`${url.toString()}&serviceKey=${key}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    throw new Error(`KTO returned HTTP ${response.status}`);
  }

  const decoded = await response.json();
  const items = getNested(decoded, ["response", "body", "items", "item"]);
  if (Array.isArray(items)) {
    return items.filter(isRecord);
  }
  if (isRecord(items)) {
    return [items];
  }
  return [];
}

export function buildKeywordSearchPlan(params: ItineraryRequest): KeywordSearch[] {
  const labels = resolveInterestLabels(params);
  const searches: KeywordSearch[] = [];
  const seenKeywords = new Set<string>();

  for (const label of labels) {
    for (const keyword of interestKeywords[label] ?? []) {
      if (seenKeywords.has(keyword)) continue;
      searches.push({ interest: label, keyword });
      seenKeywords.add(keyword);
    }
  }

  const baseKeyword = baseKeywordFor(params.base_location);
  if (baseKeyword && !seenKeywords.has(baseKeyword)) {
    searches.push({ interest: "Base location", keyword: baseKeyword });
    seenKeywords.add(baseKeyword);
  }

  if (searches.length === 0) {
    for (const keyword of ["경복궁", "북촌한옥마을", "광장시장", "서울숲", "남산서울타워"]) {
      searches.push({ interest: "Culture", keyword });
    }
  }

  return searches.slice(0, maxKeywordSearches);
}

function resolveInterestLabels(params: ItineraryRequest): string[] {
  const values = [
    ...splitPreferenceText(params.interests),
    params.companion_type,
    params.crowd_preference,
  ];
  const labels: string[] = [];

  for (const value of values) {
    const normalized = normalizePreference(value);
    if (!normalized) continue;

    for (const [alias, label] of interestAliases) {
      if (normalized === alias || normalized.includes(alias)) {
        if (!labels.includes(label)) labels.push(label);
      }
    }
  }

  return labels;
}

function splitPreferenceText(value: string): string[] {
  return value
    .split(/[,;/|+]|\band\b/gi)
    .map((part) => part.trim())
    .filter((part) => part.length > 0);
}

function normalizePreference(value: string): string {
  return value
    .toLowerCase()
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function normalizeKtoCandidate(
  rawItem: JsonRecord,
  search: KeywordSearch,
): KtoCandidate | null {
  const title = readString(rawItem, "title");
  const contentid = readString(rawItem, "contentid");
  if (!title || !contentid) return null;

  const contenttypeid = readString(rawItem, "contenttypeid");
  const addr1 = readString(rawItem, "addr1");
  const firstimage = readString(rawItem, "firstimage") ||
    readString(rawItem, "firstimage2");
  const matchedInterests = [search.interest];
  const candidate: KtoCandidate = {
    title,
    contentid,
    contenttypeid,
    addr1,
    firstimage,
    mapx: readNumber(rawItem, "mapx"),
    mapy: readNumber(rawItem, "mapy"),
    matched_interest: search.interest,
    matched_interests: matchedInterests,
    matched_keywords: [search.keyword],
    candidate_score: 0,
    category: categoryForCandidate(search.interest, contenttypeid, title),
    area_key: areaKey(addr1),
  };
  return candidate;
}

function mergeCandidate(existing: KtoCandidate, incoming: KtoCandidate): void {
  for (const interest of incoming.matched_interests) {
    if (!existing.matched_interests.includes(interest)) {
      existing.matched_interests.push(interest);
    }
  }
  for (const keyword of incoming.matched_keywords) {
    if (!existing.matched_keywords.includes(keyword)) {
      existing.matched_keywords.push(keyword);
    }
  }
  existing.matched_interest = existing.matched_interests[0] ?? incoming.matched_interest;
  if (!existing.firstimage && incoming.firstimage) existing.firstimage = incoming.firstimage;
  if (!existing.addr1 && incoming.addr1) existing.addr1 = incoming.addr1;
  if (!existing.contenttypeid && incoming.contenttypeid) {
    existing.contenttypeid = incoming.contenttypeid;
  }
}

export function scoreCandidates(
  candidates: KtoCandidate[],
  params: ItineraryRequest,
): KtoCandidate[] {
  const preferredLabels = resolveInterestLabels(params);
  const base = baseCoordinatesFor(params.base_location);
  const crowdPreference = normalizePreference(params.crowd_preference);

  return candidates.map((candidate) => {
    const category = categoryForCandidate(
      candidate.matched_interest,
      candidate.contenttypeid,
      candidate.title,
    );
    let score = 0;

    const matchedPreferred = candidate.matched_interests.filter((interest) =>
      preferredLabels.includes(interest)
    );
    score += Math.min(matchedPreferred.length, 2) * 22;
    score += keywordTitleScore(candidate, preferredLabels);
    score += contentTypeScore(candidate.contenttypeid, matchedPreferred, category);
    if (candidate.firstimage) score += 8;
    if (candidate.addr1) score += 5;
    if (isSeoulBase(params.base_location) && candidate.addr1.includes("서울")) {
      score += 8;
    }
    score += crowdPreferenceScore(crowdPreference, category);

    let distance: number | undefined;
    if (base && candidate.mapx !== undefined && candidate.mapy !== undefined) {
      distance = haversineKm(base.mapy, base.mapx, candidate.mapy, candidate.mapx);
      score += distanceScore(distance);
    }

    return {
      ...candidate,
      candidate_score: Math.round(score * 10) / 10,
      category,
      area_key: candidate.area_key || areaKey(candidate.addr1),
      distance_km: distance,
    };
  });
}

export function selectRoute(
  candidates: KtoCandidate[],
  params: ItineraryRequest,
): KtoCandidate[] {
  const pool = scoreCandidates(candidates, params)
    .sort((a, b) => b.candidate_score - a.candidate_score);
  const selected: KtoCandidate[] = [];
  const selectedIds = new Set<string>();
  const categoryCounts = new Map<string, number>();
  const areaCounts = new Map<string, number>();

  while (selected.length < routeItemCount && selectedIds.size < pool.length) {
    let best: KtoCandidate | null = null;
    let bestAdjustedScore = Number.NEGATIVE_INFINITY;

    for (const candidate of pool) {
      if (selectedIds.has(candidate.contentid)) continue;

      const categoryCount = categoryCounts.get(candidate.category) ?? 0;
      const areaCount = areaCounts.get(candidate.area_key) ?? 0;
      let adjusted = candidate.candidate_score;

      if (categoryCount >= 2) adjusted -= 38;
      if (categoryCount === 1) adjusted -= 10;
      if (areaCount >= 2) adjusted -= 18;
      if (candidate.category === selected[selected.length - 1]?.category) {
        adjusted -= 14;
      }
      if (selected.length < 3 && candidate.category === "night_view") {
        adjusted -= 12;
      }
      adjusted += routeFlowBonus(selected[selected.length - 1], candidate);

      if (adjusted > bestAdjustedScore) {
        bestAdjustedScore = adjusted;
        best = candidate;
      }
    }

    if (!best) break;
    selected.push(best);
    selectedIds.add(best.contentid);
    categoryCounts.set(best.category, (categoryCounts.get(best.category) ?? 0) + 1);
    areaCounts.set(best.area_key, (areaCounts.get(best.area_key) ?? 0) + 1);
  }

  return orderRoute(selected, params).map((candidate, index) => ({
    ...candidate,
    candidate_score: Math.round(candidate.candidate_score * 10) / 10,
    matched_interest: candidate.matched_interests[0] ?? candidate.matched_interest,
  }));
}

function orderRoute(route: KtoCandidate[], params: ItineraryRequest): KtoCandidate[] {
  const base = baseCoordinatesFor(params.base_location);
  return [...route].sort((a, b) => {
    const slotDiff = timeSlotRank(a.category) - timeSlotRank(b.category);
    if (slotDiff !== 0) return slotDiff;
    if (base && a.distance_km !== undefined && b.distance_km !== undefined) {
      return a.distance_km - b.distance_km;
    }
    return b.candidate_score - a.candidate_score;
  });
}

async function requestEnnoiaItinerary(
  request: Request,
  params: ItineraryRequest,
  route: KtoCandidate[],
): Promise<JsonRecord | null> {
  const endpoint = Deno.env.get("ENNOIA_API_ENDPOINT")?.trim();
  const project = Deno.env.get("ENNOIA_PROJECT")?.trim();
  const apiKey = Deno.env.get("ENNOIA_API_KEY")?.trim();
  const hash = Deno.env.get("ENNOIA_ITINERARY_API_HASH")?.trim();
  const failureContext = ennoiaFailureContext(endpoint, project, apiKey, hash);

  if (!endpoint || !project || !apiKey || !hash) {
    throw new EnnoiaItineraryError(
      "ennoia_missing_config",
      "ennoia Edge Function secrets are missing",
      {
        ...failureContext,
        ennoia_error_code: "ennoia_missing_config",
      },
    );
  }

  const ktoData = route.map(toEnnoiaCandidate);
  const ennoiaPayload = {
    hash,
    params: {
      ...params,
      KTO_DATA: ktoData,
    },
    messages: [
      {
        role: "user",
        content: buildEnnoiaPrompt(params, ktoData),
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
    body: JSON.stringify(ennoiaPayload),
  });

  const text = await response.text();
  if (!response.ok) {
    throw new EnnoiaItineraryError(
      `ennoia_http_${response.status}`,
      `ennoia returned HTTP ${response.status}`,
      {
        ...failureContext,
        ennoia_status: response.status,
        ennoia_status_text: response.statusText,
        ennoia_body_preview: safeBodyPreview(text),
        ennoia_error_code: `ennoia_http_${response.status}`,
      },
    );
  }

  const payload = parseAgentPayload(text);
  const itemCount = readPayloadItems(payload).length;
  if (!payload || itemCount < routeItemCount) {
    throw new EnnoiaItineraryError(
      "ennoia_parse_error",
      `ennoia response did not contain ${routeItemCount} itinerary items`,
      {
        ...failureContext,
        ennoia_status: response.status,
        ennoia_status_text: response.statusText,
        ennoia_body_preview: safeBodyPreview(text),
        ennoia_error_code: "ennoia_parse_error",
      },
    );
  }

  return payload;
}

function buildEnnoiaPrompt(
  params: ItineraryRequest,
  ktoData: JsonRecord[],
): string {
  return [
    "Use only the provided KTO_DATA.",
    "Do not call tools.",
    "Do not invent place names.",
    "Do not invent kto_content_id.",
    "Return valid JSON only.",
    "Return exactly 5 items.",
    "Each item must preserve the selected KTO contentid as kto_content_id.",
    'If a field is unknown, use an empty string.',
    JSON.stringify({
      user_request: params,
      KTO_DATA: ktoData,
      response_shape: {
        source_type: "kto_openapi_ennoia",
        title: "personalized route title",
        summary: "short route summary",
        estimated_time_saved: "1h 10m",
        items: [
          {
            order: 1,
            time: "09:00",
            place_name: "KTO title",
            kto_content_id: "contentid from KTO_DATA",
            reason: "why this stop fits the user",
            culture_tip: "practical local culture tip",
            stay_time: "Stay 1h",
            crowd_level: "low",
          },
        ],
      },
    }),
  ].join("\n");
}

class EnnoiaItineraryError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly details: EnnoiaFailureDetails,
  ) {
    super(message);
    this.name = "EnnoiaItineraryError";
  }
}

function ennoiaFailureContext(
  endpoint: string | undefined,
  project: string | undefined,
  apiKey: string | undefined,
  hash: string | undefined,
): EnnoiaFailureDetails {
  return {
    hasApiKey: Boolean(apiKey),
    hasProject: Boolean(project),
    hasEndpoint: Boolean(endpoint),
    hasItineraryApiHash: Boolean(hash),
    hashSuffix: hash ? hash.slice(-8) : "",
  };
}

function ennoiaFailureDetailsFromError(error: unknown): EnnoiaFailureDetails {
  if (error instanceof EnnoiaItineraryError) return error.details;
  return {
    hasApiKey: Boolean(Deno.env.get("ENNOIA_API_KEY")?.trim()),
    hasProject: Boolean(Deno.env.get("ENNOIA_PROJECT")?.trim()),
    hasEndpoint: Boolean(Deno.env.get("ENNOIA_API_ENDPOINT")?.trim()),
    hasItineraryApiHash: Boolean(
      Deno.env.get("ENNOIA_ITINERARY_API_HASH")?.trim(),
    ),
    hashSuffix:
      Deno.env.get("ENNOIA_ITINERARY_API_HASH")?.trim().slice(-8) ?? "",
    ennoia_error_code: "ennoia_generation_failed",
    ennoia_body_preview: error instanceof Error ? error.message.slice(0, 160) : "",
  };
}

function logEnnoiaFailure(details: EnnoiaFailureDetails): void {
  console.error("ennoia itinerary request failed", {
    ennoia_status: details.ennoia_status,
    ennoia_status_text: details.ennoia_status_text,
    ennoia_body_preview: details.ennoia_body_preview,
    ennoia_error_code: details.ennoia_error_code,
    hasApiKey: details.hasApiKey,
    hasProject: details.hasProject,
    hasEndpoint: details.hasEndpoint,
    hasItineraryApiHash: details.hasItineraryApiHash,
    hashSuffix: details.hashSuffix,
  });
}

function safeBodyPreview(text: string): string {
  return text
    .replace(/Bearer\s+[A-Za-z0-9._-]+/g, "Bearer [redacted]")
    .replace(/("?(?:apiKey|apikey|authorization|token)"?\s*[:=]\s*")([^"]+)(")/gi, "$1[redacted]$3")
    .slice(0, ennoiaBodyPreviewLength);
}

export function buildKtoEnnoiaItinerary(
  params: ItineraryRequest,
  route: KtoCandidate[],
  candidateCount: number,
  ennoiaPayload: JsonRecord | null,
): JsonRecord {
  const payloadItems = readPayloadItems(ennoiaPayload);
  const title = readPayloadString(ennoiaPayload, ["title", "route_title"]) ||
    routeTitle(params);
  const summary = readPayloadString(ennoiaPayload, ["summary", "route_summary"]) ||
    "A personalized route built from live KTO OpenAPI candidates.";
  const estimatedTimeSaved =
    readPayloadString(ennoiaPayload, ["estimatedTimeSaved", "estimated_time_saved"]) ||
    "1h 10m";

  return {
    source: "kto_openapi_ennoia",
    source_type: "kto_openapi_ennoia",
    source_badge: "KTO OpenAPI + ennoia",
    source_note:
      "Real KTO OpenAPI candidates were retrieved dynamically; the Edge Function scored and selected the route before ennoia generated explanations from KTO_DATA.",
    fallback: false,
    id: `kto-ennoia-${shortHash(
      `${params.base_location}|${params.interests}|${params.companion_type}|${params.crowd_preference}`,
    )}`,
    date_label: params.travel_date,
    title,
    summary,
    estimated_time_saved: estimatedTimeSaved,
    candidate_count: candidateCount,
    selected_candidate_count: route.length,
    items: route.map((candidate, index) =>
      itineraryItemFromCandidate(
        candidate,
        index,
        payloadItems.find((item) => itemMatchesCandidate(item, candidate)) ??
          payloadItems[index],
        true,
      )
    ),
  };
}

export function buildKtoDirectItinerary(
  params: ItineraryRequest,
  route: KtoCandidate[],
  candidateCount: number,
  ennoiaFailure?: Partial<EnnoiaFailureDetails> | null,
): JsonRecord {
  return {
    source: "kto_openapi_basic",
    source_type: "kto_openapi_basic",
    source_badge: "KTO OpenAPI",
    source_note:
      "KTO OpenAPI data succeeded; ennoia generation failed and basic descriptions were generated by the backend.",
    ennoia_error_code:
      ennoiaFailure?.ennoia_error_code ?? "ennoia_generation_failed",
    fallback: false,
    ennoia_fallback: true,
    id: `kto-direct-${shortHash(
      `${params.base_location}|${params.interests}|${params.companion_type}|${params.crowd_preference}`,
    )}`,
    date_label: params.travel_date,
    title: routeTitle(params),
    summary: "A real KTO OpenAPI route returned while ennoia is unavailable.",
    estimated_time_saved: "1h 10m",
    candidate_count: candidateCount,
    selected_candidate_count: route.length,
    items: route.map((candidate, index) =>
      itineraryItemFromCandidate(candidate, index, undefined, true)
    ),
  };
}

export function buildFallbackItinerary(params: ItineraryRequest, reason: string): JsonRecord {
  const route = selectRoute(fallbackCandidates, params);
  return {
    source: "kto_openapi_fallback",
    source_type: "kto_openapi_fallback",
    source_badge: "Demo fallback",
    source_note:
      `Demo fallback was used because ${reason}. Real KTO OpenAPI success is not claimed for this response.`,
    fallback: true,
    id: `fallback-${shortHash(
      `${params.base_location}|${params.interests}|${params.companion_type}|${params.crowd_preference}`,
    )}`,
    date_label: params.travel_date,
    title: routeTitle(params),
    summary: "Demo fallback route shown while live KTO OpenAPI data is unavailable.",
    estimated_time_saved: "45m",
    candidate_count: fallbackCandidates.length,
    selected_candidate_count: route.length,
    items: route.map((candidate, index) =>
      itineraryItemFromCandidate(candidate, index, undefined, false)
    ),
  };
}

function itineraryItemFromCandidate(
  candidate: KtoCandidate,
  index: number,
  ennoiaItem: JsonRecord | undefined,
  includeKtoId: boolean,
): JsonRecord {
  const time = readPayloadString(ennoiaItem, ["time", "start_time"]) ||
    defaultTimeForIndex(index, candidate.category);
  const reason = readPayloadString(ennoiaItem, ["reason", "aiTip", "ai_tip", "tip"]) ||
    defaultReason(candidate);
  const cultureTip = readPayloadString(ennoiaItem, [
    "culture_tip",
    "cultureTip",
    "local_tip",
  ]) || defaultCultureTip(candidate);
  const stayTime = readPayloadString(ennoiaItem, ["stay_time", "stayTime", "duration"]) ||
    defaultStayTime(candidate.category);
  const crowdLevel = readPayloadString(ennoiaItem, [
    "crowd_level",
    "crowdLevel",
    "crowd",
  ]) || defaultCrowdLevel(candidate.category);

  return {
    id: slug(candidate.title),
    order: index + 1,
    time,
    place_name: candidate.title,
    placeName: candidate.title,
    ...(includeKtoId ? { kto_content_id: candidate.contentid, contentId: candidate.contentid } : {}),
    contenttypeid: candidate.contenttypeid,
    addr1: candidate.addr1,
    firstimage: candidate.firstimage,
    image_url: candidate.firstimage,
    mapx: candidate.mapx,
    mapy: candidate.mapy,
    matched_interest: candidate.matched_interest,
    candidate_score: candidate.candidate_score,
    crowd_level: normalizeCrowdLevel(crowdLevel),
    stay_time: stayTime,
    reason,
    aiTip: reason,
    culture_tip: cultureTip,
    extra_badge: candidate.category === "night_view" ? "Night view" : undefined,
  };
}

export function parseAgentPayload(text: string): JsonRecord | null {
  try {
    const decoded = JSON.parse(text);
    return parseAgentValue(decoded);
  } catch (_) {
    return parseJsonLike(text);
  }
}

function parseAgentValue(value: unknown): JsonRecord | null {
  if (!isRecord(value)) return null;
  if (looksLikeItineraryPayload(value)) return value;

  const content = extractAgentContent(value);
  if (content !== null && content !== undefined) {
    const parsed = parseAgentContent(content);
    if (parsed) return parsed;
  }

  return value;
}

function extractAgentContent(decoded: unknown): unknown {
  if (!isRecord(decoded)) return null;
  if (isRecord(decoded.data)) {
    const dataContent = extractAgentContent(decoded.data);
    if (dataContent !== null && dataContent !== undefined) return dataContent;
    if (looksLikeItineraryPayload(decoded.data)) return decoded.data;
  }

  const choices = decoded.choices;
  if (Array.isArray(choices) && choices.length > 0) {
    const first = choices[0];
    if (isRecord(first)) {
      if (typeof first.text === "string") return first.text;
      if (isRecord(first.message) && first.message.content !== undefined) {
        return first.message.content;
      }
    }
  }
  if (isRecord(decoded.message) && decoded.message.content !== undefined) {
    return decoded.message.content;
  }
  if (decoded.output_text !== undefined) return decoded.output_text;
  if (decoded.content !== undefined) return decoded.content;
  if (decoded.data !== undefined) return decoded.data;
  return null;
}

function parseAgentContent(content: unknown): JsonRecord | null {
  if (typeof content === "string") return parseJsonLike(content);
  if (Array.isArray(content)) {
    const text = content.map((part) => {
      if (typeof part === "string") return part;
      if (!isRecord(part)) return "";
      if (typeof part.text === "string") return part.text;
      if (typeof part.output_text === "string") return part.output_text;
      if (typeof part.content === "string") return part.content;
      return "";
    }).join("");
    return parseJsonLike(text);
  }
  if (isRecord(content)) return parseAgentValue(content);
  return null;
}

function parseJsonLike(content: string): JsonRecord | null {
  const trimmed = stripMarkdownJsonFence(content.trim());
  if (!trimmed) return null;

  try {
    const decoded = JSON.parse(trimmed);
    return isRecord(decoded) ? decoded : null;
  } catch (_) {
    const objectText = extractFirstJsonObject(trimmed);
    if (!objectText) return null;
    try {
      const decoded = JSON.parse(objectText);
      return isRecord(decoded) ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

function stripMarkdownJsonFence(content: string): string {
  return content
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();
}

function extractFirstJsonObject(content: string): string | null {
  let start = -1;
  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let index = 0; index < content.length; index += 1) {
    const char = content[index];
    if (start === -1) {
      if (char === "{") {
        start = index;
        depth = 1;
      }
      continue;
    }

    if (escaped) {
      escaped = false;
      continue;
    }
    if (char === "\\") {
      escaped = inString;
      continue;
    }
    if (char === '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (char === "{") depth += 1;
    if (char === "}") depth -= 1;
    if (depth === 0) return content.slice(start, index + 1);
  }

  return null;
}

function looksLikeItineraryPayload(value: JsonRecord): boolean {
  return Array.isArray(value.items) ||
    Array.isArray(value.itinerary_items) ||
    Array.isArray(value.itineraryItems) ||
    Array.isArray(value.places) ||
    typeof value.source_type === "string" ||
    typeof value.route_title === "string" ||
    typeof value.title === "string";
}

function readPayloadItems(payload: JsonRecord | null): JsonRecord[] {
  if (!payload) return [];
  const nested = firstRecord(payload, ["itinerary", "plan", "result", "data"]) ?? payload;
  for (const key of ["items", "itinerary_items", "itineraryItems", "places"]) {
    const value = nested[key];
    if (Array.isArray(value)) return value.filter(isRecord);
  }
  return [];
}

function itemMatchesCandidate(item: JsonRecord, candidate: KtoCandidate): boolean {
  const id = readPayloadString(item, [
    "kto_content_id",
    "contentid",
    "contentId",
    "content_id",
  ]);
  return id === candidate.contentid;
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

function toEnnoiaCandidate(candidate: KtoCandidate): JsonRecord {
  return {
    title: candidate.title,
    contentid: candidate.contentid,
    contenttypeid: candidate.contenttypeid,
    addr1: candidate.addr1,
    firstimage: candidate.firstimage,
    mapx: candidate.mapx,
    mapy: candidate.mapy,
    matched_interest: candidate.matched_interest,
    candidate_score: candidate.candidate_score,
  };
}

function keywordTitleScore(candidate: KtoCandidate, preferredLabels: string[]): number {
  let score = 0;
  const haystack = `${candidate.title} ${candidate.addr1}`;
  for (const label of preferredLabels) {
    const keywords = interestKeywords[label] ?? [];
    if (keywords.some((keyword) => haystack.includes(keyword.replace(/\s/g, "")) || haystack.includes(keyword))) {
      score += 8;
    }
  }
  return Math.min(score, 18);
}

function contentTypeScore(
  contenttypeid: string,
  matchedPreferred: string[],
  category: string,
): number {
  if (!contenttypeid) return 0;
  const labels = new Set(matchedPreferred);
  if (contenttypeid === "14" && (labels.has("Museum") || labels.has("Culture"))) {
    return 12;
  }
  if (contenttypeid === "38" && (labels.has("Shopping") || labels.has("Traditional market"))) {
    return 12;
  }
  if (contenttypeid === "39" && (labels.has("Local food") || labels.has("Cafe") || labels.has("Dessert cafe"))) {
    return 12;
  }
  if (contenttypeid === "12" && [
    "palace",
    "hanok",
    "nature",
    "night_view",
    "photo",
    "kpop",
    "wellness",
  ].includes(category)) {
    return 10;
  }
  return ["12", "14", "38", "39"].includes(contenttypeid) ? 5 : 0;
}

function crowdPreferenceScore(preference: string, category: string): number {
  if (preference.includes("quiet") || preference.includes("low")) {
    if (["nature", "museum", "palace", "hanok", "wellness"].includes(category)) {
      return 9;
    }
    if (["shopping", "market", "kpop"].includes(category)) return -5;
  }
  if (preference.includes("lively") || preference.includes("active")) {
    if (["shopping", "market", "night_view", "cafe", "kpop"].includes(category)) {
      return 7;
    }
  }
  if (preference.includes("moderate")) return 3;
  return 0;
}

function distanceScore(distanceKm: number): number {
  if (distanceKm <= 2) return 8;
  if (distanceKm <= 5) return 6;
  if (distanceKm <= 10) return 4;
  if (distanceKm <= 18) return 2;
  return -2;
}

function routeFlowBonus(previous: KtoCandidate | undefined, next: KtoCandidate): number {
  if (!previous) return 0;
  if (
    previous.mapx === undefined ||
    previous.mapy === undefined ||
    next.mapx === undefined ||
    next.mapy === undefined
  ) {
    return 0;
  }
  const distance = haversineKm(previous.mapy, previous.mapx, next.mapy, next.mapx);
  if (distance <= 2) return 5;
  if (distance <= 6) return 3;
  if (distance <= 12) return 1;
  return -3;
}

function categoryForCandidate(
  interest: string,
  contenttypeid: string,
  title: string,
): string {
  const normalizedTitle = title.toLowerCase();
  if (interest === "Palace" || title.includes("궁")) return "palace";
  if (interest === "Hanok village" || title.includes("한옥")) return "hanok";
  if (interest === "Traditional market" || title.includes("시장")) return "market";
  if (interest === "Dessert cafe" || interest === "Cafe" || title.includes("카페")) {
    return "cafe";
  }
  if (interest === "Night view" || title.includes("타워") || title.includes("야경")) {
    return "night_view";
  }
  if (interest === "Shopping" || contenttypeid === "38") return "shopping";
  if (interest === "K-pop" || normalizedTitle.includes("k-pop")) return "kpop";
  if (interest === "Local food" || contenttypeid === "39") return "food";
  if (interest === "Museum" || contenttypeid === "14" || title.includes("박물관")) {
    return "museum";
  }
  if (interest === "Nature" || title.includes("공원") || title.includes("숲")) return "nature";
  if (interest === "Wellness") return "wellness";
  if (interest === "Photo spot") return "photo";
  if (interest === "Family") return "family";
  if (interest === "Couple") return "couple";
  if (interest === "Solo") return "solo";
  if (contenttypeid === "12") return "culture";
  return "culture";
}

function timeSlotRank(category: string): number {
  if (["palace", "museum", "nature", "culture", "wellness"].includes(category)) {
    return 1;
  }
  if (["market", "food"].includes(category)) return 2;
  if (["cafe", "hanok", "shopping", "kpop", "photo", "family", "solo", "couple"].includes(category)) {
    return 3;
  }
  if (category === "night_view") return 4;
  return 3;
}

function defaultTimeForIndex(index: number, category: string): string {
  if (category === "night_view") return "18:30";
  return ["09:00", "11:00", "13:00", "15:30", "18:30"][index] ?? "18:30";
}

function defaultStayTime(category: string): string {
  if (["palace", "museum", "nature"].includes(category)) return "Stay 1h 30m";
  if (["market", "food", "cafe"].includes(category)) return "Stay 1h";
  return "Stay 1h 15m";
}

function defaultCrowdLevel(category: string): string {
  return ["market", "shopping", "kpop", "night_view"].includes(category)
    ? "moderate"
    : "low";
}

function normalizeCrowdLevel(value: string): string {
  return value.toLowerCase().includes("high") ||
      value.toLowerCase().includes("moderate")
    ? "moderate"
    : "low";
}

function defaultReason(candidate: KtoCandidate): string {
  return `${candidate.title} fits ${candidate.matched_interest.toLowerCase()} preferences and scored well on KTO data quality.`;
}

function defaultCultureTip(candidate: KtoCandidate): string {
  if (candidate.category === "palace") return "Check palace etiquette signs and keep voices low around ceremonial areas.";
  if (candidate.category === "market") return "Small cash payments and short waits are common at popular stalls.";
  if (candidate.category === "cafe") return "Order first, then choose seats unless staff guide you otherwise.";
  if (candidate.category === "night_view") return "Arrive before sunset for a smoother entry and better photos.";
  return "Follow posted local guidance and keep walkways clear for residents.";
}

function routeTitle(params: ItineraryRequest): string {
  const labels = resolveInterestLabels(params).filter((label) => label !== "Quiet");
  const focus = labels.slice(0, 2).join(" + ") || "Seoul";
  return `${focus} route from ${params.base_location}`;
}

function baseKeywordFor(baseLocation: string): string | null {
  const normalized = normalizePreference(baseLocation);
  return baseLocations.find((location) =>
    location.names.some((name) => normalized.includes(normalizePreference(name)))
  )?.keyword ?? null;
}

function baseCoordinatesFor(
  baseLocation: string,
): { mapx: number; mapy: number } | null {
  const normalized = normalizePreference(baseLocation);
  const location = baseLocations.find((item) =>
    item.names.some((name) => normalized.includes(normalizePreference(name)))
  );
  return location ? { mapx: location.mapx, mapy: location.mapy } : null;
}

function isSeoulBase(baseLocation: string): boolean {
  const normalized = normalizePreference(baseLocation);
  return normalized.includes("seoul") || normalized.includes("서울") ||
    baseLocations.some((location) =>
      location.names.some((name) => normalized.includes(normalizePreference(name)))
    );
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

function areaKey(addr1: string): string {
  const parts = addr1.split(/\s+/).filter(Boolean);
  return parts.slice(0, 2).join(" ") || "unknown";
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

function fallbackCandidate(
  title: string,
  contentid: string,
  contenttypeid: string,
  addr1: string,
  matchedInterest: string,
  category: string,
  mapx: number,
  mapy: number,
): KtoCandidate {
  return {
    title,
    contentid,
    contenttypeid,
    addr1,
    firstimage: "",
    mapx,
    mapy,
    matched_interest: matchedInterest,
    matched_interests: [matchedInterest],
    matched_keywords: [title],
    candidate_score: 0,
    category,
    area_key: areaKey(addr1),
  };
}
