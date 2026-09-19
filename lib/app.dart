import 'package:flutter/material.dart';

import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/shell/app_shell.dart';

class FreeCadLauncherApp extends StatelessWidget {
  const FreeCadLauncherApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
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
  const radius = BorderRadius.all(Radius.circular(8));
  const border = OutlineInputBorder(borderRadius: radius);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    inputDecorationTheme: InputDecorationThemeData(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
