import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Lựa chọn giao diện: chỉ Sáng/Tối/Hệ thống, mặc định Tối; giá trị cũ `warm` đọc thành `light`
/// (DESIGN_SYSTEM.md mục 1).
enum ThemeChoice {
  light,
  dark,
  system;

  static ThemeChoice parse(String? raw) => switch (raw) {
    'light' || 'warm' => ThemeChoice.light,
    'system' => ThemeChoice.system,
    _ => ThemeChoice.dark,
  };

  ThemeMode get mode => switch (this) {
    ThemeChoice.light => ThemeMode.light,
    ThemeChoice.dark => ThemeMode.dark,
    ThemeChoice.system => ThemeMode.system,
  };
}

final class QtTheme extends ThemeExtension<QtTheme> {
  const QtTheme(this.palette, this.chart);
  final QtPalette palette;
  final QtChartPalette chart;

  @override
  QtTheme copyWith({QtPalette? palette, QtChartPalette? chart}) =>
      QtTheme(palette ?? this.palette, chart ?? this.chart);

  @override
  QtTheme lerp(QtTheme? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension QtThemeContext on BuildContext {
  QtPalette get palette => Theme.of(this).extension<QtTheme>()!.palette;
  QtChartPalette get chartPalette => Theme.of(this).extension<QtTheme>()!.chart;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? QtPalette.dark : QtPalette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.textLink,
    onSecondary: p.onPrimary,
    error: p.danger,
    onError: p.onStatus,
    surface: p.bgSurface,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    outline: p.borderControl,
    outlineVariant: p.border,
    surfaceContainerLowest: p.bgBase,
    surfaceContainerLow: p.bgSurface,
    surfaceContainer: p.bgSubtle,
    surfaceContainerHigh: p.bgHover,
    surfaceContainerHighest: p.bgHover,
    scrim: p.overlay,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Inter',
    fontFamilyFallback: const ['SF Pro Text', 'Segoe UI', 'Roboto'],
  );
  final text = base.textTheme
      .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary, fontFamily: 'Inter')
      .copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: QtFontSize.h1,
          fontWeight: FontWeight.w700,
          height: QtLineHeight.heading,
          color: p.textPrimary,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontSize: QtFontSize.h2,
          fontWeight: FontWeight.w600,
          height: QtLineHeight.heading,
          color: p.textPrimary,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: QtFontSize.h3,
          fontWeight: FontWeight.w600,
          height: QtLineHeight.heading,
          color: p.textPrimary,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: QtFontSize.h4,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: QtFontSize.bodyWebLg,
          height: QtLineHeight.body,
          color: p.textPrimary,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: QtFontSize.bodyWeb,
          height: QtLineHeight.body,
          color: p.textPrimary,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: QtFontSize.sm, color: p.textSecondary),
        labelSmall: base.textTheme.labelSmall?.copyWith(fontSize: QtFontSize.xs, color: p.textSecondary),
      );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(QtRadius.md),
    borderSide: BorderSide(color: p.borderControl),
  );
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(QtRadius.md));
  const minButton = Size(64, 48);
  return base.copyWith(
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: p.bgBase,
    canvasColor: p.bgBase,
    dividerColor: p.border,
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    focusColor: p.focusRing.withValues(alpha: 0.16),
    hoverColor: p.bgHover,
    extensions: [QtTheme(p, brightness == Brightness.dark ? QtChartPalette.dark : QtChartPalette.light)],
    appBarTheme: AppBarTheme(
      backgroundColor: p.bgBase,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: p.bgSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QtRadius.lg),
        side: BorderSide(color: p.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.bgSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QtRadius.lg)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.bgSurface, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: InputDecorationTheme(
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: p.focusRing, width: 2)),
      errorBorder: border.copyWith(borderSide: BorderSide(color: p.danger)),
      focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: p.danger, width: 2)),
      labelStyle: TextStyle(color: p.textSecondary),
      floatingLabelStyle: TextStyle(color: p.textPrimary),
      helperStyle: TextStyle(color: p.textSecondary),
      hintStyle: TextStyle(color: p.textMuted),
      errorStyle: TextStyle(color: p.danger),
      filled: true,
      fillColor: p.bgSurface,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        minimumSize: minButton,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderControl),
        minimumSize: minButton,
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.textLink, minimumSize: minButton, shape: buttonShape),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QtRadius.lg)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.bgSurface,
      indicatorColor: p.bgHover,
      surfaceTintColor: Colors.transparent,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.bgSurface,
      indicatorColor: p.bgHover,
      selectedIconTheme: IconThemeData(color: p.primary),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.primary,
        selectedForegroundColor: p.onPrimary,
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderControl),
        minimumSize: const Size(48, 48),
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: p.textSecondary, textColor: p.textPrimary, minVerticalPadding: 8),
    switchTheme: SwitchThemeData(trackOutlineColor: WidgetStatePropertyAll(p.borderControl)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QtRadius.md)),
    ),
  );
}
