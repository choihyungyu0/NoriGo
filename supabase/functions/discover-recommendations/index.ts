type DiscoverCategory =
  | "quiet_cafe"
  | "dessert"
  | "local_food"
  | "photo_spot"
  | "culture";

type DiscoverRequest = {
  user_language?: string;
  base_location?: string;
  current_lat?: number | null;
  current_lng?: number | null;
  category?: DiscoverCategory;
  query?: string;
  limit?: number;
};

type DiscoverPlace = {
  id: string;
  name: string;
  subtitle: string;
  description: string;
  category: DiscoverCategory;
  tags: string[];
  image_url: string;
  local_image_asset?: string;
  latitude: number;
  longitude: number;
  walking_minutes: number;
  diversity_score: number;
  local_visit_ratio: number;
  crowd_level: string;
  risk_score: number;
  rating: number;
  review_count: number;
  kto_content_id: string;
  seoul_area_name: string;
  source_type: string;
  source_badge: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const ktoKeywordSearchUrl =
  "https://apis.data.go.kr/B551011/KorService2/searchKeyword2";

const categoryKeywords: Record<DiscoverCategory, string[]> = {
  quiet_cafe: ["조용한 카페", "한옥카페", "북카페", "정원카페"],
  dessert: ["디저트", "카페", "베이커리"],
  local_food: ["전통시장", "맛집", "분식", "로컬푸드"],
  photo_spot: ["사진명소", "전망대", "산책", "한옥"],
  culture: ["박물관", "전시관", "문화공간", "한옥"],
};

const fallbackPlaces: DiscoverPlace[] = [
  {
    id: "yeonnam-small-garden",
    name: "Yeonnam Small Garden",
    subtitle: "quiet garden cafe",
    description: "A calm garden cafe tucked behind Yeonnam streets.",
    category: "quiet_cafe",
    tags: ["Quiet", "Local pick", "Photo-friendly"],
    image_url: "",
    local_image_asset: "assets/images/discover/spot_garden_cafe.png",
    latitude: 37.5629,
    longitude: 126.9247,
    walking_minutes: 5,
    diversity_score: 92,
    local_visit_ratio: 68,
    crowd_level: "Low crowd",
    risk_score: 18,
    rating: 4.7,
    review_count: 128,
    kto_content_id: "",
    seoul_area_name: "HONGDAE",
    source_type: "local_fallback",
    source_badge: "Demo fallback",
  },
  {
    id: "dear-dessert",
    name: "Dear Dessert",
    subtitle: "handmade seasonal desserts",
    description: "A small dessert room with seasonal fruit and lighter waits.",
    category: "dessert",
    tags: ["Local pick", "Sweet spot", "Quiet"],
    image_url: "",
    local_image_asset: "assets/images/discover/spot_dessert.png",
    latitude: 37.5563,
    longitude: 126.9062,
    walking_minutes: 7,
    diversity_score: 88,
    local_visit_ratio: 76,
    crowd_level: "Low crowd",
    risk_score: 16,
    rating: 4.8,
    review_count: 96,
    kto_content_id: "",
    seoul_area_name: "MANGWON",
    source_type: "local_fallback",
    source_badge: "Demo fallback",
  },
  {
    id: "page-turn",
    name: "Page Turn",
    subtitle: "independent bookstore & cultural space",
    description: "A quiet bookstore cafe near galleries and old lanes.",
    category: "culture",
    tags: ["Cultural space", "Quiet", "Local pick"],
    image_url: "",
    local_image_asset: "assets/images/discover/spot_bookstore.png",
    latitude: 37.5798,
    longitude: 126.9694,
    walking_minutes: 9,
    diversity_score: 90,
    local_visit_ratio: 61,
    crowd_level: "Low crowd",
    risk_score: 22,
    rating: 4.6,
    review_count: 74,
    kto_content_id: "",
    seoul_area_name: "SEOCHON",
    source_type: "local_fallback",
    source_badge: "Demo fallback",
  },
  {
    id: "market-bowl",
    name: "Market Bowl",
    subtitle: "local food counter",
    description: "A simple market lunch counter with steady local traffic.",
    category: "local_food",
    tags: ["Local food", "High local ratio", "Low crowd"],
    image_url: "",
    local_image_asset: "assets/images/discover/spot_dessert.png",
    latitude: 37.5702,
    longitude: 126.9995,
    walking_minutes: 8,
    diversity_score: 86,
    local_visit_ratio: 72,
    crowd_level: "Low crowd",
    risk_score: 24,
    rating: 4.5,
    review_count: 88,
    kto_content_id: "",
    seoul_area_name: "GWANGJANG",
    source_type: "local_fallback",
    source_badge: "Demo fallback",
  },
  {
    id: "hanok-frame",
    name: "Hanok Frame",
    subtitle: "quiet photo lane",
    description: "A soft morning photo spot away from the main tour flow.",
    category: "photo_spot",
    tags: ["Photo-friendly", "Quiet", "Culture"],
    image_url: "",
    local_image_asset: "assets/images/discover/spot_garden_cafe.png",
    latitude: 37.5815,
    longitude: 126.9849,
    walking_minutes: 6,
    diversity_score: 89,
    local_visit_ratio: 64,
    crowd_level: "Low crowd",
    risk_score: 21,
    rating: 4.7,
    review_count: 112,
    kto_content_id: "",
    seoul_area_name: "BUKCHON",
    source_type: "local_fallback",
    source_badge: "Demo fallback",
  },
];

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return json({}, 200);
  }
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await request.json().catch(() => ({})) as DiscoverRequest;
    const category = normalizeCategory(body.category);
    const limit = clampLimit(body.limit);
    const query = (body.query ?? "").trim();
    const location = resolveLocation(body);
    const ktoServiceKey = Deno.env.get("KTO_SERVICE_KEY") ?? "";

    if (!ktoServiceKey) {
      return json(localResponse(category, query, limit, location.usedCurrentLocation), 200);
    }

    const ktoPlaces = await fetchKtoPlaces({
      category,
      query,
      limit,
      serviceKey: ktoServiceKey,
      centerLat: location.latitude,
      centerLng: location.longitude,
    });

    if (ktoPlaces.length === 0) {
      return json(localResponse(category, query, limit, location.usedCurrentLocation), 200);
    }

    const places = withCuratedFallback(ktoPlaces, category, query, limit);
    const supplemented = places.length > ktoPlaces.length;
    return json(
      {
        category,
        source_type: supplemented ? "kto_openapi_plus_local" : "kto_openapi",
        source_badge: supplemented ? "KTO + local fallback" : "KTO OpenAPI",
        used_current_location: location.usedCurrentLocation,
        places,
      },
      200,
    );
  } catch (error) {
    return json(
      {
        ...localResponse("quiet_cafe", "", 3),
        diagnostic: safeDiagnostic(error),
      },
      200,
    );
  }
});

