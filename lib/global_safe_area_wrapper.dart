import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global SafeArea wrapper for the entire app
/// Automatically handles system UI overlays (status bar, navigation bar, etc.)
/// Works correctly on Android 15+ and all other devices
class GlobalSafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const GlobalSafeAreaWrapper({
    required this.child,
    super.key,
    this.top = false,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _getSystemUiOverlayStyle(context),
      child: SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: child,
      ),
    );
  }

  SystemUiOverlayStyle _getSystemUiOverlayStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: true,
    );
  }
}
