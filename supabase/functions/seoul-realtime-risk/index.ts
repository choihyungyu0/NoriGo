type SeoulRealtimeRiskRequest = {
  current_lat?: number | null;
  current_lng?: number | null;
  current_place_name?: string | null;
  scheduled_place_name?: string | null;
  scheduled_time?: string | null;
  trigger_context?: string | null;
};

type JsonRecord = Record<string, unknown>;

export type SeoulRealtimeArea = {
  area_nm: string;
  area_code?: string | null;
  aliases: string[];
  lat?: number | null;
  lng?: number | null;
  coord_confidence?: string | null;
};

type ResolvedArea = {
  area: SeoulRealtimeArea;
  matched_place_name: string;
  match_type: "exact_alias" | "korean_name" | "nearest_coordinates";
};

type CongestionRecord = {
  area_nm: string;
  congestion_level: string;
  congestion_message: string;
  population_min: number | null;
  population_max: number | null;
  population_time: string;
  raw: JsonRecord;
};

type IncidentScore = {
  bonus: number;
  checked: boolean;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const seoulCitydataPath = "citydata_ppltn/1/5";

const fallbackAreas: SeoulRealtimeArea[] = [
  area("광화문·덕수궁", [
    "Gwanghwamun",
    "Gwanghwamun Plaza",
    "Deoksugung",
    "Deoksu Palace",
    "광화문",
    "덕수궁",
  ]),
  area("북촌한옥마을", ["Bukchon Hanok Village", "Bukchon", "북촌"]),
  area("경복궁", ["Gyeongbokgung Palace", "Gyeongbokgung", "경복궁"]),
  area("광장(전통)시장", [
    "Gwangjang Market",
    "Gwangjang",
    "광장시장",
    "광장전통시장",
  ]),
  area("남산공원", [
    "N Seoul Tower",
    "Namsan Tower",
    "N Seoul Tower Observatory",
    "남산서울타워",
    "N서울타워",
    "남산",
  ]),
  area("명동 관광특구", ["Myeongdong", "Myeongdong Seoul", "명동"]),
  area("홍대 관광특구", ["Hongdae", "Hongik University Street", "홍대"]),
  area("익선동", ["Ikseondong", "Ikseon-dong", "익선동"]),
  area("성수카페거리", ["Seongsu", "Seongsu Cafe Street", "성수"]),
  area("잠실 관광특구", ["Jamsil", "Lotte World", "잠실"]),
  area("강남역", ["Gangnam Station", "Gangnam", "강남역"]),
];

export async function handleSeoulRealtimeRiskRequest(
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

  const params = normalizeRequest(bodyResult.body);
  const areas = await loadSeoulRealtimeAreas();
  const resolved = resolveSeoulArea(params, areas);

  if (!resolved) {
    return jsonResponse(buildUnmatchedResponse(params), 200);
  }

  const serviceKey = Deno.env.get("SEOUL_CITYDATA_API_KEY")?.trim();
  if (!serviceKey) {
    return jsonResponse(
      buildUnavailableResponse(
        params,
        resolved,
        "SEOUL_CITYDATA_API_KEY is missing in the Edge Function runtime.",
      ),
      200,
    );
  }

  try {
    const congestion = await fetchSeoulCitydata(
      resolved.area.area_nm,
      serviceKey,
    );
    return jsonResponse(buildRiskResponse(params, resolved, congestion), 200);
  } catch (error) {
    console.error(
      "Seoul real-time citydata request failed",
      error instanceof Error ? error.message : "unknown error",
    );
    return jsonResponse(
      buildUnavailableResponse(
        params,
        resolved,
        "Seoul real-time city data was unavailable.",
      ),
      200,
    );
  }
}

if (import.meta.main) {
  Deno.serve(handleSeoulRealtimeRiskRequest);
}

export function resolveSeoulArea(
  params: SeoulRealtimeRiskRequest,
  areas: SeoulRealtimeArea[] = fallbackAreas,
): ResolvedArea | null {
  const names = placeNames(params);

  for (const name of names) {
    const normalizedName = normalizeText(name);
    for (const candidate of areas) {
      const aliases = [candidate.area_nm, ...candidate.aliases];
      if (aliases.some((alias) => normalizeText(alias) === normalizedName)) {
        return {
          area: candidate,
          matched_place_name: name,
          match_type: "exact_alias",
        };
      }
    }
  }

  for (const name of names) {
    if (!hasKorean(name)) continue;
    const normalizedName = normalizeKorean(name);
    for (const candidate of areas) {
      const aliases = [candidate.area_nm, ...candidate.aliases]
        .filter(hasKorean)
        .map(normalizeKorean)
        .filter(Boolean);
      if (
        aliases.some((alias) =>
          alias === normalizedName ||
          normalizedName.includes(alias) ||
          alias.includes(normalizedName)
        )
      ) {
        return {
          area: candidate,
          matched_place_name: name,
          match_type: "korean_name",
        };
      }
    }
  }

  if (isFiniteNumber(params.current_lat) && isFiniteNumber(params.current_lng)) {
    const nearest = nearestArea(
      params.current_lat,
      params.current_lng,
      areas,
    );
    if (nearest) {
      return {
        area: nearest,
        matched_place_name: "current coordinates",
        match_type: "nearest_coordinates",
      };
    }
  }

  return null;
}

export function crowdScoreFor(congestionLevel: string): number {
  const normalized = normalizeText(congestionLevel);
  if (normalized.includes("여유")) return 20;
  if (normalized.includes("보통")) return 45;
  if (normalized.includes("약간붐빔")) return 70;
  if (normalized.includes("붐빔")) return 85;
  return 50;
}

export function riskLevelFor(score: number): string {
  if (score <= 39) return "Low";
  if (score <= 64) return "Moderate";
  if (score <= 84) return "High";
  return "Very High";
}

export function triggerTypeFor(score: number): string {
  if (score >= 85) return "crowd_spike";
  if (score >= 65) return "crowd_watch";
  return "none";
}

export function incidentBonusFromRecord(record: JsonRecord): IncidentScore {
  const incidentKeys = Object.keys(record).filter((key) =>
    /ACDNT|ACCIDENT|CONTROL|CTRL|EVENT|INCIDENT|WARNING|통제|사고/i.test(key)
  );

  if (incidentKeys.length === 0) {
    return { bonus: 0, checked: false };
  }

  const active = incidentKeys.some((key) => hasActiveIncidentSignal(record[key]));
  return { bonus: active ? 15 : 0, checked: true };
}

export function buildRiskResponse(
  params: SeoulRealtimeRiskRequest,
  resolved: ResolvedArea,
  congestion: CongestionRecord,
): JsonRecord {
  const crowdScore = crowdScoreFor(congestion.congestion_level);
  const incident = incidentBonusFromRecord(congestion.raw);
  const incidentBonus = Math.min(15, Math.max(0, incident.bonus));
  const riskScore = Math.min(100, crowdScore + incidentBonus);
  const riskLevel = riskLevelFor(riskScore);
  const triggerType = triggerTypeFor(riskScore);
  const shouldAlert = riskScore >= 85;
  const riskReasonParts = [
    `Crowd score ${crowdScore} from congestion level ${congestion.congestion_level || "unknown"}.`,
    incident.checked
      ? incidentBonus > 0
        ? `Incident/control data added ${incidentBonus} points.`
        : "Incident/control fields were checked with no active signal."
      : "No incident data was used.",
  ];

  return {
    area_nm: congestion.area_nm || resolved.area.area_nm,
    matched_place_name: resolved.matched_place_name,
    scheduled_place_name: stringValue(params.scheduled_place_name),
    congestion_level: congestion.congestion_level,
    congestion_message: congestion.congestion_message,
    population_min: congestion.population_min,
    population_max: congestion.population_max,
    population_time: congestion.population_time,
    crowd_score: crowdScore,
    incident_bonus: incidentBonus,
    risk_score: riskScore,
    risk_level: riskLevel,
    should_alert: shouldAlert,
    trigger_type: triggerType,
    alert_message: alertMessageFor(
      congestion.area_nm || resolved.area.area_nm,
      congestion.congestion_level,
      riskLevel,
      congestion.congestion_message,
    ),
    risk_reason: riskReasonParts.join(" "),
    source_type: "seoul_realtime_citydata",
    source_badge: "Seoul Real-time",
  };
}

export function parseSeoulJsonPayload(decoded: unknown): CongestionRecord | null {
  const record = findCongestionRecord(decoded);
  return record ? congestionRecordFromJson(record) : null;
}

export function parseSeoulXmlPayload(text: string): CongestionRecord | null {
  const raw: JsonRecord = {
    AREA_NM: readXmlTag(text, "AREA_NM"),
    AREA_CONGEST_LVL: readXmlTag(text, "AREA_CONGEST_LVL"),
    AREA_CONGEST_MSG: readXmlTag(text, "AREA_CONGEST_MSG"),
    AREA_PPLTN_MIN: readXmlTag(text, "AREA_PPLTN_MIN"),
    AREA_PPLTN_MAX: readXmlTag(text, "AREA_PPLTN_MAX"),
    PPLTN_TIME: readXmlTag(text, "PPLTN_TIME"),
  };

  if (!raw.AREA_CONGEST_LVL && !raw.AREA_NM) return null;
  return congestionRecordFromJson(raw);
}

async function fetchSeoulCitydata(
  areaNm: string,
  serviceKey: string,
): Promise<CongestionRecord> {
  const jsonUrl = seoulApiUrl("json", serviceKey, areaNm);

  try {
    const response = await fetch(jsonUrl, {
      headers: { Accept: "application/json" },
    });
    if (response.ok) {
      const decoded = await response.json();
      const parsed = parseSeoulJsonPayload(decoded);
      if (parsed) return parsed;
    }
  } catch (error) {
    console.warn(
      "Seoul citydata JSON endpoint failed, trying XML",
      error instanceof Error ? error.message : "unknown error",
    );
  }

  const xmlResponse = await fetch(seoulApiUrl("xml", serviceKey, areaNm), {
    headers: { Accept: "application/xml,text/xml" },
  });
  const xmlText = await xmlResponse.text();
  if (!xmlResponse.ok) {
    throw new Error(`Seoul citydata XML returned HTTP ${xmlResponse.status}`);
  }
  const parsed = parseSeoulXmlPayload(xmlText);
  if (!parsed) {
    throw new Error("Seoul citydata response did not contain congestion fields");
  }
  return parsed;
}

function seoulApiUrl(format: "json" | "xml", serviceKey: string, areaNm: string): string {
  const key = serviceKey.includes("%") ? serviceKey : encodeURIComponent(serviceKey);
  return `http://openapi.seoul.go.kr:8088/${key}/${format}/${seoulCitydataPath}/${
    encodeURIComponent(areaNm)
  }`;
}

async function loadSeoulRealtimeAreas(): Promise<SeoulRealtimeArea[]> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) return fallbackAreas;

  try {
    const response = await fetch(
      `${supabaseUrl.replace(/\/+$/, "")}/rest/v1/seoul_realtime_areas?select=area_nm,area_code,aliases,lat,lng,coord_confidence`,
      {
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
      },
    );

    if (!response.ok) return fallbackAreas;
    const decoded = await response.json();
    if (!Array.isArray(decoded)) return fallbackAreas;
    const rows = decoded.filter(isRecord).map(areaFromRecord).filter(
      (item): item is SeoulRealtimeArea => item !== null,
    );
    return rows.length > 0 ? rows : fallbackAreas;
  } catch (error) {
    console.error(
      "Unable to load Seoul realtime areas from Supabase",
      error instanceof Error ? error.message : "unknown error",
    );
    return fallbackAreas;
  }
}

