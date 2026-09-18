import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/state/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.bootstrap();
  appLogger = Logger(
    sinks: [
      RotatingFileSink(directory: Directory(services.paths.logsDir)),
      const ConsoleSink(),
    ],
  );
  appLogger.info('$appName $appVersion started', tag: 'main');
  runApp(FreeCadLauncherApp(services: services));
}
