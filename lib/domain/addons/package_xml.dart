// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import 'package:freecad_launcher/domain/addons/addon.dart';

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
  });

  final String name;
  final String description;
  final String version;
  final String? license;
  final String minPython;
  final List<String> tags;
  final List<AddonPerson> people;
  final Set<AddonContentType> content;
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
  );
}
