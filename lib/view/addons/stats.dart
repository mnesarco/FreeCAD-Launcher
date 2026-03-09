import 'package:flutter/material.dart';
import 'package:freecad_launcher/config.dart';
import 'package:freecad_launcher/controller/main.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/model/github_stats.dart';
import 'package:freecad_launcher/view/icons.dart';

class AddonStats extends StatelessWidget {
  final Addon addon;
  final bool full;
  const AddonStats({required this.addon, this.full = false, super.key});

  @override
  Widget build(BuildContext context) {
    if (!mainConfig.showGithubStats) {
      return Container();
    }
    MainController controller = MainController.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<AddonStatsCatalog>(
      future: controller.addonsStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            snapshot.data == null) {
          return Container();
        }
        final stats = snapshot.data![addon.primary.repository];
        if (stats == null) {
          return Container();
        }
        return Tooltip(
          message: 'Github stats',
          child: full ? _full(stats, theme) : _simple(stats, theme),
        );
      },
    );
  }

  Widget _simple(GitHubStats stats, ThemeData theme) {
    return Chip(
      avatar: Icon(FreeCADIcons.github_circle, color: theme.colorScheme.secondary),
      label: Text(stats.starsDisplay, overflow: TextOverflow.clip),
      labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
      backgroundColor: theme.colorScheme.secondaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _full(GitHubStats stats, ThemeData theme) {
    final texts = [
      '${stats.stargazersCount} ${stats.stargazersCount == 1 ? "star" : "stars"}',
      '${stats.forksCount} ${stats.forksCount == 1 ? 'fork' : 'forks'}',
      '${stats.openIssuesCount} ${stats.openIssuesCount == 1 ? 'issue' : 'issues'}',
      '${stats.subscribersCount} subs',
    ];
    return Chip(
      avatar: Icon(FreeCADIcons.github_circle, color: theme.colorScheme.secondary),
      label: Text(texts.join(', '), overflow: TextOverflow.clip),
      labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
      backgroundColor: theme.colorScheme.secondaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}
