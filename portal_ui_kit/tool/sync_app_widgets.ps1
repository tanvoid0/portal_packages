param(
  [Parameter(Mandatory = $true)]
  [string]$OutputDir,
  [string[]]$Bricks = @(
    'portal_button',
    'portal_card',
    'portal_text_field'
  )
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

dart pub global run mason_cli:mason get

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

foreach ($b in $Bricks) {
  Write-Host "mason make $b -> $OutputDir"
  dart pub global run mason_cli:mason make $b -o $OutputDir --on-conflict overwrite -q
}

Write-Host "Synced $($Bricks.Count) bricks into $OutputDir."
