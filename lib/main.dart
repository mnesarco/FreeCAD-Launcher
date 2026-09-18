import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportDirectory = await getApplicationSupportDirectory();
  final logsDirectory = Directory(p.join(supportDirectory.path, 'logs'));
  appLogger = Logger(
    sinks: [
      RotatingFileSink(directory: logsDirectory),
      const ConsoleSink(),
    ],
  );
  appLogger.info('$appName $appVersion started', tag: 'main');
  runApp(const FreeCadLauncherApp());
}
