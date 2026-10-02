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
import 'package:freecad_launcher/ui/icons.dart';
import 'package:freecad_launcher/ui/profiles/profile_actions.dart';
import 'package:freecad_launcher/ui/profiles/profile_dialogs.dart';
import 'package:freecad_launcher/ui/updates/updates_summary_sheet.dart';

class HomeView extends SignalStatefulWidget {
  const HomeView({super.key});

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
    final addons = services.addons.installedAddons.value;
    final macros = services.macros.installedMacros.value;
    final packages = services.python.packages.value;
    final outdated = services.updates.outdatedCount.value;
    final checking = services.updates.checking.value;
    final newsItems = services.news.items.value;
    final newsLoading = services.news.loading.value;
    final newsLoaded = services.news.loaded.value;
    final newsStale = services.news.stale.value;
    final newsError = services.news.error.value;

    Profile? lastUsed;
    for (final profile in profiles) {
      final usedAt = profile.lastUsedAt;
      if (usedAt == null) {
        continue;
      }
      if (lastUsed == null || usedAt.isAfter(lastUsed.lastUsedAt!)) {
        lastUsed = profile;
      }
    }
    lastUsed ??= profiles.isEmpty ? null : profiles.first;
    Build? lastBuild;
    if (lastUsed != null) {
      for (final build in builds) {
        if (build.id == lastUsed.buildId) {
          lastBuild = build;
          break;
        }
      }
    }

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
        _SectionTitle(title: l10n.homeStatus),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              icon: FreeCADIcons.freecad,
              label: l10n.homeStatBuilds,
              value: builds.length,
              onTap: () => shell.select(AppSection.versions),
            ),
            _StatCard(
              icon: Icons.workspaces_outlined,
              label: l10n.homeStatProfiles,
              value: profiles.length,
              onTap: () => shell.select(AppSection.profiles),
            ),
            _StatCard(
              icon: Icons.extension_outlined,
              label: l10n.homeStatAddons,
              value: addons.length,
              onTap: () => shell.select(AppSection.addons),
            ),
            _StatCard(
              icon: Icons.auto_fix_high_outlined,
              label: l10n.homeStatMacros,
              value: macros.length,
              onTap: () => shell.select(AppSection.macros),
            ),
            _StatCard(
              icon: Icons.terminal_outlined,
              label: l10n.homeStatPackages,
              value: packages.length,
              onTap: () => shell.select(AppSection.profiles),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: l10n.homeLastUsed),
        Card(
          margin: EdgeInsets.zero,
          child: lastUsed == null
              ? ListTile(
                  leading: const Icon(Icons.person_off_outlined),
                  title: Text(l10n.homeNoProfiles),
                )
              : ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(lastUsed.name),
                  subtitle: Text(
                    [
                      if (lastBuild != null) lastBuild.displayLabel,
                      if (lastBuild != null) lastBuild.channel.name,
                      if (lastUsed.lastUsedAt != null)
                        formatProfileDateTime(l10n, lastUsed.lastUsedAt)
                      else
                        l10n.homeLastUsedNever,
                    ].join('  ·  '),
                  ),
                  trailing: FilledButton.icon(
                    onPressed: () => launchProfile(context, lastUsed!),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.homeLaunch),
                  ),
                ),
        ),
        const SizedBox(height: 16),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        label,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
