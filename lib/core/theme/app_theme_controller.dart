import 'package:flutter/material.dart';

import '../storage/local_storage.dart';

/// The selected appearance is shared by every route and saved between launches.
class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static void init() {
    mode.value = switch (LocalStorage().themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    await LocalStorage().saveThemeMode(value.name);
  }
}
