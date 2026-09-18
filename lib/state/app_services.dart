import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';

import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/paths.dart';

class AppServices {
  AppServices({required this.paths, required this.database});

  final AppPaths paths;
  final AppDatabase database;

  static Future<AppServices> bootstrap() async {
    final paths = await AppPaths.resolve();
    await paths.ensureBaseDirectories();
    final database = AppDatabase(NativeDatabase(File(paths.databaseFile)));
    return AppServices(paths: paths, database: database);
  }

  Future<void> close() => database.close();
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