async function fetchKtoPlaces(options: {
  category: DiscoverCategory;
  query: string;
  limit: number;
  serviceKey: string;
  centerLat: number;
  centerLng: number;
}): Promise<DiscoverPlace[]> {
  const keywords = options.query
    ? [options.query, ...categoryKeywords[options.category]]
    : categoryKeywords[options.category];
  const unique = [...new Set(keywords)].slice(0, 4);
  const places: DiscoverPlace[] = [];

  for (const keyword of unique) {
    const url = new URL(ktoKeywordSearchUrl);
    url.searchParams.set("serviceKey", options.serviceKey);
    url.searchParams.set("MobileOS", "ETC");
    url.searchParams.set("MobileApp", "NoriGo");
    url.searchParams.set("_type", "json");
    url.searchParams.set("numOfRows", "10");
    url.searchParams.set("pageNo", "1");
    url.searchParams.set("arrange", "O");
    url.searchParams.set("areaCode", "1");
    url.searchParams.set("keyword", keyword);

    const response = await fetch(url);
    if (!response.ok) continue;

    const payload = await response.json().catch(() => null);
    const items = payload?.response?.body?.items?.item;
    const rows = Array.isArray(items) ? items : items ? [items] : [];
    for (const row of rows) {
      const name = cleanText(row.title);
      const latitude = toNumber(row.mapy);
      const longitude = toNumber(row.mapx);
      if (!name || latitude === null || longitude === null) continue;
      if (places.some((place) => place.kto_content_id === String(row.contentid))) {
        continue;
      }

      const scoreSeed = places.length + keyword.length;
      const distance = distanceKm(
        options.centerLat,
        options.centerLng,
        latitude,
        longitude,
      );
      places.push({
        id: `kto-${row.contentid ?? slug(name)}`,
        name,
        subtitle: cleanText(row.addr1) || categorySubtitle(options.category),
        description:
          cleanText(row.addr1) ||
          "A lower-crowd Seoul recommendation from KTO OpenAPI.",
        category: options.category,
        tags: tagsForCategory(options.category),
        image_url: cleanText(row.firstimage) || cleanText(row.firstimage2),
        local_image_asset: "",
        latitude,
        longitude,
        walking_minutes: walkingMinutes(distance, scoreSeed),
        diversity_score: 86 + (scoreSeed % 8),
        local_visit_ratio: 61 + (scoreSeed % 18),
        crowd_level: "Low crowd",
        risk_score: 16 + (scoreSeed % 14),
        rating: Number((4.5 + (scoreSeed % 4) * 0.1).toFixed(1)),
        review_count: 72 + scoreSeed * 7,
        kto_content_id: String(row.contentid ?? ""),
        seoul_area_name: cleanText(row.addr1).split(" ")[1] ?? "SEOUL",
        source_type: "kto_openapi",
        source_badge: "KTO OpenAPI",
      });
      if (places.length >= options.limit) {
        return places.sort((a, b) =>
          distanceKm(options.centerLat, options.centerLng, a.latitude, a.longitude) -
          distanceKm(options.centerLat, options.centerLng, b.latitude, b.longitude)
        );
      }
    }
  }

  return places
    .sort((a, b) =>
      distanceKm(options.centerLat, options.centerLng, a.latitude, a.longitude) -
      distanceKm(options.centerLat, options.centerLng, b.latitude, b.longitude)
    )
    .slice(0, options.limit);
}

