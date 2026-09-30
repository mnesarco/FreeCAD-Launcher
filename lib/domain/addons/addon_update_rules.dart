// SPDX-License-Identifier: GPL-3.0-or-later
bool addonContentChanged({
  required DateTime? catalogLastUpdate,
  required String? catalogVersion,
  required DateTime? installedCatalogLastUpdate,
  required String? installedVersion,
}) {
  if (catalogLastUpdate != null &&
      (installedCatalogLastUpdate == null || catalogLastUpdate.isAfter(installedCatalogLastUpdate))) {
    return true;
  }
  if (catalogVersion != null &&
      catalogVersion.isNotEmpty &&
      installedVersion != null &&
      installedVersion.isNotEmpty &&
      catalogVersion != installedVersion) {
    return true;
  }
  return false;
}
