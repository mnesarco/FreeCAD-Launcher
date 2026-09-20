class AddonUpdate {
  const AddonUpdate({
    required this.profileId,
    required this.addonId,
    required this.displayName,
    required this.branchRef,
    this.installedVersion,
    this.catalogVersion,
  });

  final String profileId;
  final String addonId;
  final String displayName;
  final String branchRef;
  final String? installedVersion;
  final String? catalogVersion;
}
