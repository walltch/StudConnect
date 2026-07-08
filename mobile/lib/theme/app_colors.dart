import 'package:flutter/material.dart';

/// Design tokens mirrored from the web app's tailwind.config.ts,
/// so both StudConnect clients share the same visual identity.
class AppColors {
  AppColors._();

  static const brand50 = Color(0xFFEEF2FF);
  static const brand100 = Color(0xFFE0E7FF);
  static const brand200 = Color(0xFFC7D2FE);
  static const brand500 = Color(0xFF6366F1);
  static const brand600 = Color(0xFF4F46E5);
  static const brand700 = Color(0xFF4338CA);
  static const brand900 = Color(0xFF1E1B4B);

  static const accent400 = Color(0xFFFB923C);
  static const accent500 = Color(0xFFF97316);
  static const accent600 = Color(0xFFEA580C);

  static const surface0 = Color(0xFFFFFFFF);
  static const surface1 = Color(0xFFF8FAFC);
  static const surface2 = Color(0xFFF1F5F9);

  static const slate100 = Color(0xFFF1F5F9);
  static const slate600 = Color(0xFF475569);
  static const slate800 = Color(0xFF1E293B);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand600, Color(0xFF7C3AED)],
  );

  /// Mirrors TAG_COLORS from src/lib/mock-data.ts: (background, text) per tag.
  static const Map<String, (Color, Color)> tagColors = {
    'Informatique': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'Mathématiques': (Color(0xFFF3E8FF), Color(0xFF7E22CE)),
    'Gestion de projet': (Color(0xFFFFEDD5), Color(0xFFC2410C)),
    'IA / ML': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
    'Droit': (Color(0xFFFEE2E2), Color(0xFFB91C1C)),
    'Langues': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'Sciences': (Color(0xFFCCFBF1), Color(0xFF0F766E)),
    'Marketing': (Color(0xFFFCE7F3), Color(0xFFBE185D)),
    'Stage / Alternance': (Color(0xFFFEF3C7), Color(0xFFB45309)),
    'Autre': (Color(0xFFF1F5F9), Color(0xFF475569)),
  };
}
