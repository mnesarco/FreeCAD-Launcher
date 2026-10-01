// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:xml/xml.dart';

class FreeCadPreferences {
  const FreeCadPreferences();

  /// Forces `User parameter:BaseApp/Preferences/Macro` → `MacroPath` to
  /// [macroPath] in the profile's `user.cfg`, creating a minimal configuration
  /// when the file does not exist yet. Returns false when an existing file
  /// cannot be edited (it is left untouched).
  bool ensureMacroPath({required String userCfgPath, required String macroPath}) {
    final value =
        '${macroPath.replaceAll(RegExp(r'[\\/]+$'), '')}${Platform.pathSeparator == '\\' ? '\\' : '/'}';
    try {
      final file = File(userCfgPath);
      final XmlDocument document;
      if (!file.existsSync() || file.readAsStringSync().trim().isEmpty) {
        document = _emptyDocument();
      } else {
        document = XmlDocument.parse(file.readAsStringSync());
      }

      var group = _ensureGroup(document.rootElement, 'Root');
      group = _ensureGroup(group, 'BaseApp');
      group = _ensureGroup(group, 'Preferences');
      group = _ensureGroup(group, 'Macro');
      for (final node in group.childElements
          .where((element) => element.name.local == 'FCText')
          .where((element) => element.getAttribute('Name') == 'MacroPath')
          .toList()) {
        node.parent?.children.remove(node);
      }
      group.children.add(
        XmlElement(
          XmlName('FCText'),
          [XmlAttribute(XmlName('Name'), 'MacroPath')],
          [XmlText(value)],
        ),
      );

      file.parent.createSync(recursive: true);
      file.writeAsStringSync(document.toXmlString(pretty: true, indent: '  '));
      return true;
    } on Object {
      return false;
    }
  }

  XmlDocument _emptyDocument() {
    final macro = XmlElement(XmlName('FCParamGroup'), [XmlAttribute(XmlName('Name'), 'Macro')]);
    final preferences = XmlElement(
      XmlName('FCParamGroup'),
      [XmlAttribute(XmlName('Name'), 'Preferences')],
      [macro],
    );
    final baseApp = XmlElement(
      XmlName('FCParamGroup'),
      [XmlAttribute(XmlName('Name'), 'BaseApp')],
      [preferences],
    );
    final root = XmlElement(
      XmlName('FCParamGroup'),
      [XmlAttribute(XmlName('Name'), 'Root')],
      [baseApp],
    );
    final declaration = XmlDeclaration()
      ..version = '1.0'
      ..encoding = 'utf-8';
    return XmlDocument([
      declaration,
      XmlElement(XmlName('FCParameters'), [], [root]),
    ]);
  }

  XmlElement _ensureGroup(XmlElement parent, String name) {
    for (final child in parent.childElements) {
      if (child.name.local == 'FCParamGroup' && child.getAttribute('Name') == name) {
        return child;
      }
    }
    final group = XmlElement(XmlName('FCParamGroup'), [XmlAttribute(XmlName('Name'), name)]);
    parent.children.add(group);
    return group;
  }
}
