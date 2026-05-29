Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$supabaseUrl = $env:SUPABASE_URL
$anonKey = $env:SUPABASE_ANON_KEY

if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
  throw "SUPABASE_URL environment variable is required."
}

if ([string]::IsNullOrWhiteSpace($anonKey)) {
  throw "SUPABASE_ANON_KEY environment variable is required."
}

$baseUrl = $supabaseUrl.TrimEnd("/")
$uri = "$baseUrl/functions/v1/ennoia-itinerary"

$body = @{
  user_language = "English"
  trip_days = "1"
  base_location = "Myeongdong, Seoul"
  travel_date = "May 18, Sun"
  interests = "Palace, Hanok village, Traditional market, Dessert cafe, Photo spot, Night view"
  companion_type = "Solo"
  crowd_preference = "Quiet to Moderate"
} | ConvertTo-Json

$headers = @{
  Authorization = "Bearer $anonKey"
  apikey = $anonKey
}

function Get-JsonProperty($Object, [string]$Name) {
  if ($null -eq $Object) {
    return $null
  }

  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

try {
  $response = Invoke-WebRequest `
    -Uri $uri `
    -Method Post `
    -Headers $headers `
    -ContentType "application/json; charset=utf-8" `
    -Body $body `
    -UseBasicParsing
} catch {
  if ($_.Exception.Response -eq $null) {
    throw
  }

  $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
  $errorBody = $reader.ReadToEnd()
  throw "Smoke test request failed with status $([int]$_.Exception.Response.StatusCode): $errorBody"
}

$payload = $response.Content | ConvertFrom-Json
$items = @()
$rootItems = Get-JsonProperty $payload "items"
$nestedItinerary = Get-JsonProperty $payload "itinerary"
$nestedItems = Get-JsonProperty $nestedItinerary "items"
if ($rootItems -ne $null) {
  $items = @($rootItems)
} elseif ($nestedItems -ne $null) {
  $items = @($nestedItems)
}

$contentIds = @(
  $items | ForEach-Object {
    $id = Get-JsonProperty $_ "kto_content_id"
    if ($null -eq $id) { $id = Get-JsonProperty $_ "ktoContentId" }
    if ($null -eq $id) { $id = Get-JsonProperty $_ "contentId" }
    if ($null -eq $id) { $id = Get-JsonProperty $_ "contentid" }
    $id
  } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
)

$result = [pscustomobject]@{
  status = [int]$response.StatusCode
  source_type = $(if (Get-JsonProperty $payload "source_type") {
    Get-JsonProperty $payload "source_type"
  } else {
    Get-JsonProperty $payload "sourceType"
  })
  persisted = Get-JsonProperty $payload "persisted"
  itemCount = $items.Count
  ktoContentIdCount = $contentIds.Count
  uniqueKtoContentIdCount = @($contentIds | Sort-Object -Unique).Count
  persistedPlanId = Get-JsonProperty $payload "persistedPlanId"
}

$result | Format-List

if ($result.status -lt 200 -or $result.status -gt 299) {
  throw "Expected a 2xx status."
}
if ($result.source_type -ne "kto_openapi_ennoia") {
  throw "Expected source_type kto_openapi_ennoia."
}
if ($result.itemCount -ne 5) {
  throw "Expected exactly 5 itinerary items."
}
if ($result.ktoContentIdCount -lt 3) {
  throw "Expected at least 3 KTO content IDs."
}
if ($result.persisted -ne $true) {
  throw "Expected persisted to be true."
}
