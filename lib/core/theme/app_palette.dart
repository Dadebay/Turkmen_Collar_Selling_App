import 'package:flutter/material.dart';

/// Colors used by custom widgets outside Flutter's built-in theme components.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.muted,
    required this.border,
  });

  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color muted;
  final Color border;

  static const light = AppPalette(
    surface: Colors.white,
    surfaceAlt: Color(0xfff6f7f9),
    text: Color(0xff111218),
    muted: Color(0xff757575),
    border: Color(0xffe5e5e5),
  );

  static const dark = AppPalette(
    surface: Color(0xff1c1e24),
    surfaceAlt: Color(0xff252831),
    text: Color(0xfff5f5f6),
    muted: Color(0xffafb2bd),
    border: Color(0xff3a3d47),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? muted,
    Color? border,
  }) => AppPalette(
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    border: border ?? this.border,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
