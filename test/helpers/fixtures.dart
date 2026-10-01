// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

String fixturePath(String name) => p.join('test', 'fixtures', name);

String loadFixture(String name) => File(fixturePath(name)).readAsStringSync();

Object? loadJsonFixture(String name) => jsonDecode(loadFixture(name));
