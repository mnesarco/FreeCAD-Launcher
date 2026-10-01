// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
enum AddonSource { catalog, repo, zip, symlink }

AddonSource addonSourceFromStorage(String? value) {
  for (final source in AddonSource.values) {
    if (source.name == value) {
      return source;
    }
  }
  return AddonSource.catalog;
}

extension AddonSourceX on AddonSource {
  bool get isCatalog => this == AddonSource.catalog;

  bool get isCustom => this != AddonSource.catalog;

  bool get isUpdateableFromRepository => this == AddonSource.repo;

  bool get isLiveLink => this == AddonSource.symlink;
}
