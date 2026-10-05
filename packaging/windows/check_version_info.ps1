# SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Asserts the Windows executable's VERSIONINFO fields (D-116). These values are
# user-visible in Explorer and must match the recorded copyright holder; the
# data root no longer depends on CompanyName but drift must still fail CI.
# Requires a prior `flutter build windows --release`.
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$constants = Get-Content (Join-Path $root 'lib\core\constants.dart') -Raw
$versionMatch = [regex]::Match($constants, "const String appVersion = '([^']+)';")
if (-not $versionMatch.Success) {
  throw 'Could not read appVersion from lib/core/constants.dart'
}
$version = $versionMatch.Groups[1].Value

$exe = Join-Path $root 'build\windows\x64\runner\Release\freecad_launcher.exe'
if (-not (Test-Path $exe)) {
  throw "Release executable not found at $exe; run 'flutter build windows --release' first"
}

# Build the accented names from code points so the check is encoding-independent.
$expectedCopyright = 'Copyright 2026 Frank Mart' + [char]0xED + 'nez <mnesarco at gmail>'
$expectedCompany = 'Frank Mart' + [char]0xED + 'nez'

$info = (Get-Item $exe).VersionInfo
if ($info.LegalCopyright -ne $expectedCopyright) {
  throw "LegalCopyright mismatch: expected '$expectedCopyright', got '$($info.LegalCopyright)'"
}
if ($info.CompanyName -ne $expectedCompany) {
  throw "CompanyName mismatch: expected '$expectedCompany', got '$($info.CompanyName)'"
}
if ($info.ProductName -ne 'FreeCAD Launcher') {
  throw "ProductName mismatch: expected 'FreeCAD Launcher', got '$($info.ProductName)'"
}
if ($info.ProductVersion -notlike "$version*") {
  throw "ProductVersion mismatch: expected '$version', got '$($info.ProductVersion)'"
}

Write-Host "version info OK: $expectedCopyright"
