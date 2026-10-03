// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/ui/theme/app_colors.dart';
import 'package:freecad_launcher/ui/theme/app_theme.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';
import 'package:freecad_launcher/ui/widgets/empty_state.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, CompactBadgeTone tone) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: Center(
            child: CompactBadge(label: 'x', tone: tone),
          ),
        ),
      ),
    );
  }

  testWidgets('badge tones map to semantic container colors', (tester) async {
    final theme = buildAppTheme(Brightness.dark);
    final status = AppStatusColors.dark;
    final cases = <(CompactBadgeTone, Color)>[
      (CompactBadgeTone.neutral, theme.colorScheme.surfaceContainerHighest),
      (CompactBadgeTone.info, status.infoContainer),
      (CompactBadgeTone.success, status.successContainer),
      (CompactBadgeTone.warning, status.warningContainer),
      (CompactBadgeTone.danger, theme.colorScheme.errorContainer),
      (CompactBadgeTone.running, status.runningContainer),
    ];

    for (final (tone, expected) in cases) {
      await pumpBadge(tester, tone);
      expect(
        tester.widget<Chip>(find.byType(Chip)).backgroundColor,
        expected,
        reason: 'tone $tone',
      );
    }
  });

  testWidgets('empty state shows the icon on a brand bubble', (tester) async {
    final theme = buildAppTheme(Brightness.light);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EmptyState(icon: Icons.inbox_outlined, title: 'Title', message: 'Message'),
        ),
      ),
    );

    final bubble = tester.widget<Container>(
      find.ancestor(of: find.byIcon(Icons.inbox_outlined), matching: find.byType(Container)).first,
    );
    final decoration = bubble.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, theme.colorScheme.primaryContainer);
  });
}
