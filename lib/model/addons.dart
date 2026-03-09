import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:freecad_launcher/config.dart';
import 'package:freecad_launcher/service/download.dart';
import 'package:freecad_launcher/util/hashlib.dart';
import 'package:xml/xml.dart';
import 'package:recase/recase.dart';
import 'package:archive/archive.dart';

/// A single entry (branch / release) for an addon in the catalog cache.
class AddonEntry {
  final String repository;
  final String gitRef;
  final String branchDisplayName;
  final String zipUrl;
  final bool curated;
  final String? note;
  final String? freecadMin;
  final String? freecadMax;
  final DateTime? lastUpdateTime;
  final String? relativeCachePath;
  final AddonMetadata? metadata;
  late final Set<String> tags = metadata?.tags ?? {};
  late final String tagsDisplay = tags.take(5).map((s) => "#${s.toLowerCase()}").join(", ");
  late final String minPython = metadata?.minPython ?? '3.10';
  late final sha1 = sha1Hash('$repository$zipUrl$gitRef${lastUpdateTime ?? ""}');
  late final String downloadUrl = '${mainConfig.addonsDownloadBaseUrl}$relativeCachePath';

  AddonEntry({
    required this.repository,
    required this.gitRef,
    required this.branchDisplayName,
    required this.zipUrl,
    this.curated = false,
    this.note,
    this.freecadMin,
    this.freecadMax,
    this.lastUpdateTime,
    this.relativeCachePath,
    this.metadata,
  });

  factory AddonEntry.fromJson(Map<String, dynamic> json) {
    return AddonEntry(
      repository: json['repository'] as String? ?? '',
      gitRef: json['git_ref'] as String? ?? '',
      branchDisplayName: json['branch_display_name'] as String? ?? '',
      zipUrl: json['zip_url'] as String? ?? '',
      curated: json['curated'] as bool? ?? false,
      note: json['note'] as String?,
      freecadMin: _parseVersion(json['freecad_min']),
      freecadMax: _parseVersion(json['freecad_max']),
      lastUpdateTime: () {
        final str = json['last_update_time'] as String?;
        if (str == null) {
          return null;
        }
        try {
          return DateTime.parse(str);
        } catch (e) {
          return null;
        }
      }(),
      relativeCachePath: json['relative_cache_path'] as String?,
      metadata: json['metadata'] != null
          ? AddonMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  /// freecad_min/max can be a string, null, or an object with version_as_list.
  static String? _parseVersion(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final list = value['version_as_list'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return list.where((e) => e != null && e.toString().isNotEmpty).join('.');
      }
    }
    return null;
  }
}

enum AddonPersonRole { author, maintainer, contributor }

enum AddonContent { workbench, macro, preferencePack, bundle, other }

class AddonPerson {
  final String name;
  final String contact;
  final List<AddonPersonRole> roles;
  const AddonPerson(this.name, this.contact, [this.roles = const []]);
}

/// Parsed metadata from package_xml embedded in the catalog.
class AddonMetadata {
  final String? displayName;
  final String? description;
  final String? version;
  final String? license;
  final List<AddonPerson> people;
  late final AddonPerson? author =
      people.where((p) => p.roles.contains(AddonPersonRole.author)).firstOrNull ??
      people.firstOrNull;
  final String minPython;

  /// Tags from the package_xml content section (e.g. 'assembly', 'bom', '3d').
  final Set<String> tags;

  /// Pre-decoded icon bytes (from base64 icon_data). Null if absent or invalid.
  final Uint8List? iconBytes;

  /// Whether [iconBytes] contains SVG data (vs raster PNG/etc).
  final bool iconIsSvg;

  final List<AddonContent> declaredContent;

  AddonMetadata({
    this.displayName,
    this.description,
    this.version,
    this.license,
    this.declaredContent = const [],
    this.tags = const {},
    this.iconBytes,
    this.iconIsSvg = false,
    this.people = const [],
    this.minPython = '3.10',
  });

  factory AddonMetadata.fromJson(Map<String, dynamic> json) {
    final packageXml = json['package_xml'] as String? ?? '';
    final rawIcon = json['icon_data'] as String?;

    Uint8List? iconBytes;
    bool iconIsSvg = false;
    if (rawIcon != null && rawIcon.isNotEmpty) {
      try {
        iconBytes = base64Decode(rawIcon);
        iconIsSvg = _looksLikeSvg(iconBytes);
      } catch (_) {
        iconBytes = null;
      }
    }

    final xml = _parseXml(packageXml);

    return AddonMetadata(
      displayName: _getFirstTagValue(xml, 'name'),
      description: _getFirstTagValue(xml, 'description'),
      version: _getFirstTagValue(xml, 'version'),
      license: _getFirstTagValue(xml, 'license'),
      tags: _parseTags(xml),
      iconBytes: iconBytes,
      iconIsSvg: iconIsSvg,
      people: _parsePeople(xml),
      minPython: _getFirstTagValue(xml, 'pythonmin') ?? '3.10',
      declaredContent: _parseContent(xml),
    );
  }

  static XmlDocument? _parseXml(String? xml) {
    if (xml == null) return null;
    final code = xml.trim();
    if (code.isEmpty) return null;
    try {
      return XmlDocument.parse(code);
    } catch (e) {
      return null;
    }
  }

  static String? _getFirstTagValue(XmlDocument? doc, String tag) {
    if (doc == null) return null;
    return doc.findAllElements(tag).firstOrNull?.innerText.trim();
  }

  static Set<String> _parseTags(XmlDocument? doc) {
    if (doc == null) return {};
    return doc
        .findAllElements('tag')
        .map((e) => e.innerText.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-\s]+'), ""))
        .where((t) => t.isNotEmpty)
        .map((t) => t.replaceAll(RegExp(r'\s+'), '-'))
        .toSet();
  }

