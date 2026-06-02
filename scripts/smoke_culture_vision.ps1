param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY,
  [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN,
  [string]$ImagePath = $env:CULTURE_SCAN_IMAGE_PATH
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  throw "Set SUPABASE_URL."
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "Set SUPABASE_ANON_KEY."
}

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
$endpoint = $SupabaseUrl.TrimEnd("/") + "/functions/v1/culture-vision-detect"

$cases = @(
  @{
    mode = "heuristic_no_image"
    body = @{
      current_location = "Bulguksa"
      user_language = "English"
      hint_place_type = "temple"
    }
  },
  @{
    mode = "heuristic_with_image_path"
    body = @{
      image_path = if ([string]::IsNullOrWhiteSpace($ImagePath)) {
        "00000000-0000-0000-0000-000000000000/fake.jpg"
      } else {
        $ImagePath
      }
      current_location = "Gwangjang Market"
      user_language = "English"
      hint_place_type = "market"
    }
  }
)

foreach ($case in $cases) {
  $status = 0
  $responseText = ""
  try {
    $response = Invoke-WebRequest `
      -Uri $endpoint `
      -Method Post `
      -Headers $headers `
      -Body ($case.body | ConvertTo-Json -Depth 8 -Compress) `
      -UseBasicParsing `
      -TimeoutSec 30
    $status = [int]$response.StatusCode
    $responseText = $response.Content
  } catch {
    if ($_.Exception.Response) {
      $status = [int]$_.Exception.Response.StatusCode
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $responseText = $reader.ReadToEnd()
    } else {
      throw
    }
  }

  $payload = if ([string]::IsNullOrWhiteSpace($responseText)) {
    $null
  } else {
    $responseText | ConvertFrom-Json
  }

  Write-Host ""
  Write-Host "mode: $($case.mode)"
  Write-Host "status: $status"
  Write-Host "detected_object: $($payload.detected_object)"
  Write-Host "place_type: $($payload.place_type)"
  Write-Host "confidence: $($payload.confidence)"
  Write-Host "needs_confirmation: $($payload.needs_confirmation)"
  Write-Host "source_type: $($payload.source_type)"
  Write-Host "source_badge: $($payload.source_badge)"
}