function areaFromRecord(record: JsonRecord): SeoulRealtimeArea | null {
  const areaNm = readPayloadString(record, ["area_nm"]);
  if (!areaNm) return null;
  const aliases = Array.isArray(record.aliases)
    ? record.aliases.filter((item): item is string => typeof item === "string")
    : [];
  return {
    area_nm: areaNm,
    area_code: readPayloadString(record, ["area_code"]),
    aliases,
    lat: readPayloadNumber(record, ["lat"]),
    lng: readPayloadNumber(record, ["lng"]),
    coord_confidence: readPayloadString(record, ["coord_confidence"]),
  };
}

function normalizeRequest(body: JsonRecord): SeoulRealtimeRiskRequest {
  return {
    current_lat: nullableNumber(body.current_lat),
    current_lng: nullableNumber(body.current_lng),
    current_place_name: nullableString(body.current_place_name),
    scheduled_place_name: nullableString(body.scheduled_place_name),
    scheduled_time: nullableString(body.scheduled_time),
    trigger_context: nullableString(body.trigger_context),
  };
}

function buildUnmatchedResponse(params: SeoulRealtimeRiskRequest): JsonRecord {
  return {
    area_nm: "",
    matched_place_name: "",
    scheduled_place_name: stringValue(params.scheduled_place_name),
    congestion_level: "",
    congestion_message: "",
    population_min: null,
    population_max: null,
    population_time: "",
    crowd_score: 0,
    incident_bonus: 0,
    risk_score: 0,
    risk_level: "Low",
    should_alert: false,
    trigger_type: "none",
    alert_message: "",
    risk_reason: "No matching Seoul real-time citydata AREA_NM was found.",
    source_type: "seoul_area_unmatched",
    source_badge: "Seoul Real-time",
  };
}

