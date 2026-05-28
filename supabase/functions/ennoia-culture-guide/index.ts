type CultureRequest = {
  user_language: string;
  current_location: string;
  detected_object: string;
  korean_keyword: string;
  user_intent: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const requiredFields: Array<keyof CultureRequest> = [
  "user_language",
  "current_location",
  "detected_object",
  "korean_keyword",
  "user_intent",
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
  const hash = Deno.env.get("ENNOIA_CULTURE_HASH");

  if (!endpoint || !project || !apiKey || !hash) {
    return jsonResponse(mockCultureGuide(), 200);
  }

  const params = bodyResult.body as CultureRequest;
  const ennoiaPayload = {
    hash,
    params,
    messages: [
      {
        role: "user",
        content: "Generate a practical culture guide for a foreign tourist.",
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
      "ennoia culture guide request failed",
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

function mockCultureGuide() {
  return {
    source: "mock",
    locationName: "Bulguksa",
    detectedObject: "Stone stack",
    koreanSource: "소원성취",
    translation: "Wishing for your hopes to come true.",
    title: "AI Culture Guide",
    question: "Why do Koreans stack stones here?",
    description:
      "Stone stacking at Bulguksa expresses wishes for happiness, health, and success, and is a tradition passed down for centuries.",
    meaning: "Each stone carries a wish.",
    etiquette: "Do not knock down existing stones. Add your stone with respect.",
    story:
      "This tradition comes from ancient Buddhist beliefs and the hope for peace and well-being.",
  };
}
