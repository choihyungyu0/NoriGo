type RetripRequest = {
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

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
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
  const hash = Deno.env.get("ENNOIA_RETRIP_HASH");

  if (!endpoint || !project || !apiKey || !hash) {
    return jsonResponse(mockRetrip(), 200);
  }

  const params = bodyResult.body as RetripRequest;
  const ennoiaPayload = {
    hash,
    params,
    messages: [
      {
        role: "user",
        content:
          "Use Korea Tourism Organization MCP to recommend three nearby alternatives. Return exactly 3 alternatives in valid JSON.",
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
      "ennoia retrip request failed",
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

function mockRetrip() {
  return {
    source: "mock",
    id: "cafe-arte-crowd-alert",
    originalPlace: "Cafe Arte",
    scheduledTime: "13:00",
    crowdLevel: "Very High",
    estimatedWait: "40-60 min",
    alertMessage: "Cafe Arte may become very busy within 30 minutes.",
    foreignerQueueTip:
      "Even if no visible line, app-based queues may already be full.",
    alternatives: [
      {
        id: "cafe-owall",
        name: "Cafe Owall",
        description: "Dessert in a calm hanok alley",
        walkingTime: "5 min walk",
        diversityScore: 92,
        crowdLevel: "Low",
      },
      {
        id: "seosullan-small-book-cafe",
        name: "Seosullan Small Book Cafe",
        description: "Quiet book cafe beloved by locals",
        walkingTime: "7 min walk",
        diversityScore: 88,
        crowdLevel: "Low",
      },
      {
        id: "yunsul-bakery",
        name: "Yunsul Bakery",
        description: "Local favorite bakery with short wait",
        walkingTime: "8 min walk",
        diversityScore: 90,
        crowdLevel: "Low",
      },
    ],
  };
}
