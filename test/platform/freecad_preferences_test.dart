import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/freecad_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  late Directory tempDirectory;
  late String userCfgPath;
  const preferences = FreeCadPreferences();

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_freecad_prefs');
    userCfgPath = p.join(tempDirectory.path, 'user.cfg');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  String? macroPath() {
    final document = XmlDocument.parse(File(userCfgPath).readAsStringSync());
    final matches = document.rootElement
        .findAllElements('FCText')
        .where((element) => element.getAttribute('Name') == 'MacroPath')
        .toList();
    expect(matches, hasLength(1));
    return matches.single.innerText;
  }

  test('creates a minimal config with the forced MacroPath', () {
    final ok = preferences.ensureMacroPath(
      userCfgPath: userCfgPath,
      macroPath: p.join(tempDirectory.path, 'profiles', 'p1', 'Macros'),
    );

    expect(ok, isTrue);
    final document = XmlDocument.parse(File(userCfgPath).readAsStringSync());
    expect(document.rootElement.name.local, 'FCParameters');
    expect(
      document.rootElement.findAllElements('FCParamGroup').map(
        (element) => element.getAttribute('Name'),
      ),
      containsAll(['Root', 'BaseApp', 'Preferences', 'Macro']),
    );
    expect(macroPath(), endsWith('Macros/'));
  });

  test('replaces an existing MacroPath and preserves other settings', () {
    File(userCfgPath).writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<FCParameters>
  <FCParamGroup Name="Root">
    <FCParamGroup Name="BaseApp">
      <FCParamGroup Name="Preferences">
        <FCParamGroup Name="Macro">
          <FCText Name="MacroPath">/old/Macro/</FCText>
        </FCParamGroup>
      </FCParamGroup>
      <FCParamGroup Name="RecentFiles">
        <FCText Name="File1">/data/model.FCStd</FCText>
      </FCParamGroup>
    </FCParamGroup>
    <FCParamGroup Name="Gui">
      <FCBool Name="ShowSplash">true</FCBool>
    </FCParamGroup>
  </FCParamGroup>
</FCParameters>
''');

    final ok = preferences.ensureMacroPath(
      userCfgPath: userCfgPath,
      macroPath: p.join(tempDirectory.path, 'Macros'),
    );

    expect(ok, isTrue);
    expect(macroPath(), '${p.join(tempDirectory.path, 'Macros')}/');
    final document = XmlDocument.parse(File(userCfgPath).readAsStringSync());
    expect(
      document.rootElement
          .findAllElements('FCText')
          .where((element) => element.getAttribute('Name') == 'File1')
          .single
          .innerText,
      '/data/model.FCStd',
    );
    expect(
      document.rootElement
          .findAllElements('FCBool')
          .where((element) => element.getAttribute('Name') == 'ShowSplash')
          .single
          .innerText,
      'true',
    );
  });

  test('is idempotent', () {
    final macroDirectory = p.join(tempDirectory.path, 'Macros');
    preferences.ensureMacroPath(userCfgPath: userCfgPath, macroPath: macroDirectory);
    preferences.ensureMacroPath(userCfgPath: userCfgPath, macroPath: macroDirectory);

    expect(macroPath(), '$macroDirectory/');
  });

  test('leaves an unreadable config untouched', () {
    File(userCfgPath).writeAsStringSync('<not-valid');

    final ok = preferences.ensureMacroPath(
      userCfgPath: userCfgPath,
      macroPath: p.join(tempDirectory.path, 'Macros'),
    );

    expect(ok, isFalse);
    expect(File(userCfgPath).readAsStringSync(), '<not-valid');
  });
}
