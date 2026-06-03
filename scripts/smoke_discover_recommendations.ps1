param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY,
  [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "Set SUPABASE_URL and SUPABASE_ANON_KEY before running this smoke test."
}

$authorizationToken = if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  $SupabaseAnonKey
} else {
  $AccessToken
}

$endpoint = $SupabaseUrl.TrimEnd("/") + "/functions/v1/discover-recommendations"
$categories = @("quiet_cafe", "dessert", "local_food", "photo_spot", "culture")

foreach ($category in $categories) {
  $body = @{
    user_language = "English"
    base_location = "Myeongdong, Seoul"
    current_lat = $null
    current_lng = $null
    category = $category
    query = ""
    limit = 10
  } | ConvertTo-Json -Depth 8 -Compress

  $env:NORIGO_DISCOVER_ENDPOINT = $endpoint
  $env:NORIGO_DISCOVER_ANON_KEY = $SupabaseAnonKey
  $env:NORIGO_DISCOVER_AUTH_TOKEN = $authorizationToken
  $env:NORIGO_DISCOVER_BODY = $body

  $responseText = & node -e @"
const endpoint = process.env.NORIGO_DISCOVER_ENDPOINT;
const anonKey = process.env.NORIGO_DISCOVER_ANON_KEY;
const authToken = process.env.NORIGO_DISCOVER_AUTH_TOKEN || anonKey;
const body = process.env.NORIGO_DISCOVER_BODY;

(async () => {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      apikey: anonKey,
      authorization: 'Bearer ' + authToken,
      'content-type': 'application/json',
    },
    body,
  });
  const text = await response.text();
  if (!response.ok) {
    console.error(text);
    process.exit(response.status);
  }
  process.stdout.write(text);
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
"@

  if ($LASTEXITCODE -ne 0) {
    throw "discover-recommendations request failed for $category."
  }

  $response = $responseText | ConvertFrom-Json
  $places = @($response.places)
  $names = @($places | Select-Object -First 3 | ForEach-Object { $_.name })
  $contentIdCount = @($places | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.kto_content_id) }).Count
  $coordinateCount = @($places | Where-Object {
    $_.latitude -ne $null -and $_.longitude -ne $null -and
    [double]$_.latitude -ne 0 -and [double]$_.longitude -ne 0
  }).Count

  Write-Host ""
  Write-Host "status: ok"
  Write-Host "category: $($response.category)"
  Write-Host "source_type: $($response.source_type)"
  Write-Host "source_badge: $($response.source_badge)"
  Write-Host "place count: $($places.Count)"
  Write-Host "first 3 place names: $($names -join ', ')"
  Write-Host "KTO content id count: $contentIdCount"
  Write-Host "map coordinate count: $coordinateCount"
}
