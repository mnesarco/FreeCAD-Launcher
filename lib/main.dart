import 'package:flutter/material.dart';
import 'database.dart';
import 'controller.dart';
import 'view/home.dart';

void main() async {
  Database db = Database();
  MainController controller = MainController(db);
  runApp(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: HomeView(controller: controller),
    ),
  );
}
