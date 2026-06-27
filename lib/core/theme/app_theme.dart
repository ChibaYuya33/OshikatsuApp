import 'package:flutter/material.dart';

/// 推し色 (seed) から「大人可愛い・くすみ」テイストのテーマを生成する。
class AppTheme {
  // 同梱フォント(オフライン対応)。見出し=丸ゴシック、本文=角ゴシック。
  static const String _fontHeading = 'ZenMaruGothic';
  static const String _fontBody = 'ZenKakuGothicNew';

  static ThemeData light(Color seed) => _build(seed, Brightness.light);
  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  // 温かみのある背景(真っ白を避ける)。
  static const Color _lightBg = Color(0xFFFAF6F4);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _darkBg = Color(0xFF1A1617);
  static const Color _darkCard = Color(0xFF241F21);

  static ThemeData _build(Color seed, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: muted(seed),
      brightness: brightness,
    ).copyWith(
      surface: isLight ? _lightBg : _darkBg,
      surfaceContainerLowest: isLight ? _lightCard : _darkCard,
      surfaceContainerLow: isLight ? _lightCard : _darkCard,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
    );

    final text = _textTheme(base.textTheme, scheme);
    final hairline = scheme.outlineVariant.withValues(alpha: isLight ? 0.5 : 0.6);

    return base.copyWith(
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontHeading,
          color: scheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: hairline),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: hairline),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        labelStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
              fontFamily: _fontHeading,
              fontWeight: FontWeight.w700,
              fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
              fontFamily: _fontHeading, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        extendedTextStyle: const TextStyle(
            fontFamily: _fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleSmall?.copyWith(
          fontFamily: _fontBody,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: text.bodySmall?.copyWith(color: scheme.outline),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme baseText, ColorScheme scheme) {
    // 本文は Zen Kaku Gothic New、見出しは Zen Maru Gothic(丸み・上品)。
    final body = baseText.apply(fontFamily: _fontBody);
    TextStyle? maru(TextStyle? s, FontWeight w) =>
        s?.copyWith(fontFamily: _fontHeading, fontWeight: w);
    return body.copyWith(
      displayLarge: maru(body.displayLarge, FontWeight.w700),
      displayMedium: maru(body.displayMedium, FontWeight.w700),
      displaySmall: maru(body.displaySmall, FontWeight.w700),
      headlineLarge: maru(body.headlineLarge, FontWeight.w700),
      headlineMedium: maru(body.headlineMedium, FontWeight.w700),
      headlineSmall: maru(body.headlineSmall, FontWeight.w700),
      titleLarge: maru(body.titleLarge, FontWeight.w700),
      titleMedium: maru(body.titleMedium, FontWeight.w600),
    );
  }

  /// 色をくすませる(HSLで彩度↓・明度を中庸へ)。大人可愛いの肝。
  static Color muted(Color c) {
    final hsl = HSLColor.fromColor(c);
    final s = (hsl.saturation * 0.62).clamp(0.0, 1.0);
    // 明るすぎ/暗すぎを中庸に寄せる。
    final l = (hsl.lightness * 0.85 + 0.12).clamp(0.0, 1.0);
    return hsl.withSaturation(s).withLightness(l).toColor();
  }

  /// グラフ用のくすみパレット。
  static const List<Color> mutedChartColors = [
    Color(0xFFD8989E), // くすみローズ
    Color(0xFFCBA06E), // くすみマスタード
    Color(0xFF9FB3A6), // セージ
    Color(0xFF93A7C0), // ダスティブルー
    Color(0xFFB6A0C2), // くすみラベンダー
    Color(0xFFCBA59A), // テラコッタ
  ];

  /// 推し色プリセット(くすみ12色・大人可愛い)。
  static const List<Color> presetColors = [
    Color(0xFFE0A3AC), // くすみピンク
    Color(0xFFD98C9A), // ローズ
    Color(0xFFCB8E7E), // テラコッタ
    Color(0xFFD3A86E), // くすみマスタード
    Color(0xFFC9B27E), // ベージュゴールド
    Color(0xFFA7BB97), // セージ
    Color(0xFF8FB7A8), // くすみミント
    Color(0xFF8FAAC0), // ダスティブルー
    Color(0xFF9D9BC4), // くすみラベンダー
    Color(0xFFB594BC), // モーブパープル
    Color(0xFFC58FAE), // くすみマゼンタ
    Color(0xFFAD9A8C), // グレージュ
  ];
}
