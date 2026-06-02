param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY,
  [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN,
  [switch]$DebugDiagnostics
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
if ($DebugDiagnostics) {
  $headers["x-culture-debug"] = "true"
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

function Get-TextFromContentParts($parts) {
  $texts = @()
  foreach ($part in $parts) {
    if ($part -is [string]) {
      $texts += $part
    } elseif ($null -ne $part.text) {
      $texts += [string]$part.text
    } elseif ($null -ne $part.content) {
      $texts += [string]$part.content
    }
  }
  return ($texts -join "`n")
}

function ConvertFrom-CultureContent($content) {
  if ($null -eq $content) {
    return $null
  }
  if ($content -isnot [string]) {
    return $content
  }

  $trimmed = $content.Trim()
  $trimmed = $trimmed -replace "^```(?:json)?\s*", ""
  $trimmed = $trimmed -replace "\s*```$", ""

  try {
    return $trimmed | ConvertFrom-Json
  } catch {
    $start = $trimmed.IndexOf("{")
    $end = $trimmed.LastIndexOf("}")
    if ($start -ge 0 -and $end -gt $start) {
      return $trimmed.Substring($start, $end - $start + 1) | ConvertFrom-Json
    }
  }
  return $null
}

function Get-CulturePayload($response) {
  if ($null -eq $response) {
    return $null
  }
  if ($response.source_type -or $response.source_badge -or $response.question) {
    return $response
  }
  if ($response.output_text) {
    return ConvertFrom-CultureContent $response.output_text
  }
  if ($response.content) {
    return ConvertFrom-CultureContent $response.content
  }
  if ($response.message -and $response.message.content) {
    $content = $response.message.content
    if ($content -is [array]) {
      $content = Get-TextFromContentParts $content
    }
    return ConvertFrom-CultureContent $content
  }
  if ($response.choices -and $response.choices.Count -gt 0) {
    $choice = $response.choices[0]
    if ($choice.message -and $choice.message.content) {
      $content = $choice.message.content
      if ($content -is [array]) {
        $content = Get-TextFromContentParts $content
      }
      return ConvertFrom-CultureContent $content
    }
    if ($choice.text) {
      return ConvertFrom-CultureContent $choice.text
    }
  }
  return $response
}

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
  $payload = Get-CulturePayload $response
  $sourceType = if ($payload.source_type) {
    $payload.source_type
  } elseif ($response.choices) {
    "ennoia_direct"
  } else {
    ""
  }
  $sourceBadge = if ($payload.source_badge) {
    $payload.source_badge
  } elseif ($response.choices) {
    "ennoia"
  } else {
    ""
  }

  Write-Host ""
  Write-Host $case.name
  Write-Host "status: $status"
  Write-Host "source_type: $sourceType"
  Write-Host "source_badge: $sourceBadge"
  Write-Host "question: $($payload.question)"
  Write-Host "korean_phrase: $($payload.korean_phrase)"
  Write-Host "persisted: $($payload.persisted)"
  Write-Host "cultureScanRecordId: $($payload.cultureScanRecordId)"
  Write-Host "scope_limited: $($payload.scope_limited)"
  if ($DebugDiagnostics -and $payload.diagnostics) {
    Write-Host "diagnostics: $(($payload.diagnostics | ConvertTo-Json -Compress))"
  }
}
