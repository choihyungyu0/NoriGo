type ItineraryRequest = {
  user_language: string;
  trip_days: string;
  base_location: string;
  travel_date: string;
  interests: string;
  companion_type: string;
  crowd_preference: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
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

Deno.serve(async (request) => {
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

  const endpoint = Deno.env.get("ENNOIA_API_ENDPOINT");
  const project = Deno.env.get("ENNOIA_PROJECT");
  const apiKey = Deno.env.get("ENNOIA_API_KEY");
  const hash = Deno.env.get("ENNOIA_ITINERARY_HASH");

  if (!endpoint || !project || !apiKey || !hash) {
    return jsonResponse(mockItinerary(), 200);
  }

  const params = bodyResult.body as ItineraryRequest;
  const ennoiaPayload = {
    hash,
    params,
    messages: [
      {
        role: "user",
        content:
          "Use Korea Tourism Organization MCP to recommend a one-day Seoul itinerary. Convert interests into Korean search keywords and return exactly 5 itinerary items in valid JSON.",
      },
    ],
  };

  try {
    const ennoiaResponse = await fetch(endpoint, {
      method: "POST",
      headers: {
        project,
        apiKey,
        "Content-Type": "application/json; charset=utf-8",
      },
      body: JSON.stringify(ennoiaPayload),
    });

    return new Response(await ennoiaResponse.text(), {
      status: ennoiaResponse.status,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json; charset=utf-8",
      },
    });
  } catch (error) {
    console.error(
      "ennoia itinerary request failed",
      error instanceof Error ? error.message : "unknown error",
    );
    return jsonResponse({ error: "Unable to reach ennoia." }, 502);
  }
});

async function readJsonBody(
  request: Request,
): Promise<{ ok: true; body: Record<string, unknown> } | {
  ok: false;
  error: string;
}> {
  try {
    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return { ok: false, error: "Request body must be a JSON object." };
    }
    return { ok: true, body: body as Record<string, unknown> };
  } catch (_) {
    return { ok: false, error: "Request body must be valid JSON." };
  }
}

function validateFields(
  body: Record<string, unknown>,
  fields: string[],
): string | null {
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

function mockItinerary() {
  return {
    source: "mock",
    id: "mock-seoul-one-day",
    dateLabel: "May 18, Sun",
    title: "AI Itinerary Planner",
    estimatedTimeSaved: "1h 25m",
    items: [
      {
        id: "gyeongbokgung-palace",
        order: 1,
        time: "09:00",
        placeName: "Gyeongbokgung Palace",
        crowdLevel: "low",
        stayTime: "Stay 1h 30m",
        aiTip: "Best time to enter!",
      },
      {
        id: "bukchon-hanok-village",
        order: 2,
        time: "11:00",
        placeName: "Bukchon Hanok Village",
        crowdLevel: "moderate",
        stayTime: "Stay 1h",
        aiTip: "Explore quiet alleyways",
      },
      {
        id: "dessert-cafe",
        order: 3,
        time: "13:00",
        placeName: "Dessert Cafe",
        crowdLevel: "low",
        stayTime: "Stay 1h",
        aiTip: "Perfect time for a break",
      },
      {
        id: "seongsu-select-shop",
        order: 4,
        time: "15:00",
        placeName: "Seongsu Select Shop",
        crowdLevel: "moderate",
        stayTime: "Stay 1h 30m",
        aiTip: "Trendy finds in Seongsu",
      },
      {
        id: "n-seoul-tower",
        order: 5,
        time: "18:30",
        placeName: "N Seoul Tower",
        crowdLevel: "low",
        stayTime: "Stay 1h",
        aiTip: "Catch the best sunset view",
        extraBadge: "Sunset view",
      },
    ],
  };
}
