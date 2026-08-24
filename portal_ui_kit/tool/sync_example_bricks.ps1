$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

dart pub global run mason_cli:mason get

$content = Get-Content -Raw (Join-Path $root 'mason.yaml')
$bricks = [regex]::Matches($content, '(?m)^  (portal_[a-z_]+):') |
  ForEach-Object { $_.Groups[1].Value } |
  Sort-Object -Unique

foreach ($b in $bricks) {
  Write-Host "mason make $b -> example/lib/ui"
  dart pub global run mason_cli:mason make $b -o example/lib/ui --on-conflict overwrite -q
}

Write-Host "Synced $($bricks.Count) bricks into example/lib/ui."
