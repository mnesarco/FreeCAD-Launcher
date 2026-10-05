// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/package_xml.dart';
import 'package:freecad_launcher/domain/python/python_names.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';

/// Internal workbenches provided by FreeCAD itself (Package_Metadata "internal"
/// dependencies). Standard builds ship all of them, so they are informational.
const Set<String> internalWorkbenches = {
  'assembly',
  'bim',
  'cam',
  'draft',
  'fem',
  'import',
  'material',
  'mesh',
  'openscad',
  'part',
  'partdesign',
  'plot',
  'points',
  'reverseengineering',
  'robot',
  'sketcher',
  'spreadsheet',
  'techdraw',
  'tux',
  'web',
};

enum ResolvedDependencyKind { addon, python, internal }

class ResolvedAddonDependency {
  const ResolvedAddonDependency({
    required this.source,
    required this.kind,
    required this.declaredByAddonId,
    this.addon,
    this.branchRef,
    this.internalName,
  });

  final AddonDependency source;
  final ResolvedDependencyKind kind;
  final String declaredByAddonId;
  final Addon? addon;

  /// Branch selected for [addon] when the dependency was resolved.
  final String? branchRef;
  final String? internalName;

  bool get optional => source.optional;
}

/// The user's decision for one addon install.
class AddonDependencySelection {
  const AddonDependencySelection({
    required this.installRequired,
    this.optionalAddonIds = const {},
    this.optionalPackageNames = const {},
  });

  /// False means "addon only": nothing (required or optional) is installed.
  final bool installRequired;
  final Set<String> optionalAddonIds;

  /// PEP 503-normalized package names.
  final Set<String> optionalPackageNames;

  static const AddonDependencySelection none = AddonDependencySelection(installRequired: false);
  static const AddonDependencySelection requiredOnly = AddonDependencySelection(
    installRequired: true,
  );
}

typedef AddonDependencyHandler =
    Future<AddonDependencySelection?> Function(AddonDependencyPlan plan);

class ResolvedPythonRequirement {
  const ResolvedPythonRequirement({
    required this.requirement,
    required this.optional,
    required this.declaredByAddonId,
  });

  final PythonRequirement requirement;
  final bool optional;
  final String declaredByAddonId;
}

class AddonDependencyPlan {
  const AddonDependencyPlan({
    this.requiredAddons = const [],
    this.optionalAddons = const [],
    this.orderedAddons = const [],
    this.requiredPython = const [],
    this.optionalPython = const [],
    this.internalWorkbenches = const {},
    this.invalidRequirements = const [],
    this.unresolved = const [],
  });

  final List<ResolvedAddonDependency> requiredAddons;
  final List<ResolvedAddonDependency> optionalAddons;

  /// Required and optional dependent addons in dependency order (deepest first).
  final List<ResolvedAddonDependency> orderedAddons;
  final List<ResolvedPythonRequirement> requiredPython;
  final List<ResolvedPythonRequirement> optionalPython;
  final Set<String> internalWorkbenches;
  final List<PythonRequirement> invalidRequirements;
  final List<String> unresolved;

  bool get hasInstallable =>
      requiredAddons.isNotEmpty ||
      optionalAddons.isNotEmpty ||
      requiredPython.isNotEmpty ||
      optionalPython.isNotEmpty;

  bool get isEmpty =>
      !hasInstallable &&
      internalWorkbenches.isEmpty &&
      invalidRequirements.isEmpty &&
      unresolved.isEmpty;
}

/// Resolves the declared dependencies of one addon against the catalog,
/// mirroring FreeCAD's AddonManager semantics (D-108):
/// `automatic` entries match addons first, then internal workbenches, then are
/// treated as Python packages.
///
/// Addons already installed in the profile are excluded from the install lists
/// but their dependency trees are still walked (a missing transitive dependency
/// must install even when the intermediate addon is present).
///
/// Python candidates already present in [availablePythonPackages] (PEP 503
/// normalized) are filtered out, as are invalid `requirements.txt` options
/// (returned in [AddonDependencyPlan.invalidRequirements]).
AddonDependencyPlan resolveAddonDependencies({
  required String addonId,
  required List<AddonDependency> dependencies,
  required List<Addon> catalog,
  String? requirementsText,
  Set<String> installedAddonIds = const {},
  Set<String> availablePythonPackages = const {},
  AddonBranch Function(Addon addon)? branchOf,
}) {
  return _AddonDependencyResolver(
    addonId: addonId,
    dependencies: dependencies,
    catalog: catalog,
    requirementsText: requirementsText,
    installedAddonIds: installedAddonIds,
    availablePythonPackages: availablePythonPackages,
    branchOf: branchOf ?? (addon) => addon.primaryBranch,
  ).run();
}

