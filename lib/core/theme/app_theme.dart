import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Web 用の軽量ページ遷移(フェードのみ)。
/// CanvasKit(モバイル Safari)では Cupertino のパララックス遷移が重く、
/// 戻る操作がもたつくため、Web では安価なフェードに置き換える。
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

/// 推し色 (seed) から、男女問わず使えるニュートラルで上品なテーマを生成する。
class AppTheme {
  // Web では全プラットフォームで軽量フェード遷移を使う(高速化)。
  // ネイティブ実機では各 OS 既定の遷移を維持。
  static const PageTransitionsTheme _pageTransitions = kIsWeb
      ? PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _FadePageTransitionsBuilder(),
            TargetPlatform.iOS: _FadePageTransitionsBuilder(),
            TargetPlatform.macOS: _FadePageTransitionsBuilder(),
            TargetPlatform.windows: _FadePageTransitionsBuilder(),
            TargetPlatform.linux: _FadePageTransitionsBuilder(),
            TargetPlatform.fuchsia: _FadePageTransitionsBuilder(),
          },
        )
      : PageTransitionsTheme();
  // 同梱フォント(オフライン対応)。見出し・本文ともクセのない角ゴシックで統一。
  static const String _fontHeading = 'ZenKakuGothicNew';
  static const String _fontBody = 'ZenKakuGothicNew';

  static ThemeData light(Color seed) => _build(seed, Brightness.light);
  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  // ニュートラルな背景(やや寒色寄りのグレー。真っ白を避ける)。
  static const Color _lightBg = Color(0xFFF4F5F7);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _darkBg = Color(0xFF15181E);
  static const Color _darkCard = Color(0xFF1F242C);

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
      pageTransitionsTheme: _pageTransitions,
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
    // 見出し・本文とも Zen Kaku Gothic New(ニュートラルな角ゴシック)で統一。
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

  /// グラフ用のニュートラルパレット(寒色・中性色を中心に)。
  static const List<Color> mutedChartColors = [
    Color(0xFF5B7AA8), // スレートブルー
    Color(0xFF5E9C8E), // ティールグリーン
    Color(0xFFC2A35A), // マスタード
    Color(0xFF8E7CB0), // インディゴグレー
    Color(0xFF8A99A8), // グレーブルー
    Color(0xFFC08A7A), // テラコッタ
  ];

  /// 推し色プリセット(12色・男女問わず使える中性〜寒色を中心にバランス)。
  static const List<Color> presetColors = [
    Color(0xFF44597A), // ネイビー
    Color(0xFF4F7CAC), // スチールブルー
    Color(0xFF3FA39B), // ティール
    Color(0xFF5C9A6A), // フォレストグリーン
    Color(0xFF7E8CA0), // スレートグレー
    Color(0xFF8E7CB0), // インディゴ
    Color(0xFFC2A35A), // マスタード
    Color(0xFFCB7A4E), // テラコッタオレンジ
    Color(0xFF9C5A5A), // バーガンディ
    Color(0xFF6D7A52), // オリーブ
    Color(0xFF4A4F5C), // チャコール
    Color(0xFFC58FAE), // くすみピンク(推し色として選べる)
  ];
}
