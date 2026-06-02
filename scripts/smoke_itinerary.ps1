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

$profiles = @(
  @{
    name = "A"
    body = @{
      preferred_language = "English"
      user_language = "English"
      destination = "South Korea"
      base_location = "Myeongdong, Seoul"
      travel_date = "May 18, Sun"
      trip_days = "1"
      interests = "Palace, Hanok village, Traditional market"
      companion_type = "Solo"
      crowd_preference = "Quiet to Moderate"
      food_needs = "None"
    }
  },
  @{
    name = "B"
    body = @{
      preferred_language = "English"
      user_language = "English"
      destination = "South Korea"
      base_location = "Hongdae, Seoul"
      travel_date = "May 18, Sun"
      trip_days = "1"
      interests = "K-pop, Shopping, Cafe"
      companion_type = "Friends"
      crowd_preference = "Lively"
      food_needs = "None"
    }
  },
  @{
    name = "C"
    body = @{
      preferred_language = "English"
      user_language = "English"
      destination = "South Korea"
      base_location = "Gangnam, Seoul"
      travel_date = "May 18, Sun"
      trip_days = "1"
      interests = "Night view, Shopping, Couple, Cafe"
      companion_type = "Couple"
      crowd_preference = "Moderate"
      food_needs = "None"
    }
  }
)

$authorizationToken = if ([string]::IsNullOrWhiteSpace($AccessToken)) {
  $SupabaseAnonKey
} else {
  $AccessToken
}

$headers = @{
  apikey = $SupabaseAnonKey
  Authorization = "Bearer $authorizationToken"
  "Content-Type" = "application/json"
}
$endpoint = $SupabaseUrl.TrimEnd("/") + "/functions/v1/ennoia-itinerary"
$routeSignatures = @()
$shouldPersistUserId = -not [string]::IsNullOrWhiteSpace($AccessToken)

if ($shouldPersistUserId) {
  Write-Host "Authenticated smoke: itinerary user_id should be persisted."
} else {
  Write-Host "Unauthenticated smoke: user_id may be null."
}

function First-TextValue {
  param(
    [Parameter(Mandatory = $true)] $Object,
    [Parameter(Mandatory = $true)] [string[]] $Names
  )

  foreach ($name in $Names) {
    $value = $Object.$name
    if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
      return [string]$value
    }
  }
  return ""
}

foreach ($profile in $profiles) {
  $env:NORIGO_SMOKE_ENDPOINT = $endpoint
  $env:NORIGO_SMOKE_ANON_KEY = $SupabaseAnonKey
  $env:NORIGO_SMOKE_AUTH_TOKEN = $authorizationToken
  $env:NORIGO_SMOKE_BODY = $profile.body | ConvertTo-Json -Depth 8 -Compress
  $responseText = & node -e @"
const endpoint = process.env.NORIGO_SMOKE_ENDPOINT;
const anonKey = process.env.NORIGO_SMOKE_ANON_KEY;
const authToken = process.env.NORIGO_SMOKE_AUTH_TOKEN || anonKey;
const body = process.env.NORIGO_SMOKE_BODY;

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
    throw "request failed for profile $($profile.name)."
  }

  $response = $responseText | ConvertFrom-Json

  $items = @($response.items)
  $names = @($items | ForEach-Object {
    First-TextValue -Object $_ -Names @("place_name", "placeName", "name")
  })
  $contentIds = @($items | ForEach-Object {
    First-TextValue -Object $_ -Names @("kto_content_id", "contentId", "content_id", "contentid")
  } | Where-Object { $_ })
  $signature = ($names | Sort-Object) -join "|"
  $routeSignatures += $signature

  Write-Host ""
  Write-Host "Profile $($profile.name)"
  Write-Host "source_type: $($response.source_type)"
  Write-Host "source_badge: $($response.source_badge)"
  Write-Host "itemCount: $($items.Count)"
  Write-Host "ktoContentIdCount: $($contentIds.Count)"
  Write-Host "authenticated: $($response.authenticated)"
  Write-Host "userIdReturned: $(-not [string]::IsNullOrWhiteSpace([string]$response.user_id))"
  Write-Host "place names: $($names -join ', ')"
  Write-Host "content IDs: $($contentIds -join ', ')"
}

$uniqueRouteCount = @($routeSignatures | Sort-Object -Unique).Count
Write-Host ""
if ($uniqueRouteCount -eq 1) {
  Write-Host "WARNING: onboarding preferences may not be affecting itinerary generation."
} else {
  Write-Host "Routes are different across profiles."
}
