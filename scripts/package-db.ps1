Param(
  [Parameter(Mandatory = $false)]
  [string]$Version,
  [Parameter(Mandatory = $false)]
  [int]$SplitSizeMB = 0
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

$manifest = [ordered]@{
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

$zipName = "yu-gi-lect-db-$Version.zip"
$zipPath = Join-Path $dist $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path (Join-Path $dbRoot "*") -DestinationPath $zipPath

if ($SplitSizeMB -gt 0) {
  $partSize = $SplitSizeMB * 1MB
  $parts = @()
  $buffer = New-Object byte[] (4MB)
  $index = 1
  $in = [System.IO.File]::OpenRead($zipPath)
  try {
    while ($in.Position -lt $in.Length) {
      $partName = "{0}.{1}" -f $zipName, $index.ToString("000")
      $partPath = Join-Path $dist $partName
      $out = [System.IO.File]::Create($partPath)
      try {
        $written = 0L
        while ($written -lt $partSize -and $in.Position -lt $in.Length) {
          $toRead = [Math]::Min($buffer.Length, $partSize - $written)
          $read = $in.Read($buffer, 0, $toRead)
          if ($read -le 0) { break }
          $out.Write($buffer, 0, $read)
          $written += $read
        }
      } finally {
        $out.Close()
      }
      $parts += @{
        name = $partName
        size = (Get-Item $partPath).Length
      }
      $index++
    }
  } finally {
    $in.Close()
  }
  $manifest.parts = $parts
}

$manifestPath = Join-Path $dist "manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host "Manifest: $manifestPath"
Write-Host "Zip: $zipPath"
