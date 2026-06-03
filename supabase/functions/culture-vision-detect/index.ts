type JsonRecord = Record<string, unknown>;

export type CultureVisionRequest = {
  image_path?: string | null;
  current_location?: string | null;
  user_language?: string | null;
  hint_place_type?: string | null;
};

export type CultureVisionAlternative = {
  detected_object: string;
  place_type: string;
  label: string;
  confidence: number;
};

export type CultureVisionResult = {
  detected_object: string;
  place_type: string;
  confidence: number;
  alternatives: CultureVisionAlternative[];
  needs_confirmation: boolean;
  source_type: "vision_ai" | "vision_heuristic" | "vision_no_match";
  source_badge: "Vision AI" | "Context hint" | "Manual selection";
  detected_object_source?: string;
  final_decision?: string;
};

type AllowedCultureObject = {
  key: string;
  placeType: string;
  label: string;
  keywords: string[];
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const allowedObjects: AllowedCultureObject[] = [
  {
    key: "temple_stone_stack",
    placeType: "temple",
    label: "Temple stone stack",
    keywords: ["temple", "buddha", "bulguksa", "stone", "stack", "wish"],
  },
  {
    key: "restaurant_call_bell",
    placeType: "restaurant",
    label: "Restaurant call bell",
    keywords: ["restaurant", "bell", "call", "table", "server"],
  },
  {
    key: "subway_pregnant_seat",
    placeType: "subway",
    label: "Pregnant priority seat",
    keywords: ["subway", "metro", "pregnant", "pink", "seat"],
  },
  {
    key: "cafe_quiet_work",
    placeType: "cafe",
    label: "Quiet cafe work",
    keywords: ["cafe", "coffee", "quiet", "work", "laptop"],
  },
  {
    key: "kiosk_ordering",
    placeType: "restaurant",
    label: "Kiosk ordering",
    keywords: ["kiosk", "order", "screen", "payment", "menu"],
  },
  {
    key: "market_cash_food",
    placeType: "market",
    label: "Market cash and food",
    keywords: ["market", "cash", "food", "card", "gwangjang"],
  },
  {
    key: "market_queue_ticket",
    placeType: "market",
    label: "Market queue ticket",
    keywords: ["market", "queue", "ticket", "number", "waiting"],
  },
  {
    key: "palace_photo_etiquette",
    placeType: "palace",
    label: "Palace photo etiquette",
    keywords: ["palace", "photo", "gyeongbokgung", "camera", "hanbok"],
  },
  {
    key: "hanok_resident_etiquette",
    placeType: "hanok_village",
    label: "Hanok resident etiquette",
    keywords: ["hanok", "bukchon", "resident", "quiet", "village"],
  },
  {
    key: "waiting_number_ticket",
    placeType: "restaurant",
    label: "Waiting number ticket",
    keywords: ["waiting", "number", "ticket", "queue", "restaurant"],
  },
];

const allowedByKey = new Map(allowedObjects.map((item) => [item.key, item]));

export async function handleCultureVisionDetectRequest(
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
  const imageBytes = params.image_path
    ? await downloadCultureScanImage(params.image_path).catch(() => null)
    : null;

  const providerResult = await classifyWithConfiguredVisionProvider(
    params,
    imageBytes,
  ).catch(() => null);
  const result = providerResult ?? noMatchResult(params);

  console.log(JSON.stringify({
    image_path_suffix: suffix(params.image_path),
    source_type: result.source_type,
    confidence: result.confidence,
    detected_object: result.detected_object,
    detected_object_source: result.detected_object_source ?? null,
  }));

  return jsonResponse(result, 200);
}

export function noMatchResult(
  params: CultureVisionRequest,
): CultureVisionResult {
  return {
    detected_object: "unsupported",
    place_type: optionalString(params.hint_place_type) ?? "unknown",
    confidence: 0,
    alternatives: [],
    needs_confirmation: true,
    source_type: "vision_no_match",
    source_badge: "Manual selection",
    detected_object_source: "no_match",
    final_decision: "manual_required",
  };
}

if (import.meta.main) {
  Deno.serve(handleCultureVisionDetectRequest);
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

function normalizeRequest(body: JsonRecord): CultureVisionRequest {
  return {
    image_path: normalizeImagePath(optionalString(body.image_path)),
    current_location: optionalString(body.current_location) ?? "Bulguksa",
    user_language: optionalString(body.user_language) ?? "English",
    hint_place_type: optionalString(body.hint_place_type) ?? "temple",
  };
}

function normalizeImagePath(value: string | null): string | null {
  if (!value) return null;
  const trimmed = value.trim().replace(/^culture-scans\//, "");
  if (!trimmed || trimmed.includes("..") || trimmed.startsWith("/")) {
    return null;
  }
  return trimmed;
}

async function downloadCultureScanImage(
  imagePath: string,
): Promise<Uint8Array | null> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) return null;

  const encodedPath = imagePath.split("/").map(encodeURIComponent).join("/");
  const response = await fetch(
    `${
      supabaseUrl.replace(/\/+$/, "")
    }/storage/v1/object/culture-scans/${encodedPath}`,
    {
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
      },
    },
  );
  if (!response.ok) return null;
  const bytes = new Uint8Array(await response.arrayBuffer());
  return bytes.length > 0 ? bytes : null;
}

