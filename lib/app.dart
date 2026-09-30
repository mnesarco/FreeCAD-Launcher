// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/shell/app_shell.dart';

class FreeCadLauncherApp extends StatelessWidget {
  const FreeCadLauncherApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final themeMode = services.settings.themeMode.watch(context);
    return AppScope(
      services: services,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: switch (themeMode) {
          AppThemeMode.system => ThemeMode.system,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
        },
        home: const AppShell(),
      ),
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
    brightness: brightness,
  );
  const radius = BorderRadius.all(Radius.circular(4));
  const border = OutlineInputBorder(borderRadius: radius);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    inputDecorationTheme: InputDecorationThemeData(
      isDense: true,
      border: border,
      enabledBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
  );
}