/// Merges the dependency plans of several addons into one consent preview
/// (bundle apply, batch updates). Required entries win over optional ones and
/// duplicates are removed by addon id / PEP 503 package name.
AddonDependencyPlan mergeDependencyPlans(Iterable<AddonDependencyPlan> plans) {
  final addons = <String, ResolvedAddonDependency>{};
  final order = <String>[];
  final requiredPython = <String, ResolvedPythonRequirement>{};
  final optionalPython = <String, ResolvedPythonRequirement>{};
  final internals = <String>{};
  final invalid = <PythonRequirement>[];
  final unresolved = <String>[];

  for (final plan in plans) {
    for (final entry in plan.orderedAddons) {
      final id = entry.addon!.id;
      final existing = addons[id];
      if (existing == null) {
        addons[id] = entry;
        order.add(id);
      } else if (existing.optional && !entry.optional) {
        addons[id] = ResolvedAddonDependency(
          source: entry.source,
          kind: ResolvedDependencyKind.addon,
          addon: entry.addon,
          branchRef: entry.branchRef,
          declaredByAddonId: entry.declaredByAddonId,
        );
      }
    }
    for (final entry in plan.requiredPython) {
      final key = normalizePythonPackageName(entry.requirement.name);
      optionalPython.remove(key);
      requiredPython.putIfAbsent(key, () => entry);
    }
    for (final entry in plan.optionalPython) {
      final key = normalizePythonPackageName(entry.requirement.name);
      optionalPython.putIfAbsent(key, () => entry);
    }
    internals.addAll(plan.internalWorkbenches);
    invalid.addAll(plan.invalidRequirements);
    unresolved.addAll(plan.unresolved);
  }

  return AddonDependencyPlan(
    requiredAddons: [
      for (final id in order)
        if (!addons[id]!.optional) addons[id]!,
    ],
    optionalAddons: [
      for (final id in order)
        if (addons[id]!.optional) addons[id]!,
    ],
    orderedAddons: [for (final id in order) addons[id]!],
    requiredPython: requiredPython.values.toList(growable: false),
    optionalPython: optionalPython.values.toList(growable: false),
    internalWorkbenches: internals,
    invalidRequirements: invalid,
    unresolved: unresolved,
  );
}

class _AddonDependencyResolver {
  _AddonDependencyResolver({
    required this.addonId,
    required this.dependencies,
    required this.catalog,
    required this.branchOf,
    this.requirementsText,
    this.installedAddonIds = const {},
    this.availablePythonPackages = const {},
  }) {
    for (final addon in catalog) {
      _byId[addon.id] = addon;
      _byName.putIfAbsent(addon.id.toLowerCase(), () => addon);
      final displayName = addon.displayName.trim().toLowerCase();
      if (displayName.isNotEmpty) {
        _byName.putIfAbsent(displayName, () => addon);
      }
    }
    _visited.add(addonId);
  }

  final String addonId;
  final List<AddonDependency> dependencies;
  final List<Addon> catalog;
  final AddonBranch Function(Addon addon) branchOf;
  final String? requirementsText;
  final Set<String> installedAddonIds;
  final Set<String> availablePythonPackages;

  final _byId = <String, Addon>{};
  final _byName = <String, Addon>{};
  final _visited = <String>{};
  final _addonEntries = <String, ResolvedAddonDependency>{};
  final _addonOrder = <String>[];
  final _requiredPython = <String, ResolvedPythonRequirement>{};
  final _optionalPython = <String, ResolvedPythonRequirement>{};
  final _internals = <String>{};
  final _unresolved = <String>[];
  final _invalidRequirements = <PythonRequirement>[];

