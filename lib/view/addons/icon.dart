import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freecad_launcher/config.dart';
import 'package:freecad_launcher/model/addons.dart';
import 'dart:typed_data';

class CuratedIndicator extends StatelessWidget {
  final Addon addon;
  final double size;
  const CuratedIndicator({required this.addon, this.size = 16.0, super.key});

  @override
  Widget build(BuildContext context) {
    if (!mainConfig.showCuratedIcon || !addon.primary.curated) {
      return Container();
    }
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Reviewed/Curated',
      child: Icon(Icons.checklist, size: 16, color: theme.colorScheme.primary),
    );
  }
}

class AddonIcon extends StatelessWidget {
  final Addon addon;
  final double size;
  const AddonIcon(this.addon, {this.size = 48.0, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = addon.primary.metadata;
    final Uint8List? bytes = metadata?.iconBytes;

    if (bytes == null) {
      return _defaultIcon(theme: theme, size: size);
    }

    return SizedBox(
      height: size,
      width: size,
      child: metadata!.iconIsSvg
          ? SvgPicture.memory(bytes, width: size, height: size, fit: BoxFit.contain)
          : Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _defaultIcon(theme: theme, size: size),
            ),
    );
  }

  Widget _defaultIcon({ThemeData? theme, double size = 48.0}) {
    return Icon(
      Icons.extension,
      color: theme?.colorScheme.primary ?? Colors.blueAccent,
      size: size,
    );
  }
}

class AddonContentIcons extends StatelessWidget {
  final Addon addon;
  final double? size;
  final Color? color;
  const AddonContentIcons({required this.addon, this.size, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...addon.declaredContent.map(
          (c) => switch (c) {
            AddonContent.workbench => Tooltip(
              message: 'Workbenches',
              child: Icon(Icons.construction, size: size, color: color),
            ),
            AddonContent.macro => Tooltip(
              message: 'Macros',
              child: Icon(Icons.auto_fix_high, size: size, color: color),
            ),
            AddonContent.preferencePack => Tooltip(
              message: 'Preferences packs',
              child: Icon(Icons.color_lens, size: size, color: color),
            ),
            AddonContent.bundle => Tooltip(
              message: 'Bundle',
              child: Icon(Icons.folder, size: size, color: color),
            ),
            AddonContent.other => Tooltip(
              message: 'Other content',
              child: Icon(Icons.extension, size: size, color: color),
            ),
          },
        ),
      ],
    );
  }
}
