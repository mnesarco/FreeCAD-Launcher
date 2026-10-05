// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import 'package:freecad_launcher/domain/addons/addon.dart';

enum AddonDependencyType { automatic, addon, internal, python }

class AddonDependency {
  const AddonDependency({
    required this.name,
    this.type = AddonDependencyType.automatic,
    this.optional = false,
    this.versionLt = '',
    this.versionLte = '',
    this.versionEq = '',
    this.versionGte = '',
    this.versionGt = '',
  });

  final String name;
  final AddonDependencyType type;
  final bool optional;

  /// Version constraints are parsed for completeness but intentionally not used
  /// when resolving or installing dependencies (D-108, AddonManager parity).
  final String versionLt;
  final String versionLte;
  final String versionEq;
  final String versionGte;
  final String versionGt;

  bool get hasVersionConstraint =>
      versionLt.isNotEmpty ||
      versionLte.isNotEmpty ||
      versionEq.isNotEmpty ||
      versionGte.isNotEmpty ||
      versionGt.isNotEmpty;
}

class PackageXmlInfo {
  const PackageXmlInfo({
    required this.name,
    required this.description,
    required this.version,
    required this.license,
    required this.minPython,
    required this.tags,
    required this.people,
    required this.content,
    this.dependencies = const [],
  });

  final String name;
  final String description;
  final String version;
  final String? license;
  final String minPython;
  final List<String> tags;
  final List<AddonPerson> people;
  final Set<AddonContentType> content;
  final List<AddonDependency> dependencies;
}

PackageXmlInfo? parsePackageXml(String xmlText) {
  final XmlElement root;
  try {
    root = XmlDocument.parse(xmlText).rootElement;
  } on XmlException {
    return null;
  }

  String elementText(String name) {
    for (final element in root.findElements(name)) {
      final text = element.innerText.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  final tags = <String>[];
  for (final element in root.findAllElements('tag')) {
    final tag = element.innerText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags.add(tag);
    }
  }

  final people = <AddonPerson>[];
  for (final role in const ['author', 'maintainer', 'contributor']) {
    for (final element in root.findAllElements(role)) {
      final name = element.innerText.trim();
      if (name.isEmpty) {
        continue;
      }
      people.add(AddonPerson(name: name, contact: element.getAttribute('email'), roles: [role]));
    }
  }

  final content = <AddonContentType>{};
  final contentRoot = root.findElements('content').firstOrNull ?? root;
  for (final element in contentRoot.childElements) {
    switch (element.name.local.toLowerCase()) {
      case 'workbench':
        content.add(AddonContentType.workbench);
      case 'macro':
        content.add(AddonContentType.macro);
      case 'preferencepack':
        content.add(AddonContentType.preferencePack);
      case 'bundle':
        content.add(AddonContentType.bundle);
    }
  }
  if (content.isEmpty) {
    content.add(AddonContentType.other);
  }

  final minPython = elementText('pythonmin');
  final license = elementText('license');
  return PackageXmlInfo(
    name: elementText('name'),
    description: elementText('description'),
    version: elementText('version'),
    license: license.isEmpty ? null : license,
    minPython: minPython.isEmpty ? '3.10' : minPython,
    tags: tags,
    people: people,
    content: content,
    dependencies: _parseDependencies(root),
  );
}

List<AddonDependency> _parseDependencies(XmlElement root) {
  final dependencies = <AddonDependency>[];
  for (final element in root.findAllElements('depend')) {
    final name = element.innerText.trim();
    if (name.isEmpty) {
      continue;
    }
    dependencies.add(
      AddonDependency(
        name: name,
        type: _dependencyType(element.getAttribute('type')),
        optional: (element.getAttribute('optional') ?? '').toLowerCase() == 'true',
        versionLt: element.getAttribute('version_lt')?.trim() ?? '',
        versionLte: element.getAttribute('version_lte')?.trim() ?? '',
        versionEq: element.getAttribute('version_eq')?.trim() ?? '',
        versionGte: element.getAttribute('version_gte')?.trim() ?? '',
        versionGt: element.getAttribute('version_gt')?.trim() ?? '',
      ),
    );
  }
  return dependencies;
}

AddonDependencyType _dependencyType(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'addon' => AddonDependencyType.addon,
    'internal' => AddonDependencyType.internal,
    'python' => AddonDependencyType.python,
    _ => AddonDependencyType.automatic,
  };
}
