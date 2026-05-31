param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  Write-Error "Set SUPABASE_URL and SUPABASE_ANON_KEY before running this smoke test."
}

$endpoint = $SupabaseUrl.TrimEnd("/") + "/functions/v1/ennoia-retrip"
$headers = @{
  "apikey" = $SupabaseAnonKey
  "Authorization" = "Bearer $SupabaseAnonKey"
  "Content-Type" = "application/json; charset=utf-8"
}

$profiles = @(
  @{
    name = "A Palace crowd spike"
    body = @{
      plan_id = "00000000-0000-4000-8000-000000000001"
      original_item_id = "gyeongbokgung-palace"
      user_language = "English"
      current_location = "Jongno, Seoul"
      original_place = "Gyeongbokgung Palace"
      original_place_type = "Palace"
      original_place_value = "Palace, hanok village, traditional culture"
      scheduled_time = "09:00"
      trigger_type = "crowd_spike"
      crowd_level = "Very High"
      estimated_wait = "40-60 min"
      user_preference = "Quiet to Moderate, nearby cultural alternative"
    }
  },
  @{
    name = "B Cafe crowd spike"
    body = @{
      plan_id = "00000000-0000-4000-8000-000000000002"
      original_item_id = "hongdae-cafe"
      user_language = "English"
      current_location = "Hongdae, Seoul"
      original_place = "Hongdae Cafe"
      original_place_type = "Cafe"
      original_place_value = "Cafe, K-pop, shopping"
      scheduled_time = "13:00"
      trigger_type = "queue_full"
      crowd_level = "Very High"
      estimated_wait = "40-60 min"
      user_preference = "Lively, K-pop, shopping, cafe"
    }
  },
  @{
    name = "C Night view crowd spike"
    body = @{
      plan_id = "00000000-0000-4000-8000-000000000003"
      original_item_id = "gangnam-night-view"
      user_language = "English"
      current_location = "Gangnam, Seoul"
      original_place = "Gangnam Night View"
      original_place_type = "Night view"
      original_place_value = "Night view, shopping, couple, cafe"
      scheduled_time = "18:30"
      trigger_type = "crowd_spike"
      crowd_level = "High"
      estimated_wait = "30-45 min"
      user_preference = "Moderate, couple-friendly, cafe, shopping"
    }
  }
)

foreach ($profile in $profiles) {
  Write-Host ""
  Write-Host "=== $($profile.name) ==="
  $jsonBody = $profile.body | ConvertTo-Json -Depth 8
  try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $jsonBody -TimeoutSec 60
    $names = @($response.alternatives | ForEach-Object {
      if ($_.place_name) { $_.place_name } else { $_.name }
    })
    $ids = @($response.alternatives | ForEach-Object {
      if ($_.kto_content_id) { $_.kto_content_id }
      elseif ($_.content_id) { $_.content_id }
      else { $_.contentid }
    })

    Write-Host "source_type: $($response.source_type)"
    Write-Host "source_badge: $($response.source_badge)"
    Write-Host "source_note: $($response.source_note)"
    Write-Host "ennoia_error_code: $($response.ennoia_error_code)"
    Write-Host "persisted: $($response.persisted)"
    Write-Host "retripEventId: $($response.retripEventId)"
    Write-Host "alternativeCount: $(@($response.alternatives).Count)"
    Write-Host "place names: $($names -join ', ')"
    Write-Host "content IDs: $($ids -join ', ')"
  } catch {
    $message = $_.Exception.Message
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      $message = $_.ErrorDetails.Message
    }
    Write-Host "ERROR: $($message.Substring(0, [Math]::Min(500, $message.Length)))"
  }
}
