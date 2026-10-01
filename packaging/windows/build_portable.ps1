# SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Assembles the unsigned Windows portable zip (D-091) from the Flutter release
# bundle, with 7zr.exe, LICENSE, THIRD_PARTY_NOTICES.md and README.md inside.
# Requires a prior `flutter build windows --release`.
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$constants = Get-Content (Join-Path $root 'lib\core\constants.dart') -Raw
$versionMatch = [regex]::Match($constants, "const String appVersion = '([^']+)';")
if (-not $versionMatch.Success) {
  throw 'Could not read appVersion from lib/core/constants.dart'
}
$version = $versionMatch.Groups[1].Value

$release = Join-Path $root 'build\windows\x64\runner\Release'
if (-not (Test-Path (Join-Path $release 'freecad_launcher.exe'))) {
  throw "Release bundle not found at $release; run 'flutter build windows --release' first"
}

$sevenZip = Join-Path $root 'third_party\7zip\7zr.exe'
$expectedHash = 'ad4c82fadcbdf93c03b4fc440f300509c7d60c5c2f4d183e35d9d70d6957037d'
$actualHash = (Get-FileHash -Path $sevenZip -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) {
  throw "7zr.exe hash mismatch: expected $expectedHash, got $actualHash"
}

$bundleName = "FreeCADLauncher-$version-windows-x86_64"
$stagingRoot = Join-Path $root 'build\windows\portable'
$stage = Join-Path $stagingRoot $bundleName
if (Test-Path $stagingRoot) {
  Remove-Item -Path $stagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stage -Force | Out-Null

Copy-Item -Path (Join-Path $release '*') -Destination $stage -Recurse -Force
Copy-Item -Path (Join-Path $root 'LICENSE') -Destination $stage -Force
Copy-Item -Path (Join-Path $root 'README.md') -Destination $stage -Force
Copy-Item -Path (Join-Path $root 'THIRD_PARTY_NOTICES.md') -Destination $stage -Force

foreach ($required in @('freecad_launcher.exe', '7zr.exe', 'LICENSE', 'THIRD_PARTY_NOTICES.md')) {
  if (-not (Test-Path (Join-Path $stage $required))) {
    throw "Missing $required in the portable bundle"
  }
}

$zip = Join-Path $root "build\windows\$bundleName.zip"
if (Test-Path $zip) {
  Remove-Item -Path $zip -Force
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
  $stage,
  $zip,
  [System.IO.Compression.CompressionLevel]::Optimal,
  $true
)

$zipHash = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLowerInvariant()
$sidecar = "$zip.sha256"
[System.IO.File]::WriteAllText($sidecar, "$zipHash  $bundleName.zip`n")

Write-Host "Built $zip"
Write-Host "Wrote $sidecar"
