param()

$ErrorActionPreference = "Stop"

$required = @(
  "ENNOIA_API_ENDPOINT",
  "ENNOIA_PROJECT",
  "ENNOIA_API_KEY",
  "ENNOIA_ITINERARY_API_HASH"
)

foreach ($name in $required) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    throw "Set $name before running this smoke test."
  }
}

$ktoData = @(
  @{
    title = "Deoksugung Daehanmun"
    contentid = "1605981"
    contenttypeid = "12"
    addr1 = "Seoul Jung-gu"
    matched_interest = "Palace"
  },
  @{
    title = "Hanboknam Gyeongbokgung"
    contentid = "2390314"
    contenttypeid = "38"
    addr1 = "Seoul Jongno-gu"
    matched_interest = "Hanok village"
  },
  @{
    title = "Gwangjang Market"
    contentid = "132183"
    contenttypeid = "38"
    addr1 = "Seoul Jongno-gu"
    matched_interest = "Traditional market"
  },
  @{
    title = "Namsangol Hanok Village"
    contentid = "126747"
    contenttypeid = "12"
    addr1 = "Seoul Jung-gu"
    matched_interest = "Hanok village"
  },
  @{
    title = "Bukchon Hanok Village"
    contentid = "126537"
    contenttypeid = "12"
    addr1 = "Seoul Jongno-gu"
    matched_interest = "Hanok village"
  }
)
$ktoDataJson = $ktoData | ConvertTo-Json -Depth 8 -Compress

$prompt = @"
Use only the provided KTO_DATA.
Do not call tools.
Do not invent place names.
Do not invent kto_content_id.
Return valid JSON only.
Return exactly 5 items.
Each item must preserve the selected KTO contentid as kto_content_id.
If a field is unknown, use an empty string.
$( @{ KTO_DATA = $ktoData } | ConvertTo-Json -Depth 8 -Compress )
"@

$body = @{
  hash = $env:ENNOIA_ITINERARY_API_HASH
  params = @{
    user_language = "English"
    preferred_language = "English"
    destination = "South Korea"
    trip_days = "1"
    base_location = "Myeongdong, Seoul"
    travel_date = "May 18, Sun"
    interests = "Palace, Hanok village, Traditional market"
    companion_type = "Solo"
    crowd_preference = "Quiet to Moderate"
    food_needs = "None"
    KTO_DATA = $ktoDataJson
  }
  messages = @(
    @{
      role = "user"
      content = $prompt
    }
  )
} | ConvertTo-Json -Depth 10 -Compress

$env:NORIGO_ENNOIA_ENDPOINT = $env:ENNOIA_API_ENDPOINT
$env:NORIGO_ENNOIA_PROJECT = $env:ENNOIA_PROJECT
$env:NORIGO_ENNOIA_API_KEY = $env:ENNOIA_API_KEY
$env:NORIGO_ENNOIA_BODY = $body

& node -e @'
const endpoint = process.env.NORIGO_ENNOIA_ENDPOINT;
const project = process.env.NORIGO_ENNOIA_PROJECT;
const apiKey = process.env.NORIGO_ENNOIA_API_KEY;
const body = process.env.NORIGO_ENNOIA_BODY;

function redact(text) {
  return String(text || '')
    .replace(/Bearer\s+[A-Za-z0-9._-]+/g, 'Bearer [redacted]')
    .replace(/("?apiKey"?\s*[:=]\s*")([^"]+)(")/gi, '$1[redacted]$3')
    .replace(/("?apikey"?\s*[:=]\s*")([^"]+)(")/gi, '$1[redacted]$3')
    .replace(/("?authorization"?\s*[:=]\s*")([^"]+)(")/gi, '$1[redacted]$3');
}

function stripFence(text) {
  return String(text || '').trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();
}

function extractObject(text) {
  const value = stripFence(text);
  try {
    return JSON.parse(value);
  } catch {}
  let start = -1;
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = 0; i < value.length; i += 1) {
    const char = value[i];
    if (start === -1) {
      if (char === '{') {
        start = i;
        depth = 1;
      }
      continue;
    }
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char === '\\') {
      escaped = inString;
      continue;
    }
    if (char === '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (char === '{') depth += 1;
    if (char === '}') depth -= 1;
    if (depth === 0) {
      try {
        return JSON.parse(value.slice(start, i + 1));
      } catch {
        return null;
      }
    }
  }
  return null;
}

function textFromParts(parts) {
  if (!Array.isArray(parts)) return '';
  return parts.map((part) => {
    if (typeof part === 'string') return part;
    if (part && typeof part === 'object') {
      return part.text || part.output_text || part.content || '';
    }
    return '';
  }).join('');
}

function parsePayload(raw) {
  let decoded;
  try {
    decoded = JSON.parse(raw);
  } catch {
    return extractObject(raw);
  }
  const data = decoded.data || decoded;
  const choice = Array.isArray(data.choices) ? data.choices[0] : undefined;
  const content =
    choice?.message?.content ??
    data.message?.content ??
    data.output_text ??
    data.content ??
    data.data;
  if (typeof content === 'string') return extractObject(content);
  if (Array.isArray(content)) return extractObject(textFromParts(content));
  if (content && typeof content === 'object') return content;
  return decoded;
}

(async () => {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      project,
      apiKey,
      'X-ENNOIA-USER-ID': 'norigo-smoke-test',
      'content-type': 'application/json; charset=utf-8',
    },
    body,
  });
  const text = await response.text();
  const payload = parsePayload(text);
  const items = Array.isArray(payload?.items) ? payload.items : [];
  const first = items[0] || {};

  console.log(`status: ${response.status} ${response.statusText}`);
  console.log(`parsed item count: ${items.length}`);
  console.log(`first place name: ${first.place_name || first.placeName || first.name || ''}`);
  console.log(`first kto_content_id: ${first.kto_content_id || first.contentid || first.contentId || ''}`);
  if (!response.ok || items.length === 0) {
    console.log(`raw error preview: ${redact(text).slice(0, 500)}`);
    process.exit(response.ok ? 0 : 1);
  }
})().catch((error) => {
  console.log('status: request failed');
  console.log('parsed item count: 0');
  console.log('first place name: ');
  console.log('first kto_content_id: ');
  console.log(`raw error preview: ${redact(error.message).slice(0, 500)}`);
  process.exit(1);
});
'@
