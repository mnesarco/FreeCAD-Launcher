import 'package:signals_flutter/signals_flutter.dart';

enum AppSection { home, profiles, versions, addons, macros, settings }

class ShellController {
  final section = signal(AppSection.home);

  void select(AppSection value) {
    section.value = value;
  }

  void selectIndex(int index) {
    if (index < 0 || index >= AppSection.values.length) {
      return;
    }
    section.value = AppSection.values[index];
  }
}
