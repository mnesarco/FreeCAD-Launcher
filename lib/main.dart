// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/cli/cli.dart';
import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/platform/tls_trust.dart';
import 'package:freecad_launcher/state/app_services.dart';

Future<void> main(List<String> arguments) async {
  final startup = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.bootstrap();
  appLogger = Logger(
    sinks: [
      RotatingFileSink(directory: Directory(services.paths.logsDir)),
      const ConsoleSink(),
    ],
  );
  effect(() => appLogger.level = services.settings.logLevel.value);
  appLogger.info(
    'startup: bootstrap at ${startup.elapsedMilliseconds} ms',
    tag: 'perf',
  );

  final trust = installAdditionalTrust(
    extraBundlePath: p.join(services.paths.dataRoot, 'ca-bundle.pem'),
  );
  if (trust.hasCertificates || trust.error != null) {
    appLogger.info(
      'TLS trust: $trust (exe: ${Platform.resolvedExecutable})',
      tag: 'main',
    );
  }

  if (arguments.isEmpty) {
    appLogger.info('$appName $appVersion started', tag: 'main');
    runApp(FreeCadLauncherApp(services: services));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appLogger.info(
        'startup: first frame at ${startup.elapsedMilliseconds} ms',
        tag: 'perf',
      );
    });
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
