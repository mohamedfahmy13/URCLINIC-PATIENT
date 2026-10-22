import 'package:flutter/material.dart';

/// Keeps a user's preference separate from the currently resolved brightness.
class AppThemeModeController extends ChangeNotifier
    with WidgetsBindingObserver {
  final ValueChanged<bool> onBrightnessChanged;
  ThemeMode _mode = ThemeMode.light;
  bool _dark = false;

  AppThemeModeController({required this.onBrightnessChanged}) {
    WidgetsBinding.instance.addObserver(this);
  }

  ThemeMode get mode => _mode;
  bool get isDark => _dark;

  void setMode(ThemeMode mode) {
    final changed = _mode != mode;
    _mode = mode;
    _resolve(preferenceChanged: changed);
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode == ThemeMode.system) _resolve();
  }

  void _resolve({bool preferenceChanged = false}) {
    final dark = _mode == ThemeMode.dark ||
        (_mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    final changed = _dark != dark;
    _dark = dark;
    // Synchronize legacy nb_utils styles before widgets rebuild.
    onBrightnessChanged(dark);
    if (changed || preferenceChanged) notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
