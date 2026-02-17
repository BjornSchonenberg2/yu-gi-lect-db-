Param(
  [Parameter(Mandatory = $true)]
  [string]$Path,
  [Parameter(Mandatory = $false)]
  [int]$SplitSizeMB = 1900
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $Path)) {
  throw "File not found: $Path"
}

$dir = Split-Path -Parent $Path
$name = Split-Path -Leaf $Path
$partSize = $SplitSizeMB * 1MB

$buffer = New-Object byte[] (4MB)
$index = 1
$in = [System.IO.File]::OpenRead($Path)
try {
  while ($in.Position -lt $in.Length) {
    $partName = "{0}.{1}" -f $name, $index.ToString("000")
    $partPath = Join-Path $dir $partName
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
    Write-Host "Wrote $partName"
    $index++
  }
} finally {
  $in.Close()
}
