import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  /// [useGoogleFonts] is false in tests so no network font fetching happens.
  static ThemeData light(Locale locale, {bool useGoogleFonts = true}) {
    final isArabic = locale.languageCode == 'ar';
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.forest,
      onPrimary: AppColors.paper,
      secondary: AppColors.moss,
      tertiary: AppColors.coral,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      outline: AppColors.line,
      error: AppColors.coral,
    );

    final base = ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme;
    final body = useGoogleFonts
        ? (isArabic ? GoogleFonts.notoNaskhArabicTextTheme(base) : GoogleFonts.sourceSans3TextTheme(base))
        : base;

    TextStyle? heading(TextStyle? s) {
      if (!useGoogleFonts || s == null) return s;
      return isArabic ? GoogleFonts.amiri(textStyle: s, fontWeight: FontWeight.w700) : GoogleFonts.fraunces(textStyle: s, fontWeight: FontWeight.w600);
    }

    final textTheme = body
        .copyWith(
          displaySmall: heading(body.displaySmall),
          headlineLarge: heading(body.headlineLarge),
          headlineMedium: heading(body.headlineMedium),
          headlineSmall: heading(body.headlineSmall),
          titleLarge: heading(body.titleLarge),
        )
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    const radius = BorderRadius.all(Radius.circular(4));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: textTheme,
      focusColor: AppColors.forest.withValues(alpha: 0.18),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: AppColors.ink,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: AppColors.line)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperDeep.withValues(alpha: 0.5),
        border: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.line)),
        enabledBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.line)),
        focusedBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.forest, width: 2)),
        errorBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.coral)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.coral, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.paper,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AppColors.forest),
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: AppColors.line)),
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.mossSoft,
        labelStyle: textTheme.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paperDeep,
        indicatorColor: AppColors.mossSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.paperDeep,
        indicatorColor: AppColors.mossSoft,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
