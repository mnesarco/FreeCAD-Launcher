import 'package:flutter/material.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'package:freecad_launcher/config.dart';
import 'package:freecad_launcher/util/format.dart';
import 'package:freecad_launcher/view/addons/icon.dart';
import 'package:freecad_launcher/view/addons/stats.dart';

class AddonTile extends StatelessWidget {
  final Addon addon;
  final Widget Function(Addon)? detailWidgetBuilder;

  const AddonTile({required this.addon, this.detailWidgetBuilder, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      leading: _icon(theme),
      title: Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 8), child: _title(theme)),
      subtitle: _subtitle(theme),
      trailing: _trailing(theme),
      onTap: () => detailWidgetBuilder == null ? null : _showDetail(context),
    );
  }

  Widget _title(ThemeData theme) {
    final entry = addon.primary;
    final version = addon.version == null ? null : 'v${addon.version}';
    return ClipRRect(
      child: Row(
        spacing: 8,
        children: [
          Flexible(
            child: Text(
              addon.displayName,
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          CuratedIndicator(addon: addon, size: 16),
          if (version != null) Text(version, overflow: TextOverflow.ellipsis),
          if (version == null && entry.lastUpdateTime != null)
            Text(fmtDateTime(entry.lastUpdateTime), overflow: TextOverflow.ellipsis),
          AddonStats(addon: addon),
        ],
      ),
    );
  }

  Widget _subtitle(ThemeData theme) {
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(text: ellipsis(addon.description, 256).replaceAll(RegExp(r'\s+'), ' ')),
          if (addon.tagsDisplay.isNotEmpty) ...[
            const TextSpan(text: '  '),
            TextSpan(
              text: addon.tagsDisplay,
              style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trailing(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        // AddonStats(addon: addon),
        AddonContentIcons(addon: addon),
        if (addon.entries.length > 1)
          Chip(
            label: Text('${addon.entries.length} branches', style: theme.textTheme.bodySmall),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        if (addon.author != null)
          Chip(
            label: Text('By ${ellipsis(addon.author!.name, 32)}', style: theme.textTheme.bodySmall),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.inversePrimary,
          ),
      ],
    );
  }

  Widget _iconFrame(Widget child, ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: child, //SizedBox(width: 52, height: 52, child: child),
      ),
    );
  }

  Widget _icon(ThemeData theme) {
    return _iconFrame(AddonIcon(addon, size: 40), theme);
  }

  void _showDetail(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.8,
            maxHeight: (size.height - 64) * 0.8,
          ),
          child: detailWidgetBuilder?.call(addon),
        ),
      ),
    );
  }
}