export async function classifyWithConfiguredVisionProvider(
  params: CultureVisionRequest,
  imageBytes: Uint8Array | null,
): Promise<CultureVisionResult | null> {
  const endpoint = Deno.env.get("VISION_PROVIDER_ENDPOINT")?.trim();
  const apiKey = Deno.env.get("VISION_PROVIDER_API_KEY")?.trim();
  if (!endpoint || !apiKey) return null;

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json; charset=utf-8",
    },
    body: JSON.stringify({
      current_location: params.current_location,
      hint_place_type: params.hint_place_type,
      allowed_objects: allowedObjects.map((item) => ({
        key: item.key,
        place_type: item.placeType,
        label: item.label,
      })),
      image_base64: imageBytes ? bytesToBase64(imageBytes) : null,
    }),
  });
  if (!response.ok) return null;

  const decoded = await response.json().catch(() => null);
  if (!decoded || typeof decoded !== "object" || Array.isArray(decoded)) {
    return null;
  }
  const result = visionResultFromProvider(decoded as JsonRecord);
  return result;
}

function visionResultFromProvider(
  payload: JsonRecord,
): CultureVisionResult | null {
  const detectedObject = optionalString(payload.detected_object) ??
    optionalString(payload.object_key);
  if (!detectedObject || !allowedByKey.has(detectedObject)) return null;

  const object = allowedByKey.get(detectedObject)!;
  const confidence = clampNumber(payload.confidence, 0.72);
  const alternatives = readAlternatives(payload.alternatives);
  return {
    detected_object: object.key,
    place_type: object.placeType,
    confidence,
    alternatives: alternatives.length > 0
      ? alternatives
      : [alternativeFor(object, confidence)],
    needs_confirmation: confidence < 0.72,
    source_type: "vision_ai",
    source_badge: "Vision AI",
    detected_object_source: "vision_provider",
    final_decision: confidence >= 0.75
      ? "auto_confirm_possible"
      : confidence >= 0.5
      ? "needs_confirmation"
      : "manual_required",
  };
}

export function classifyWithHeuristics(
  params: CultureVisionRequest,
): CultureVisionResult {
  const text = [
    params.hint_place_type,
    params.current_location,
  ].join(" ").toLowerCase();

  const scored = allowedObjects
    .map((item) => ({
      item,
      score: scoreObject(item, text),
    }))
    .sort((a, b) => b.score - a.score);

  const best = scored[0]?.score > 0 ? scored[0].item : allowedObjects[0];
  const alternatives = scored
    .filter((item) => item.score > 0 || item.item.key === best.key)
    .slice(0, 3)
    .map((item, index) =>
      alternativeFor(
        item.item,
        index === 0 ? 0.42 : Math.max(0.28, 0.38 - index * 0.06),
      )
    );

  return {
    detected_object: best.key,
    place_type: best.placeType,
    confidence: 0.42,
    alternatives,
    needs_confirmation: true,
    source_type: "vision_heuristic",
    source_badge: "Context hint",
  };
}

function scoreObject(item: AllowedCultureObject, text: string): number {
  let score = item.key.includes(text) ? 2 : 0;
  if (text.includes(item.placeType)) score += 8;
  for (const keyword of item.key.split("_")) {
    if (text.includes(keyword)) score += 2;
  }
  for (const keyword of item.keywords) {
    if (text.includes(keyword)) score += 4;
  }
  return score;
}

function readAlternatives(value: unknown): CultureVisionAlternative[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => {
      if (!item || typeof item !== "object" || Array.isArray(item)) {
        return null;
      }
      const record = item as JsonRecord;
      const key = optionalString(record.detected_object) ??
        optionalString(record.object_key);
      const object = key ? allowedByKey.get(key) : null;
      if (!object) return null;
      return alternativeFor(object, clampNumber(record.confidence, 0.5));
    })
    .filter((item): item is CultureVisionAlternative => item !== null)
    .slice(0, 3);
}

function alternativeFor(
  item: AllowedCultureObject,
  confidence: number,
): CultureVisionAlternative {
  return {
    detected_object: item.key,
    place_type: item.placeType,
    label: item.label,
    confidence,
  };
}

function optionalString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function clampNumber(value: unknown, fallback: number): number {
  const numberValue = typeof value === "number"
    ? value
    : typeof value === "string"
    ? Number(value)
    : Number.NaN;
  if (!Number.isFinite(numberValue)) return fallback;
  return Math.max(0, Math.min(1, numberValue));
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function suffix(value: string | null | undefined): string | null {
  if (!value) return null;
  const parts = value.split("/").filter((part) => part.length > 0);
  return parts.slice(-2).join("/");
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