function buildUnavailableResponse(
  params: SeoulRealtimeRiskRequest,
  resolved: ResolvedArea,
  reason: string,
): JsonRecord {
  return {
    area_nm: resolved.area.area_nm,
    matched_place_name: resolved.matched_place_name,
    scheduled_place_name: stringValue(params.scheduled_place_name),
    congestion_level: "",
    congestion_message: "",
    population_min: null,
    population_max: null,
    population_time: "",
    crowd_score: 0,
    incident_bonus: 0,
    risk_score: 0,
    risk_level: "Low",
    should_alert: false,
    trigger_type: "none",
    alert_message: "",
    risk_reason: reason,
    source_type: "seoul_realtime_unavailable",
    source_badge: "Seoul Real-time",
  };
}

function congestionRecordFromJson(record: JsonRecord): CongestionRecord {
  return {
    area_nm: readPayloadString(record, ["AREA_NM", "area_nm"]) ?? "",
    congestion_level: readPayloadString(record, [
      "AREA_CONGEST_LVL",
      "area_congest_lvl",
      "congestion_level",
    ]) ?? "",
    congestion_message: readPayloadString(record, [
      "AREA_CONGEST_MSG",
      "area_congest_msg",
      "congestion_message",
    ]) ?? "",
    population_min: readPayloadNumber(record, [
      "AREA_PPLTN_MIN",
      "area_ppltn_min",
      "population_min",
    ]),
    population_max: readPayloadNumber(record, [
      "AREA_PPLTN_MAX",
      "area_ppltn_max",
      "population_max",
    ]),
    population_time: readPayloadString(record, [
      "PPLTN_TIME",
      "ppltn_time",
      "population_time",
    ]) ?? "",
    raw: record,
  };
}

