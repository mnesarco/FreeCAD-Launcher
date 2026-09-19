import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/cli/cli.dart';
import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/state/app_services.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.bootstrap();
  appLogger = Logger(
    sinks: [
      RotatingFileSink(directory: Directory(services.paths.logsDir)),
      const ConsoleSink(),
    ],
  );

  if (arguments.isEmpty) {
    appLogger.info('$appName $appVersion started', tag: 'main');
    runApp(FreeCadLauncherApp(services: services));
    return;
  }

  final exitCode = await runCli(
    arguments,
    services: services,
    out: stdout,
    err: stderr,
  );
  await services.close();
  exit(exitCode);
}
