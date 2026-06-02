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

$headers = @{
  apikey = $SupabaseAnonKey
  Authorization = "Bearer $authorizationToken"
  "Content-Type" = "application/json"
}
$endpoint = $SupabaseUrl.TrimEnd("/") + "/functions/v1/ennoia-culture-guide"

$cases = @(
  @{
    name = "Bulguksa stone stack"
    body = @{
      user_language = "English"
      current_location = "Bulguksa"
      place_type = "temple"
      detected_object = "temple_stone_stack"
      korean_keyword = "소원 성취"
      user_intent = "Understand local culture and etiquette"
      user_question = "Why do Koreans stack stones here?"
      image_path = $null
    }
  },
  @{
    name = "Korean restaurant call bell"
    body = @{
      user_language = "English"
      current_location = "Korean restaurant"
      place_type = "restaurant"
      detected_object = "restaurant_call_bell"
      korean_keyword = "여기요"
      user_intent = "Understand local culture and etiquette"
      user_question = "Is it polite to press the call bell?"
      image_path = $null
    }
  },
  @{
    name = "Seoul subway pregnant seat"
    body = @{
      user_language = "English"
      current_location = "Seoul subway"
      place_type = "subway"
      detected_object = "subway_pregnant_seat"
      korean_keyword = "임산부 배려석"
      user_intent = "Understand local culture and etiquette"
      user_question = "Can I sit in the pink subway seat?"
      image_path = $null
    }
  },
  @{
    name = "Cafe kiosk ordering"
    body = @{
      user_language = "English"
      current_location = "Cafe"
      place_type = "cafe"
      detected_object = "kiosk_ordering"
      korean_keyword = "도와주실 수 있나요?"
      user_intent = "Understand local culture and etiquette"
      user_question = "Should I order at the kiosk?"
      image_path = $null
    }
  },
  @{
    name = "Gwangjang Market cash food"
    body = @{
      user_language = "English"
      current_location = "Gwangjang Market"
      place_type = "market"
      detected_object = "market_cash_food"
      korean_keyword = "카드 돼요?"
      user_intent = "Understand local culture and etiquette"
      user_question = "Can I pay by card and eat while walking?"
      image_path = $null
    }
  }
)

foreach ($case in $cases) {
  $body = $case.body | ConvertTo-Json -Depth 8
  $status = 0
  $responseText = ""

  try {
    $raw = Invoke-WebRequest -Uri $endpoint -Method Post -Headers $headers -Body $body -UseBasicParsing
    $status = [int]$raw.StatusCode
    $responseText = [string]$raw.Content
  } catch {
    if ($_.Exception.Response) {
      $status = [int]$_.Exception.Response.StatusCode
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $responseText = $reader.ReadToEnd()
    } else {
      throw
    }
  }

  $response = $null
  if (-not [string]::IsNullOrWhiteSpace($responseText)) {
    $response = $responseText | ConvertFrom-Json
  }

  Write-Host ""
  Write-Host $case.name
  Write-Host "status: $status"
  Write-Host "source_type: $($response.source_type)"
  Write-Host "source_badge: $($response.source_badge)"
  Write-Host "question: $($response.question)"
  Write-Host "korean_phrase: $($response.korean_phrase)"
  Write-Host "persisted: $($response.persisted)"
  Write-Host "cultureScanRecordId: $($response.cultureScanRecordId)"
  Write-Host "scope_limited: $($response.scope_limited)"
}
