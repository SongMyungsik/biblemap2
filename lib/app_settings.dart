import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 앱 색상 팔레트 (앱바 · 하단 네비 공통)
const List<({String name, Color color})> appColorPalette = [
  (name: '연두', color: Color.fromARGB(255, 235, 245, 178)),
  (name: '하늘', color: Color.fromARGB(255, 220, 240, 255)),
  (name: '분홍', color: Color.fromARGB(255, 255, 224, 235)),
  (name: '라벤더', color: Color.fromARGB(255, 230, 220, 250)),
  (name: '살구', color: Color.fromARGB(255, 255, 228, 196)),
  (name: '민트', color: Color.fromARGB(255, 200, 240, 225)),
  (name: '회색', color: Color.fromARGB(255, 225, 225, 225)),
  (name: '보라', color: Color(0xFF5C3D99)),
  (name: '파랑', color: Color(0xFF1E88E5)),
  (name: '초록', color: Color(0xFF2E7D32)),
];

// 앱 전체 설정 (화면 모드 · 앱 색상). SharedPreferences에 저장한다.
class AppSettings {
  AppSettings._();

  static const _kThemeMode = 'theme_mode';
  static const _kAppColor = 'app_color';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Color> appColor =
      ValueNotifier(appColorPalette.first.color);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString(_kThemeMode);
      themeMode.value = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
      final colorValue = prefs.getInt(_kAppColor);
      if (colorValue != null) appColor.value = Color(colorValue);
    } catch (_) {}
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeMode, mode.name);
    } catch (_) {}
  }

  static Future<void> setAppColor(Color color) async {
    appColor.value = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kAppColor, color.toARGB32());
    } catch (_) {}
  }
}

// 다크 모드에서는 같은 색상 계열을 어둡게 낮춰서 사용한다.
Color effectiveAppColor(Color base, Brightness brightness) {
  if (brightness != Brightness.dark) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness(hsl.lightness.clamp(0.0, 0.28))
      .withSaturation(hsl.saturation.clamp(0.0, 0.5))
      .toColor();
}

Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;

ThemeData buildAppTheme(Color appColor, Brightness brightness) {
  final bar = effectiveAppColor(appColor, brightness);
  final fg = onColor(bar);
  final barIsDark = fg == Colors.white;
  return ThemeData(
    primarySwatch: Colors.purple,
    brightness: brightness,
    appBarTheme: AppBarTheme(
      backgroundColor: bar,
      foregroundColor: fg,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: fg,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bar,
      selectedItemColor: barIsDark
          ? Colors.amberAccent
          : const Color.fromARGB(255, 255, 53, 53),
      unselectedItemColor: barIsDark ? Colors.white70 : Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// 다크 모드 대응용 색상 (하드코딩된 밝은 색을 대체)
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get pageBg =>
      isDark ? Theme.of(this).scaffoldBackgroundColor : const Color(0xFFF8F5FF);
  Color get cardBg => isDark ? const Color(0xFF2A2A2E) : Colors.white;
  Color get softBg => isDark ? const Color(0xFF232326) : Colors.grey.shade100;
  Color get textMain => isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87;
  Color get textSub => isDark ? Colors.white60 : Colors.grey.shade700;
  Color get borderSoft => isDark ? Colors.white24 : Colors.grey.shade300;
}
