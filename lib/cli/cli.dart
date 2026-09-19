import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/state/app_services.dart';

const int cliOk = 0;
const int cliFailure = 1;
const int cliUsage = 2;

const String _usage = '''
FreeCAD Launcher $appVersion

Usage:
  freecad-launcher                        Open the graphical application
  freecad-launcher list                   List profiles
  freecad-launcher run <profile> [-- <args>...]
                                          Launch a profile; arguments after --
                                          are passed through to FreeCAD
  freecad-launcher --version              Print the version
  freecad-launcher --help                 Show this help
''';

Future<int> runCli(
  List<String> arguments, {
  required AppServices services,
  required StringSink out,
  required StringSink err,
}) async {
  if (arguments.isEmpty) {
    err.writeln(_usage);
    return cliUsage;
  }

  switch (arguments.first) {
    case '-h' || '--help':
      out.writeln(_usage);
      return cliOk;
    case '-v' || '--version':
      out.writeln('$appName $appVersion');
      return cliOk;
    case 'list':
      return _list(services, out);
    case 'run':
      return _run(arguments, services, err);
    default:
      err.writeln('Unknown command: ${arguments.first}\n');
      err.writeln(_usage);
      return cliUsage;
  }
}

Future<int> _list(AppServices services, StringSink out) async {
  final profiles = await services.profilesRepository.getAll();
  for (final profile in profiles) {
    final build = await services.database.buildsDao.getById(profile.buildId);
    out.writeln(
      [
        profile.name,
        build?.version ?? '—',
        build?.channel.name ?? '—',
        'py${profile.pythonVersion}',
      ].join('\t'),
    );
  }
  return cliOk;
}

Future<int> _run(List<String> arguments, AppServices services, StringSink err) async {
  if (arguments.length < 2) {
    err.writeln('Usage: $appName run <profile> [-- <args>...]');
    return cliUsage;
  }

  final profileName = arguments[1];
  final separator = arguments.indexOf('--', 2);
  final passthrough = separator >= 0
      ? arguments.sublist(separator + 1)
      : const <String>[];
  if (separator == -1 && arguments.length > 2) {
    err.writeln('Extra arguments must come after --');
    return cliUsage;
  }

  final profile = await services.profilesRepository.getByName(profileName);
  if (profile == null) {
    err.writeln('Profile not found: $profileName');
    return cliUsage;
  }

  final result = await services.profiles.launch(
    profileId: profile.id,
    userArguments: passthrough,
  );

  if (result.isQuarantineRequired) {
    err.writeln(
      'The app bundle is quarantined; open the launcher UI and launch once to '
      'review and remove the quarantine attribute, then retry.',
    );
    return cliFailure;
  }
  if (result.isFailure || result.launch == null) {
    err.writeln('Launch failed: ${result.error}');
    return cliFailure;
  }

  return result.launch!.exitCode;
}
