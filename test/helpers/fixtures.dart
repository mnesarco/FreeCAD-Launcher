import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

String fixturePath(String name) => p.join('test', 'fixtures', name);

String loadFixture(String name) => File(fixturePath(name)).readAsStringSync();

Object? loadJsonFixture(String name) => jsonDecode(loadFixture(name));
