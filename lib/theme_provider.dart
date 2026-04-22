import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Canonical theme-mode key stored in SharedPreferences.
const _kThemePrefKey = 'imas_theme_mode';

/// Maps [ThemeMode] → persisted string and back.
extension _ThemeModeX on ThemeMode {
  String get key => switch (this) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode fromKey(String? key) => switch (key) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark, // safe default
      };
}

class ThemeProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;
  bool _initialized = false;

  ThemeProvider() {
    _init();
  }

  // ── Public getters ─────────────────────────────────────────────────

  ThemeMode get themeMode => _themeMode;

  /// True once prefs have been read — lets the UI show a splash
  /// instead of a flash between light/dark on first frame.
  bool get initialized => _initialized;

  /// Resolved brightness — respects ThemeMode.system.
  bool get isDark {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // ── Init ───────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemePrefKey);
    _themeMode = _ThemeModeX.fromKey(stored);
    _initialized = true;
    notifyListeners();
  }

  // ── Mutations ──────────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // no-op guard
    _themeMode = mode;
    notifyListeners(); // update UI immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemePrefKey, mode.key);
  }

  /// Cycles Dark → Light → System → Dark.
  Future<void> cycleTheme() async {
    final next = switch (_themeMode) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
      ThemeMode.system => ThemeMode.dark,
    };
    await setThemeMode(next);
  }

  /// Simple two-way toggle (dark ↔ light), ignores system.
  Future<void> toggleTheme() async {
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  // ── Helpers ────────────────────────────────────────────────────────

  /// Human-readable label for use in Settings UI.
  String get label => switch (_themeMode) {
        ThemeMode.dark => 'Dark',
        ThemeMode.light => 'Light',
        ThemeMode.system => 'System',
      };

  IconData get icon => switch (_themeMode) {
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };
}