  AddonDependencyPlan run() {
    final text = requirementsText;
    if (text != null) {
      for (final requirement in parseRequirements(text)) {
        if (!requirement.valid) {
          _invalidRequirements.add(requirement);
        } else {
          _addPythonRequirement(requirement: requirement, optional: false, declaredBy: addonId);
        }
      }
    }
    for (final dependency in dependencies) {
      _process(dependency, addonId);
    }
    return AddonDependencyPlan(
      requiredAddons: [
        for (final id in _addonOrder)
          if (!_addonEntries[id]!.optional) _addonEntries[id]!,
      ],
      optionalAddons: [
        for (final id in _addonOrder)
          if (_addonEntries[id]!.optional) _addonEntries[id]!,
      ],
      orderedAddons: [for (final id in _addonOrder) _addonEntries[id]!],
      requiredPython: _requiredPython.values.toList(growable: false),
      optionalPython: _optionalPython.values.toList(growable: false),
      internalWorkbenches: _internals,
      invalidRequirements: _invalidRequirements,
      unresolved: _unresolved,
    );
  }

  void _process(AddonDependency dependency, String declaredBy) {
    switch (dependency.type) {
      case AddonDependencyType.internal:
        _addInternal(dependency);
      case AddonDependencyType.python:
        _addPythonRequirement(
          requirement: PythonRequirement(raw: dependency.name, name: dependency.name),
          optional: dependency.optional,
          declaredBy: declaredBy,
        );
      case AddonDependencyType.addon:
        final addon = _match(dependency.name);
        if (addon != null) {
          _addAddon(dependency, addon, declaredBy);
        } else {
          _autoResolve(dependency, declaredBy);
        }
      case AddonDependencyType.automatic:
        _autoResolve(dependency, declaredBy);
    }
  }

  void _autoResolve(AddonDependency dependency, String declaredBy) {
    final addon = _match(dependency.name);
    if (addon != null) {
      _addAddon(dependency, addon, declaredBy);
      return;
    }
    final candidate = _normalizedInternalName(dependency.name);
    if (internalWorkbenches.contains(candidate)) {
      _internals.add(candidate);
      return;
    }
    _addPythonRequirement(
      requirement: PythonRequirement(raw: dependency.name, name: dependency.name),
      optional: dependency.optional,
      declaredBy: declaredBy,
    );
  }

  void _addAddon(AddonDependency source, Addon addon, String declaredBy) {
    final id = addon.id;
    final existing = _addonEntries[id];
    if (_visited.contains(id)) {
      if (existing != null && existing.optional && !source.optional) {
        _addonEntries[id] = ResolvedAddonDependency(
          source: source,
          kind: ResolvedDependencyKind.addon,
          addon: addon,
          branchRef: existing.branchRef,
          declaredByAddonId: declaredBy,
        );
      }
      return;
    }
    _visited.add(id);
    final branch = branchOf(addon);
    for (final nested in branch.metadata?.dependencies ?? const <AddonDependency>[]) {
      _process(nested, id);
    }
    if (!installedAddonIds.contains(id)) {
      _addonEntries[id] = ResolvedAddonDependency(
        source: source,
        kind: ResolvedDependencyKind.addon,
        addon: addon,
        branchRef: branch.gitRef,
        declaredByAddonId: declaredBy,
      );
      _addonOrder.add(id);
    }
  }

  void _addInternal(AddonDependency source) {
    final candidate = source.name.trim().toLowerCase();
    if (internalWorkbenches.contains(candidate)) {
      _internals.add(candidate);
    } else {
      _unresolved.add(source.name.trim());
    }
  }

  void _addPythonRequirement({
    required PythonRequirement requirement,
    required bool optional,
    required String declaredBy,
  }) {
    final key = normalizePythonPackageName(requirement.name);
    if (key.isEmpty || availablePythonPackages.contains(key)) {
      return;
    }
    if (optional) {
      if (_requiredPython.containsKey(key)) {
        return;
      }
      _optionalPython.putIfAbsent(
        key,
        () => ResolvedPythonRequirement(
          requirement: requirement,
          optional: true,
          declaredByAddonId: declaredBy,
        ),
      );
      return;
    }
    _optionalPython.remove(key);
    _requiredPython.putIfAbsent(
      key,
      () => ResolvedPythonRequirement(
        requirement: requirement,
        optional: false,
        declaredByAddonId: declaredBy,
      ),
    );
  }

  Addon? _match(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _byId[trimmed] ?? _byName[trimmed.toLowerCase()];
  }
}

String _normalizedInternalName(String name) {
  final candidate = name.trim().toLowerCase();
  if (candidate.endsWith('wb')) {
    return candidate.substring(0, candidate.length - 2).trim();
  }
  if (candidate.endsWith('workbench')) {
    return candidate.substring(0, candidate.length - 9).trim();
  }
  return candidate;
}
