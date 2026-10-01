// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
enum AddonContentType { workbench, macro, preferencePack, bundle, other }

class AddonPerson {
  const AddonPerson({required this.name, this.contact, this.roles = const []});

  final String name;
  final String? contact;
  final List<String> roles;
}

class AddonMetadata {
  const AddonMetadata({
    required this.name,
    required this.description,
    required this.version,
    required this.license,
    required this.minPython,
    required this.tags,
    required this.people,
    required this.content,
    required this.requirements,
    this.iconBase64,
  });

  final String name;
  final String description;
  final String version;
  final String? license;
  final String minPython;
  final List<String> tags;
  final List<AddonPerson> people;
  final Set<AddonContentType> content;
  final String requirements;
  final String? iconBase64;

  bool get hasRequirements => requirements.trim().isNotEmpty;
}

class AddonBranch {
  const AddonBranch({
    required this.gitRef,
    required this.displayName,
    required this.repositoryUrl,
    required this.zipUrl,
    required this.curated,
    required this.sparseCache,
    this.relativeCachePath,
    this.freecadMin,
    this.freecadMax,
    this.lastUpdateTime,
    this.note,
    this.metadata,
  });

  final String gitRef;
  final String displayName;
  final String repositoryUrl;
  final String zipUrl;
  final bool curated;
  final bool sparseCache;
  final String? relativeCachePath;

  /// Normalized version strings, e.g. `0.20.1` or `0.19`.
  final String? freecadMin;
  final String? freecadMax;
  final DateTime? lastUpdateTime;
  final String? note;
  final AddonMetadata? metadata;

  bool get hasRequirements => metadata?.hasRequirements ?? false;
}

class Addon {
  const Addon({required this.id, required this.branches});

  final String id;
  final List<AddonBranch> branches;

  AddonBranch get primaryBranch => branches.first;

  AddonMetadata? get _richestMetadata {
    for (final branch in branches) {
      if (branch.metadata != null) {
        return branch.metadata;
      }
    }
    return null;
  }

  String get displayName => _richestMetadata?.name ?? id;

  String get description => _richestMetadata?.description ?? '';

  String? get license => _richestMetadata?.license;

  String get version => _richestMetadata?.version ?? '';

  bool get hasRequirements => branches.any((branch) => branch.hasRequirements);

  Set<String> get tags => {
    for (final branch in branches) ...?branch.metadata?.tags,
  };

  Set<AddonContentType> get content => {
    for (final branch in branches) ...?branch.metadata?.content,
  };

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    if (normalized.startsWith('#')) {
      final tag = normalized.substring(1);
      return tags.any((candidate) => candidate == tag);
    }
    return displayName.toLowerCase().contains(normalized) ||
        id.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized) ||
        tags.any((tag) => tag.contains(normalized));
  }
}
