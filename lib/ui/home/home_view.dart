// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/news/news_item.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/shell_controller.dart';
import 'package:freecad_launcher/ui/profiles/profile_actions.dart';
import 'package:freecad_launcher/ui/profiles/profile_dialogs.dart';
import 'package:freecad_launcher/ui/updates/updates_summary_sheet.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';

class HomeView extends SignalStatefulWidget {
  const HomeView({super.key, this.onOpenProfile, this.onLaunchProfile});

  final ValueChanged<String>? onOpenProfile;
  final ValueChanged<Profile>? onLaunchProfile;

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  bool _started = false;
  void Function()? _disposeFeedEffect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final services = AppScope.of(context);
    services.builds.start();
    services.profiles.start();
    services.addons.start();
    services.macros.start();
    services.python.start();
    services.updates.start();
    _disposeFeedEffect = effect(() {
      final url = services.settings.newsFeedUrl.value;
      unawaited(services.news.load(url));
    });
  }

  @override
  void dispose() {
    _disposeFeedEffect?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppScope.of(context);
    final shell = services.shell;

    final builds = services.builds.installedBuilds.value;
    final profiles = services.profiles.profiles.value;
    final outdated = services.updates.outdatedCount.value;
    final checking = services.updates.checking.value;
    final newsItems = services.news.items.value;
    final newsLoading = services.news.loading.value;
    final newsLoaded = services.news.loaded.value;
    final newsStale = services.news.stale.value;
    final newsError = services.news.error.value;
    final recent = services.profiles.recentProfiles.value;
    final buildsById = services.profiles.buildsById.value;
    final runningProfiles = services.profiles.runningProfiles.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (builds.isEmpty || profiles.isEmpty)
          _FirstRunCard(
            onAddVersion: () => shell.select(AppSection.versions),
            onCreateProfile: () => showProfileFormDialog(
              context,
              controller: services.profiles,
            ),
            onInstallAddons: () => shell.select(AppSection.addons),
          ),
        if (recent.isNotEmpty) ...[
          _SectionTitle(title: l10n.homeRecentProfiles),
          _RecentProfilesRow(
            profiles: recent,
            buildsById: buildsById,
            runningProfiles: runningProfiles,
            onLaunch: widget.onLaunchProfile,
            onOpenProfile: widget.onOpenProfile,
          ),
          const SizedBox(height: 16),
        ],
        _SectionTitle(title: l10n.homeUpdates),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(
              outdated > 0
                  ? Icons.system_update_alt
                  : Icons.check_circle_outline,
            ),
            title: Text(
              outdated > 0
                  ? l10n.homeUpdatesAvailable(outdated)
                  : l10n.homeUpdatesNone,
            ),
            trailing: FilledButton.tonal(
              onPressed: checking ? null : () => _checkUpdates(context),
              child: Text(
                checking ? l10n.homeUpdatesChecking : l10n.homeUpdatesCheck,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: l10n.homeNews),
        _NewsCard(
          items: newsItems,
          loading: newsLoading,
          loaded: newsLoaded,
          stale: newsStale,
          error: newsError?.message,
          onRetry: () => unawaited(
            services.news.retry(services.settings.newsFeedUrl.value),
          ),
        ),
      ],
    );
  }

  Future<void> _checkUpdates(BuildContext context) async {
    final services = AppScope.of(context);
    await services.updates.check();
    if (!context.mounted) {
      return;
    }
    await showUpdatesSummarySheet(context);
  }
}

class _RecentProfilesRow extends StatelessWidget {
  const _RecentProfilesRow({
    required this.profiles,
    required this.buildsById,
    required this.runningProfiles,
    required this.onLaunch,
    required this.onOpenProfile,
  });

  final List<Profile> profiles;
  final Map<String, Build> buildsById;
  final Set<String> runningProfiles;
  final ValueChanged<Profile>? onLaunch;
  final ValueChanged<String>? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: profiles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return SizedBox(
            width: 220,
            child: _RecentProfileCard(
              profile: profile,
              buildInfo: buildsById[profile.buildId],
              running: runningProfiles.contains(profile.id),
              onLaunch: onLaunch,
              onOpenProfile: onOpenProfile,
            ),
          );
        },
      ),
    );
  }
}

class _RecentProfileCard extends StatelessWidget {
  const _RecentProfileCard({
    required this.profile,
    required this.buildInfo,
    required this.running,
    required this.onLaunch,
    required this.onOpenProfile,
  });

  final Profile profile;
  final Build? buildInfo;
  final bool running;
  final ValueChanged<Profile>? onLaunch;
  final ValueChanged<String>? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final buildLine = [
      if (buildInfo != null) buildInfo!.displayLabel,
      if (buildInfo != null) buildInfo!.channel.name,
    ].join('  ·  ');
    return Card(
      margin: EdgeInsets.zero,
      child: Tooltip(
        message: l10n.homeLaunch,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final launch = onLaunch;
            if (launch != null) {
              launch(profile);
            } else {
              launchProfile(context, profile);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (running)
                      CompactBadge(
                        icon: Icons.play_arrow,
                        label: l10n.profilesRunning,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  buildLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formatProfileDateTime(l10n, profile.lastUsedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (onOpenProfile != null)
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: l10n.homeOpenProfile,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onOpenProfile!(profile.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _FirstRunCard extends StatelessWidget {
  const _FirstRunCard({
    required this.onAddVersion,
    required this.onCreateProfile,
    required this.onInstallAddons,
  });

  final VoidCallback onAddVersion;
  final VoidCallback onCreateProfile;
  final VoidCallback onInstallAddons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.homeEmptyMessage),
            const SizedBox(height: 8),
            _StepTile(
              number: 1,
              label: l10n.homeStepVersion,
              onPressed: onAddVersion,
            ),
            _StepTile(
              number: 2,
              label: l10n.homeStepProfile,
              onPressed: onCreateProfile,
            ),
            _StepTile(
              number: 3,
              label: l10n.homeStepAddons,
              onPressed: onInstallAddons,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.label,
    required this.onPressed,
  });

  final int number;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 12,
        child: Text('$number', style: const TextStyle(fontSize: 12)),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPressed,
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.items,
    required this.loading,
    required this.loaded,
    required this.stale,
    required this.error,
    required this.onRetry,
  });

  static const int maxItems = 10;

  final List<NewsItem> items;
  final bool loading;
  final bool loaded;
  final bool stale;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (loading && items.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          if (stale)
            ListTile(
              dense: true,
              leading: const Icon(Icons.cloud_off_outlined, size: 18),
              title: Text(l10n.homeNewsStale),
            ),
          if (items.isEmpty && loaded && error != null)
            ListTile(
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(l10n.homeNewsError),
              subtitle: Text(error!, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: TextButton(
                onPressed: onRetry,
                child: Text(l10n.versionsRetry),
              ),
            )
          else if (items.isEmpty && loaded)
            ListTile(
              leading: const Icon(Icons.newspaper_outlined),
              title: Text(l10n.homeNewsEmpty),
            )
          else
            for (final item in items.take(_NewsCard.maxItems))
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: item.excerpt == null && item.publishedAt == null
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.excerpt != null)
                            Text(
                              item.excerpt!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (item.publishedAt != null)
                            Text(
                              _date(item.publishedAt!),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                isThreeLine: item.excerpt != null,
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => launchUrl(
                  Uri.parse(item.link),
                  mode: LaunchMode.externalApplication,
                ),
              ),
        ],
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
