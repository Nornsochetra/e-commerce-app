import 'package:flutter/material.dart';

/// Mercato design tokens, taken from the HTML prototype (docs/prototype/assets/mercato.css).

/// Colours used across the app.
class AppColors {
  static const primary = Color(0xFF10B981); // emerald: accents, focus, progress
  static const primaryDark = Color(0xFF047857); // main buttons, selected states
  static const primaryDeep = Color(0xFF065F46); // pressed buttons, text on mint
  static const mint = Color(0xFFD1FAE5); // soft highlights, secondary buttons
  static const mintSoft = Color(0xFFECFDF5); // tinted cards and icon tiles

  static const background = Color(0xFFFAFAF8); // warm white page background
  static const surface = Color(0xFFFFFFFF); // cards and sheets
  static const field = Color(0xFFF3F4F1); // input and stepper background
  static const media = Color(0xFFF1F2EE); // image placeholder background
  static const line = Color(0xFFECEEEA); // borders and dividers

  static const text = Color(0xFF0F172A); // primary text
  static const textMuted = Color(0xFF64748B); // secondary text
  static const textFaint = Color(0xFF94A3B8); // hints and disabled text

  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEE2E2);
  static const info = Color(0xFF2563EB);
  static const infoBg = Color(0xFFDBEAFE);
  static const star = Color(0xFFF59E0B);
}

/// Text styles (Manrope).
class AppText {
  static const display = TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.text);
  static const title = TextStyle(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.text);
  static const section = TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.text);
  static const headerTitle = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text);
  static const head = TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: AppColors.text);
  static const body = TextStyle(fontSize: 14, height: 22 / 14, fontWeight: FontWeight.w400, color: AppColors.text);
  static const bodyMuted = TextStyle(fontSize: 14, height: 22 / 14, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static const meta = TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, color: AppColors.textMuted);
  static const eyebrow = TextStyle(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: AppColors.primaryDark);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text);
  static const button = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  static const price = TextStyle(fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: AppColors.text);
}

/// Spacing (4px scale), corner radii and shadows.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Left/right padding of every screen.
  static const double page = 20;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  /// Height of the main buttons and text fields.
  static const double controlHeight = 52;

  static const List<BoxShadow> shadowSoft = [BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1))];
  static const List<BoxShadow> shadowFloat = [BoxShadow(color: Color(0x380F172A), blurRadius: 40, spreadRadius: -12, offset: Offset(0, 16))];
}

/// The app's [ThemeData], used in main.dart.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryDark,
    primary: AppColors.primaryDark,
    onPrimary: Colors.white,
    secondary: AppColors.mint,
    onSecondary: AppColors.primaryDeep,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.error,
  );
  const pill = StadiumBorder();
  final inputRadius = BorderRadius.circular(AppSpacing.radiusMd);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.line,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      headlineMedium: AppText.display,
      headlineSmall: AppText.title,
      titleLarge: AppText.section,
      titleMedium: AppText.head,
      bodyMedium: AppText.body,
      bodySmall: AppText.meta,
      labelLarge: AppText.button,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primaryDark.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, AppSpacing.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        shape: pill,
        textStyle: AppText.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(0, AppSpacing.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        shape: pill,
        textStyle: AppText.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        minimumSize: const Size(44, 44),
        textStyle: AppText.button.copyWith(fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
      border: OutlineInputBorder(borderRadius: inputRadius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: Colors.transparent, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      errorStyle: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF111827),
      contentTextStyle: const TextStyle(fontFamily: 'Manrope', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      actionTextColor: const Color(0xFF6EE7B7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      dragHandleColor: Color(0xFFE2E5DF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary, linearTrackColor: AppColors.mint),
  );
}