function localResponse(
  category: DiscoverCategory,
  query: string,
  limit: number,
  usedCurrentLocation = false,
) {
  const places = withCuratedFallback([], category, query, limit);
  return {
    category,
    source_type: "local_fallback",
    source_badge: "Demo fallback",
    used_current_location: usedCurrentLocation,
    places,
  };
}

function withCuratedFallback(
  preferred: DiscoverPlace[],
  category: DiscoverCategory,
  query: string,
  limit: number,
) {
  const normalizedQuery = query.toLowerCase();
  const categoryText = category.replace("_", " ");
  const filtered = fallbackPlaces.filter((place) => {
    const categoryMatch =
      place.category === category ||
      place.tags.some((tag) => tag.toLowerCase().includes(categoryText));
    const queryMatch =
      normalizedQuery.length === 0 ||
      place.name.toLowerCase().includes(normalizedQuery) ||
      place.subtitle.toLowerCase().includes(normalizedQuery) ||
      place.description.toLowerCase().includes(normalizedQuery) ||
      place.tags.some((tag) => tag.toLowerCase().includes(normalizedQuery));
    return categoryMatch && queryMatch;
  });
  const target = Math.max(3, limit);
  const places: DiscoverPlace[] = [];
  for (const place of [...preferred, ...filtered, ...fallbackPlaces]) {
    if (places.length >= target) break;
    if (places.some((item) => item.id === place.id)) continue;
    places.push(place);
  }
  return places.slice(0, target);
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function normalizeCategory(value?: string): DiscoverCategory {
  const normalized = (value ?? "quiet_cafe").toLowerCase();
  if (
    normalized === "dessert" ||
    normalized === "local_food" ||
    normalized === "photo_spot" ||
    normalized === "culture" ||
    normalized === "quiet_cafe"
  ) {
    return normalized;
  }
  return "quiet_cafe";
}

function clampLimit(value?: number) {
  if (!Number.isFinite(value ?? NaN)) return 10;
  return Math.min(Math.max(Math.trunc(value ?? 10), 3), 10);
}

function resolveLocation(body: DiscoverRequest) {
  const currentLat = toNumber(body.current_lat);
  const currentLng = toNumber(body.current_lng);
  if (isValidCoordinate(currentLat, currentLng)) {
    return {
      latitude: currentLat,
      longitude: currentLng,
      usedCurrentLocation: true,
    };
  }

  const base = baseCoordinates(body.base_location ?? "");
  return {
    latitude: base.latitude,
    longitude: base.longitude,
    usedCurrentLocation: false,
  };
}

function baseCoordinates(baseLocation: string) {
  const normalized = baseLocation.toLowerCase();
  if (normalized.includes("hongdae") || normalized.includes("홍대")) {
    return { latitude: 37.5563, longitude: 126.9236 };
  }
  if (normalized.includes("myeongdong") || normalized.includes("명동")) {
    return { latitude: 37.5636, longitude: 126.9820 };
  }
  if (normalized.includes("gangnam") || normalized.includes("강남")) {
    return { latitude: 37.4979, longitude: 127.0276 };
  }
  if (normalized.includes("gwanghwamun") || normalized.includes("광화문")) {
    return { latitude: 37.5759, longitude: 126.9768 };
  }
  if (normalized.includes("bukchon") || normalized.includes("북촌")) {
    return { latitude: 37.5815, longitude: 126.9849 };
  }
  return { latitude: 37.5665, longitude: 126.9780 };
}

function isValidCoordinate(lat: number | null, lng: number | null) {
  return (
    lat !== null &&
    lng !== null &&
    Math.abs(lat) <= 90 &&
    Math.abs(lng) <= 180 &&
    lat !== 0 &&
    lng !== 0
  );
}

function walkingMinutes(distance: number, seed: number) {
  if (!Number.isFinite(distance)) return 5 + (seed % 5);
  return Math.min(Math.max(Math.round(distance * 12), 4), 28);
}

function distanceKm(
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
) {
  const earthRadiusKm = 6371;
  const dLat = radians(toLat - fromLat);
  const dLng = radians(toLng - fromLng);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(radians(fromLat)) *
      Math.cos(radians(toLat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function radians(value: number) {
  return (value * Math.PI) / 180;
}

function tagsForCategory(category: DiscoverCategory) {
  switch (category) {
    case "dessert":
      return ["Local pick", "Sweet spot", "Quiet"];
    case "local_food":
      return ["Local food", "High local ratio", "Low crowd"];
    case "photo_spot":
      return ["Photo-friendly", "Quiet", "Culture"];
    case "culture":
      return ["Cultural space", "Quiet", "Local pick"];
    case "quiet_cafe":
    default:
      return ["Quiet", "Local pick", "Photo-friendly"];
  }
}

function categorySubtitle(category: DiscoverCategory) {
  switch (category) {
    case "dessert":
      return "handmade seasonal desserts";
    case "local_food":
      return "local food counter";
    case "photo_spot":
      return "quiet photo spot";
    case "culture":
      return "cultural space";
    case "quiet_cafe":
    default:
      return "quiet garden cafe";
  }
}

function cleanText(value: unknown) {
  if (typeof value !== "string") return "";
  return value.replace(/<[^>]+>/g, "").trim();
}

function toNumber(value: unknown) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function slug(value: string) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

function safeDiagnostic(error: unknown) {
  return error instanceof Error ? error.message.slice(0, 160) : "unknown error";
}
