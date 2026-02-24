param(
  [string]$IndexPath
)

$tag = ([System.DateTime]::UtcNow.ToString("yyyyMMddHHmmss"))

(Get-Content $IndexPath) -replace '{CACHE_BUSTING_TOKEN}', $tag) | Set-Content $IndexPath