  static List<AddonContent> _parseContent(XmlDocument? doc) {
    if (doc == null) return [];
    return [
      if (doc.findAllElements('workbench').isNotEmpty) AddonContent.workbench,
      if (doc.findAllElements('macro').isNotEmpty) AddonContent.macro,
      if (doc.findAllElements('preferencepack').isNotEmpty) AddonContent.preferencePack,
      if (doc.findAllElements('bundle').isNotEmpty) AddonContent.bundle,
      if (doc.findAllElements('other').isNotEmpty) AddonContent.other,
    ];
  }

  static List<AddonPerson> _parsePeople(XmlDocument? doc) {
    if (doc == null) return const [];
    final elements = [
      ...doc.findAllElements('author'),
      ...doc.findAllElements('maintainer'),
      ...doc.findAllElements('contributor'),
    ];
    final elementsByName = groupBy(elements, (e) => e.innerText.trim().toUpperCase());
    final people = elementsByName.entries.map((e) {
      final roles = e.value.map((e) {
        return switch (e.name.local) {
          'author' => AddonPersonRole.author,
          'maintainer' => AddonPersonRole.maintainer,
          _ => AddonPersonRole.contributor,
        };
      }).toList();
      return AddonPerson(
        e.key.titleCase,
        e.value.first.getAttribute("email") ?? 'No contact',
        roles,
      );
    });
    return people.toList();
  }

  /// Heuristic: check if decoded bytes start with XML/SVG markers.
  static bool _looksLikeSvg(Uint8List bytes) {
    final str = String.fromCharCodes(bytes.length > 256 ? bytes.sublist(0, 256) : bytes).trimLeft();
    return str.startsWith('<?xml') || str.startsWith('<svg') || str.startsWith('<!');
  }
}

/// An addon identified by its catalog key, with one or more branch entries.
class Addon {
  final String id;
  final List<AddonEntry> entries;
  late final AddonEntry primary = entries.first;
  late final String displayName = primary.metadata?.displayName ?? id;
  late final AddonPerson? author = primary.metadata?.author;
  late final String? version = primary.metadata?.version;
  late final DateTime? lastUpdate = primary.lastUpdateTime;
  late final Set<String> tags = primary.tags;
  late final String tagsDisplay = primary.tagsDisplay;
  late final String minPython = primary.minPython;
  late final String description = () {
    final meta = primary.metadata?.description;
    if (meta != null && meta.isNotEmpty) return meta;
    final note = primary.note;
    if (note != null && note.isNotEmpty) return note;
    return '${primary.branchDisplayName} — ${primary.repository}';
  }();
  late final List<AddonContent> declaredContent = primary.metadata?.declaredContent ?? const [];

  Addon({required this.id, required this.entries});
}

/// Loads, holds, and filters the full addon catalog.
class AddonCatalog {
  final List<Addon> addons;

  const AddonCatalog(this.addons);

  static Future<AddonCatalog> download(DownloadManager downloadManager) async {
    final cache = await downloadManager.download(
      mainConfig.addonsCatalogUrl,
      'addons-catalog.zip',
      mainConfig.addonsCatalogTTL,
    );
    final input = InputFileStream(cache);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final file = archive.find('addon_catalog_cache.json');
      if (file == null) {
        throw Exception('addon_catalog_cache.json not found in archive');
      }
      final json = utf8.decode(file.readBytes()!);
      return AddonCatalog.parseString(json);
    } finally {
      input.closeSync();
    }
  }

  /// Load and parse the catalog from a JSON file on disk.
  static Future<AddonCatalog> loadFromFile(String path) async {
    final raw = await File(path).readAsString();
    return _parse(raw);
  }

  /// Load and parse the catalog from a JSON string.
  static AddonCatalog parseString(String raw) => _parse(raw);

  static AddonCatalog _parse(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw);
    final List<Addon> addons = [];

    for (final entry in json.entries) {
      // Skip schema & meta keys.
      if (entry.key.startsWith('_') || entry.key.startsWith('\$')) continue;
      if (entry.value is! List) continue;

      final list = entry.value as List<dynamic>;
      addons.add(
        Addon(
          id: entry.key,
          entries: list.map((e) => AddonEntry.fromJson(e as Map<String, dynamic>)).toList(),
        ),
      );
    }

    addons.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return AddonCatalog(addons);
  }

  /// Return addons matching [query]. Supports `#tag` syntax for tag filtering.
  /// Example: "assembly #bom #3d" filters by text "assembly" AND tags "bom" + "3d".
  List<Addon> search(String query) {
    if (query.isEmpty) return addons;

    // Extract #tags and remaining text query.
    final tagPattern = RegExp(r'#(\S+)');
    final tags = tagPattern.allMatches(query).map((m) => m.group(1)!.toLowerCase()).toList();
    final textQuery = query.replaceAll(tagPattern, '').trim().toLowerCase();

    Iterable<Addon> results = addons;

    // Stage 1: filter by text (name, description, author).
    if (textQuery.isNotEmpty) {
      results = results.where((a) {
        final byName = a.displayName.toLowerCase().contains(textQuery);
        final byDesc = a.description.toLowerCase().contains(textQuery);
        final byAuthor = a.author != null && a.author!.name.toLowerCase().contains(textQuery);
        return byName || byDesc || byAuthor;
      });
    }

    // Stage 2: filter by tags (all specified tags must be present).
    if (tags.isNotEmpty) {
      results = results.where((a) {
        final addonTags = a.tags;
        return tags.every((t) => addonTags.contains(t));
      });
    }

    return results.toList();
  }
}
