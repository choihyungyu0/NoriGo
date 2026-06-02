param(
  [string]$Endpoint = $env:ENNOIA_API_ENDPOINT,
  [string]$Project = $env:ENNOIA_PROJECT,
  [string]$ApiKey = $env:ENNOIA_API_KEY,
  [string]$Hash = $env:ENNOIA_CULTURE_HASH
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (
  [string]::IsNullOrWhiteSpace($Endpoint) -or
  [string]::IsNullOrWhiteSpace($Project) -or
  [string]::IsNullOrWhiteSpace($ApiKey) -or
  [string]::IsNullOrWhiteSpace($Hash)
) {
  throw "Set ENNOIA_API_ENDPOINT, ENNOIA_PROJECT, ENNOIA_API_KEY, and ENNOIA_CULTURE_HASH before running this smoke test."
}

$cultureContext = @{
  location_name = "Bulguksa"
  current_location = "Bulguksa"
  place_type = "temple"
  detected_object = "temple_stone_stack"
  title_en = "Temple stone stack"
  meaning = "Small stone stacks often express a quiet wish for health, peace, or good fortune."
  etiquette = "Look without touching existing stacks. If signs allow it, add one small stone gently and keep the area tidy."
  story = "At Korean temples, stone stacks are treated as personal wishes rather than photo props."
  korean_phrase = "소원 성취하세요"
  pronunciation = "so-won seong-chwi-ha-se-yo"
  phrase_meaning = "May your wish come true."
  user_question = "Why do Koreans stack stones here?"
  user_language = "English"
}
$cultureContextJson = $cultureContext | ConvertTo-Json -Depth 8 -Compress

$prompt = @"
Use only the provided CULTURE_CONTEXT.
Do not call tools.
Do not invent cultural facts.
Do not answer broad politics, social controversy, stereotypes, or general Korean society questions.
Focus only on immediate travel behavior.
Return valid JSON only with:
question, description, meaning, etiquette, story, korean_phrase, pronunciation, phrase_meaning, confidence.
"@.Trim()

$headers = @{
  project = $Project
  apiKey = $ApiKey
  "Content-Type" = "application/json; charset=utf-8"
}

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

function ConvertFrom-AgentContent($content) {
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

function Get-AgentPayload($response) {
  if ($null -eq $response) {
    return $null
  }
  if ($response.question -or $response.korean_phrase) {
    return $response
  }
  if ($response.output_text) {
    return ConvertFrom-AgentContent $response.output_text
  }
  if ($response.content) {
    if ($response.content -is [array]) {
      return ConvertFrom-AgentContent (Get-TextFromContentParts $response.content)
    }
    return ConvertFrom-AgentContent $response.content
  }
  if ($response.data) {
    return Get-AgentPayload $response.data
  }
  if ($response.message -and $response.message.content) {
    $content = $response.message.content
    if ($content -is [array]) {
      $content = Get-TextFromContentParts $content
    }
    return ConvertFrom-AgentContent $content
  }
  if ($response.choices -and $response.choices.Count -gt 0) {
    $choice = $response.choices[0]
    if ($choice.message -and $choice.message.content) {
      $content = $choice.message.content
      if ($content -is [array]) {
        $content = Get-TextFromContentParts $content
      }
      return ConvertFrom-AgentContent $content
    }
    if ($choice.text) {
      return ConvertFrom-AgentContent $choice.text
    }
  }
  return $null
}

function New-AgentBody($mode) {
  $params = @{
    user_language = "English"
    current_location = "Bulguksa"
    place_type = "temple"
    detected_object = "temple_stone_stack"
    korean_keyword = "소원 성취"
    user_intent = "Understand local culture and etiquette"
    user_question = "Why do Koreans stack stones here?"
  }

  $messageText = $prompt
  if ($mode -eq "params") {
    $params.culture_context = $cultureContextJson
  } else {
    $messageText = "$prompt`n`nCULTURE_CONTEXT:`n$cultureContextJson"
  }

  return @{
    hash = $Hash
    params = $params
    messages = @(
      @{
        role = "user"
        content = @(
          @{
            type = "text"
            text = $messageText
          }
        )
      }
    )
  }
}

foreach ($mode in @("params", "message")) {
  $status = 0
  $responseText = ""
  $body = New-AgentBody $mode | ConvertTo-Json -Depth 12

  try {
    $raw = Invoke-WebRequest -Uri $Endpoint -Method Post -Headers $headers -Body $body -UseBasicParsing
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

  $payload = $null
  if (-not [string]::IsNullOrWhiteSpace($responseText)) {
    try {
      $payload = Get-AgentPayload ($responseText | ConvertFrom-Json)
    } catch {
      $payload = $null
    }
  }

  Write-Host ""
  Write-Host "mode: $mode"
  Write-Host "status: $status"
  Write-Host "parsed question: $($payload.question)"
  Write-Host "korean_phrase: $($payload.korean_phrase)"
  if ($status -lt 200 -or $status -ge 300 -or $null -eq $payload) {
    $preview = ($responseText -replace "\s+", " ").Trim()
    if ($preview.Length -gt 1000) {
      $preview = $preview.Substring(0, 1000)
    }
    Write-Host "raw error preview: $preview"
  }
}