function findCongestionRecord(value: unknown): JsonRecord | null {
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findCongestionRecord(item);
      if (found) return found;
    }
    return null;
  }

  if (!isRecord(value)) return null;
  if (
    "AREA_CONGEST_LVL" in value ||
    "AREA_CONGEST_MSG" in value ||
    "AREA_PPLTN_MIN" in value
  ) {
    return value;
  }

  for (const item of Object.values(value)) {
    const found = findCongestionRecord(item);
    if (found) return found;
  }
  return null;
}

function alertMessageFor(
  areaNm: string,
  congestionLevel: string,
  riskLevel: string,
  congestionMessage: string,
): string {
  const level = congestionLevel || "unknown congestion";
  const base = `${areaNm} is ${riskLevel} risk now (${level}).`;
  return congestionMessage ? `${base} ${congestionMessage}` : base;
}

function nearestArea(
  lat: number,
  lng: number,
  areas: SeoulRealtimeArea[],
): SeoulRealtimeArea | null {
  let nearest: SeoulRealtimeArea | null = null;
  let nearestDistance = Number.POSITIVE_INFINITY;

  for (const candidate of areas) {
    if (!isFiniteNumber(candidate.lat) || !isFiniteNumber(candidate.lng)) {
      continue;
    }
    const confidence = candidate.coord_confidence?.trim().toLowerCase();
    if (!confidence || confidence === "missing") continue;

    const distance = haversineKm(lat, lng, candidate.lat, candidate.lng);
    if (distance < nearestDistance) {
      nearest = candidate;
      nearestDistance = distance;
    }
  }

  return nearest;
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

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function placeNames(params: SeoulRealtimeRiskRequest): string[] {
  return [
    params.current_place_name,
    params.scheduled_place_name,
  ]
    .map(stringValue)
    .filter((value, index, values) =>
      value.length > 0 && values.indexOf(value) === index
    );
}

function normalizeText(value: string): string {
  return value
    .toLowerCase()
    .replace(/[\s._'’`-]+/g, "")
    .trim();
}

function normalizeKorean(value: string): string {
  return value.replace(/[^\u3131-\uD79D0-9a-zA-Z]+/g, "").trim();
}

function hasKorean(value: string): boolean {
  return /[\u3131-\uD79D]/.test(value);
}

function hasActiveIncidentSignal(value: unknown): boolean {
  if (typeof value === "number") return value > 0;
  if (typeof value !== "string") return false;
  const normalized = normalizeText(value);
  if (!normalized) return false;
  return ![
    "0",
    "none",
    "no",
    "normal",
    "clear",
    "없음",
    "해당없음",
    "정상",
  ].includes(normalized);
}

function readXmlTag(text: string, tag: string): string {
  const match = text.match(new RegExp(`<${tag}>([\\s\\S]*?)<\\/${tag}>`, "i"));
  if (!match) return "";
  return decodeXml(match[1].replace(/^<!\[CDATA\[/, "").replace(/\]\]>$/, ""))
    .trim();
}

function decodeXml(value: string): string {
  return value
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

function readPayloadString(
  record: JsonRecord,
  keys: string[],
): string | null {
  for (const key of keys) {
    const value = record[key];
    if (typeof value === "string" && value.trim()) return value.trim();
    if (typeof value === "number") return String(value);
  }
  return null;
}

function readPayloadNumber(
  record: JsonRecord,
  keys: string[],
): number | null {
  for (const key of keys) {
    const value = record[key];
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string") {
      const parsed = Number.parseInt(value.replace(/,/g, ""), 10);
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return null;
}

function nullableString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function nullableNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
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

function area(areaNm: string, aliases: string[]): SeoulRealtimeArea {
  return { area_nm: areaNm, aliases };
}
