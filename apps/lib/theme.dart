import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF0F172A);
  static const primary = Color(0xFF2563EB);
  static const muted = Color(0xFFF1F5F9);
  static const mutedForeground = Color(0xFF64748B);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);

  static const mutedHalf30 = Color(0x4DF1F5F9); // bg-muted/30
  static const white70 = Color(0xB3FFFFFF);
  static const white80 = Color(0xCCFFFFFF);
  static const white60 = Color(0x99FFFFFF);
  static const white40 = Color(0x66FFFFFF);
  static const white10 = Color(0x1AFFFFFF);
  static const black30 = Color(0x4D000000);
  static const black50 = Color(0x80000000);
  static const black60 = Color(0x99000000);
  static const black70 = Color(0xB3000000);
  static const transparentBlack = Color(0x00000000);
}

/// Breakpoint Tailwind: sm 640, md 768, lg 1024, xl 1280, 2xl 1536.
class Responsive {
  static double width(BuildContext c) => MediaQuery.of(c).size.width;
  static bool isSm(BuildContext c) => width(c) >= 640;
  static bool isMd(BuildContext c) => width(c) >= 768;
  static bool isLg(BuildContext c) => width(c) >= 1024;

  static double containerMaxWidth(double w) {
    if (w >= 1536) return 1536;
    if (w >= 1280) return 1280;
    if (w >= 1024) return 1024;
    if (w >= 768) return 768;
    if (w >= 640) return 640;
    return w;
  }
}

/// Gaya heading serif (font-serif) memakai font sistem.
/// Ganti nama font di sini jika ingin font lain.
TextStyle serif({
  required double size,
  required FontWeight weight,
  Color color = AppColors.foreground,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}
