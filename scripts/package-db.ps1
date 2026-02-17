Param(
  [Parameter(Mandatory = $false)]
  [string]$Version
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$dbRoot = Join-Path $root "Yu-Gi-Lect-DB"
$dist = Join-Path $root "dist"

if (!(Test-Path $dbRoot)) {
  throw "Yu-Gi-Lect-DB folder not found at $dbRoot"
}

if ([string]::IsNullOrWhiteSpace($Version)) {
  $Version = (Get-Date).ToString("yyyy-MM-dd")
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null

$cardsDir = Join-Path $dbRoot "cards"
$dataDir = Join-Path $dbRoot "data"

$cardCount = 0
$wikiCount = 0
$artCount = 0
$wikiArtCount = 0

if (Test-Path $cardsDir) {
  $cardCount = (Get-ChildItem -Path $cardsDir -Recurse -Filter "card.json" | Measure-Object).Count
  $wikiCount = (Get-ChildItem -Path $cardsDir -Recurse -Filter "wiki.json" | Measure-Object).Count
  $artCount = (Get-ChildItem -Path $cardsDir -Recurse -Filter "art_*.jpg" | Measure-Object).Count
  $wikiArtCount = (Get-ChildItem -Path $cardsDir -Recurse -Filter "wiki_art_*.jpg" | Measure-Object).Count
}

$manifest = @{
  version = $Version
  generated_at = (Get-Date).ToString("o")
  root = "Yu-Gi-Lect-DB"
  counts = @{
    cards = $cardCount
    wiki = $wikiCount
    art = $artCount
    wiki_art = $wikiArtCount
  }
}

$manifestPath = Join-Path $dist "manifest.json"
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8

$zipName = "yu-gi-lect-db-$Version.zip"
$zipPath = Join-Path $dist $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path (Join-Path $dbRoot "*") -DestinationPath $zipPath

Write-Host "Manifest: $manifestPath"
Write-Host "Zip: $zipPath"
