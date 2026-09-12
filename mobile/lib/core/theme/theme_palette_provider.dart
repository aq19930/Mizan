import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

const String _prefKeyThemePalette = 'mizan_pref_theme_palette';

final themePaletteProvider = StateNotifierProvider<ThemePaletteNotifier, AppThemePalette>((ref) {
  return ThemePaletteNotifier();
});

class ThemePaletteNotifier extends StateNotifier<AppThemePalette> {
  ThemePaletteNotifier() : super(AppThemePalette.emerald) {
    _loadSavedPalette();
  }

  Future<void> _loadSavedPalette() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyThemePalette);
      if (saved != null) {
        state = AppThemePalette.values.firstWhere(
          (p) => p.name == saved,
          orElse: () => AppThemePalette.emerald,
        );
      }
    } catch (_) {}
  }

  Future<void> setPalette(AppThemePalette palette) async {
    state = palette;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyThemePalette, palette.name);
    } catch (_) {}
  }

  PaletteColors get activeColors => AppColors.getPalette(state);
}
