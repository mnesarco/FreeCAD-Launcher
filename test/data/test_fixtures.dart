// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';
import 'package:freecad_launcher/domain/macros/macro_types.dart';

final DateTime _baseTime = DateTime.utc(2026, 9, 18, 10);

Build sampleBuild({
  String id = 'build-1',
  String version = '1.1.3',
  String? label,
  BuildKind kind = BuildKind.appimage,
  BuildChannel channel = BuildChannel.stable,
  BuildPlatform platform = BuildPlatform.linux,
  String arch = 'x86_64',
  String? assetName = 'FreeCAD_1.1.3-Linux-x86_64-py311.AppImage',
  String? pythonVersion = '3.11',
  BuildStatus status = BuildStatus.installed,
}) {
  return Build(
    id: id,
    kind: kind,
    version: version,
    label: label,
    channel: channel,
    platform: platform,
    arch: arch,
    assetName: assetName,
    localPath: '/data/builds/$id',
    sha256: 'abc123',
    verified: true,
    pythonVersion: pythonVersion,
    sizeBytes: 1024,
    status: status,
    installedAt: _baseTime,
    updatedAt: _baseTime,
  );
}

Profile sampleProfile({
  String id = 'profile-1',
  String name = 'Default',
  String buildId = 'build-1',
  String pythonVersion = '3.11',
}) {
  return Profile(
    id: id,
    name: name,
    buildId: buildId,
    pythonVersion: pythonVersion,
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );
}

InstalledAddon sampleAddon({
  String id = 'addon-1',
  String profileId = 'profile-1',
  String addonId = 'A2plus',
  String displayName = 'A2plus',
  String? gitRef = 'master',
  String? version = '0.4.60',
  DateTime? catalogLastUpdate,
}) {
  return InstalledAddon(
    id: id,
    profileId: profileId,
    addonId: addonId,
    displayName: displayName,
    gitRef: gitRef,
    version: version,
    installedAt: _baseTime,
    updatedAt: _baseTime,
    hasRequirements: false,
    catalogLastUpdate: catalogLastUpdate,
  );
}

PythonPackage samplePackage({
  String id = 'package-1',
  String profileId = 'profile-1',
  String name = 'numpy',
  String? version = '1.26.4',
  String source = 'manual',
  String? targetDir,
}) {
  return PythonPackage(
    id: id,
    profileId: profileId,
    name: name,
    version: version,
    targetDir: targetDir ?? '/data/profiles/$profileId/AdditionalPythonPackages/py311',
    source: source,
    installedAt: _baseTime,
  );
}

Bundle sampleBundle({String id = 'bundle-1', String name = 'Mechanical'}) {
  return Bundle(
    id: id,
    name: name,
    description: 'CAD + FEM essentials',
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );
}

BundleItem sampleBundleItem({
  String bundleId = 'bundle-1',
  String addonId = 'A2plus',
  String? gitRef = 'master',
}) {
  return BundleItem(bundleId: bundleId, addonId: addonId, gitRef: gitRef);
}

Macro sampleMacro({
  String id = 'macro-1',
  String profileId = 'profile-1',
  String name = 'MyMacro',
  String fileName = 'MyMacro.FCMacro',
  MacroSource source = MacroSource.local,
}) {
  return Macro(
    id: id,
    profileId: profileId,
    name: name,
    fileName: fileName,
    source: source,
    installedAt: _baseTime,
    updatedAt: _baseTime,
  );
}

CatalogCacheEntry sampleCacheEntry({
  String key = 'github:releases:stable',
  String payloadPath = '/data/cache/releases.json',
  CacheStatus status = CacheStatus.ok,
}) {
  return CatalogCacheEntry(
    key: key,
    etag: 'W/"abc"',
    lastModified: 'Thu, 18 Sep 2026 10:00:00 GMT',
    payloadPath: payloadPath,
    fetchedAt: _baseTime,
    status: status,
  );
}
