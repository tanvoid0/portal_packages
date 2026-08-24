$ErrorActionPreference = 'Stop'

$packages = @(
  "packages/portal_core_codegen",
  "packages/portal_core_models"
)

foreach ($pkg in $packages) {
  Write-Host "Running codegen in $pkg..."
  Push-Location $pkg
  dart pub get
  dart run build_runner build --delete-conflicting-outputs
  Pop-Location
}

Write-Host "Code generation complete for all packages."