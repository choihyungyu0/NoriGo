param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  Write-Host "Set SUPABASE_URL and SUPABASE_ANON_KEY before running this smoke test."
  Write-Host "Example:"
  Write-Host '$env:SUPABASE_URL="https://your-project.supabase.co"'
  Write-Host '$env:SUPABASE_ANON_KEY="your-anon-key"'
  exit 1
}

if ([string]::IsNullOrWhiteSpace($env:SEOUL_CITYDATA_API_KEY)) {
  Write-Host "SEOUL_CITYDATA_API_KEY is not set in this shell."
  Write-Host "This script does not send the key from Flutter or PowerShell; configure it as a Supabase Edge Function secret:"
  Write-Host "supabase secrets set SEOUL_CITYDATA_API_KEY=your-seoul-openapi-key"
  Write-Host ""
}

$endpoint = $SupabaseUrl.TrimEnd("/") + "/functions/v1/seoul-realtime-risk"
$headers = @{
  "apikey" = $SupabaseAnonKey
  "Authorization" = "Bearer $SupabaseAnonKey"
  "Content-Type" = "application/json; charset=utf-8"
}

$places = @(
  "Bukchon Hanok Village",
  "Gyeongbokgung Palace",
  "Gwangjang Market",
  "Myeongdong",
  "Hongdae"
)

foreach ($place in $places) {
  Write-Host ""
  Write-Host "=== $place ==="
  $body = @{
    current_lat = $null
    current_lng = $null
    current_place_name = $null
    scheduled_place_name = $place
    scheduled_time = "14:00"
    trigger_context = "itinerary_check"
  } | ConvertTo-Json -Depth 8

  try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $body -TimeoutSec 60
    Write-Host "status: ok"
    Write-Host "area_nm: $($response.area_nm)"
    Write-Host "congestion_level: $($response.congestion_level)"
    Write-Host "risk_score: $($response.risk_score)"
    Write-Host "risk_level: $($response.risk_level)"
    Write-Host "should_alert: $($response.should_alert)"
    Write-Host "source_type: $($response.source_type)"
    Write-Host "source_badge: $($response.source_badge)"
    Write-Host "risk_reason: $($response.risk_reason)"
  } catch {
    $message = $_.Exception.Message
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      $message = $_.ErrorDetails.Message
    }
    Write-Host "status: error"
    Write-Host "risk_reason: $($message.Substring(0, [Math]::Min(500, $message.Length)))"
  }
}
