import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Card style mirroring the web's `.card` utility: white bg, rounded-xl,
/// subtle shadow, slate-100 border.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand600,
      primary: AppColors.brand600,
      surface: AppColors.surface0,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface1,
      textTheme: textTheme.apply(
        bodyColor: AppColors.slate800,
        displayColor: AppColors.slate800,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface0,
        foregroundColor: AppColors.slate800,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.slate800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.slate600,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.slate800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: AppColors.brand600,
        unselectedItemColor: AppColors.slate600,
        backgroundColor: AppColors.surface0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand600,
        foregroundColor: Colors.white,
      ),
    );
  }
}
