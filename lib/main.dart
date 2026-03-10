import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'service/database.dart';
import 'controller/main.dart';
import 'view/home.dart';

import 'service/applications.dart';

void main() async {
  driftRuntimeOptions.defaultSerializer = const ValueSerializer.defaults(
    serializeDateTimeValuesAsString: true,
  );

  Database db = Database();
  MainController controller = MainController(db);

  // // -- TESTS
  // final flatpak = FlatpakService();
  // final results = await flatpak.find();
  // results.fold(
  //   onFailure: (error) => print(error),
  //   onSuccess: (data) async {
  //     for (String target in data) {
  //       print("TARGET: $target");
  //       var v = await flatpak.getVersion(target);
  //       v.fold(onSuccess: (v) => print("  - $v"), onFailure: (e) => print(e));
  //     }
  //     // flatpak.launch(data[0]);
  //   },
  // );

  // final snap = SnapService();
  // final s_results = await snap.find();
  // s_results.fold(
  //   onFailure: (error) => print(error),
  //   onSuccess: (data) async {
  //     for (String target in data) {
  //       print("SNAP TARGET: $target");
  //       var v = await snap.getVersion(target);
  //       v.fold(onSuccess: (v) => print("  - SNAP VERSION $v"), onFailure: (e) => print(e));
  //     }
  //     // snap.launch(data[0], "/home/mnesarco/tmp/snap");
  //   },
  // );

  // END TESTS

  // runApp(
  //   MaterialApp(
  //     debugShowCheckedModeBanner: false,
  //     theme: ThemeData(useMaterial3: true),
  //     home: HomeView(controller: controller),
  //   ),
  // );

  controller.apps.importInstalledApps();

  runApp(HomeView(controller: controller));
}
