import 'package:flutter/material.dart';

class CompactBadge extends StatelessWidget {
  const CompactBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 14),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelSmall,
      backgroundColor: backgroundColor,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
