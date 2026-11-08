// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_constants.dart';
import 'app_palette.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Gilroy',
      colorSchemeSeed: ColorConstants.primaryColor,
      extensions: const [AppPalette.light],
      useMaterial3: true,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ColorConstants.whiteColor,
      ),
      scaffoldBackgroundColor: ColorConstants.whiteColor,
      cardColor: AppPalette.light.surface,
      dividerColor: AppPalette.light.border,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
        ),
        elevation: 0,
      ),
      // Use the Material fade-through slide on every platform so page
      // transitions are consistent and never fall back to the iOS-style
      // Cupertino swipe (which looked broken on tab navigation).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: ColorConstants.primaryColor,
      brightness: Brightness.dark,
      surface: const Color(0xff15171c),
    );
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Gilroy',
      colorScheme: scheme,
      useMaterial3: true,
      extensions: const [AppPalette.dark],
      scaffoldBackgroundColor: scheme.surface,
      cardColor: AppPalette.dark.surface,
      dividerColor: AppPalette.dark.border,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppPalette.dark.surface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppPalette.dark.surface,
        foregroundColor: AppPalette.dark.text,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: AppPalette.dark.border)),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppPalette.dark.surface,
        labelStyle: TextStyle(color: AppPalette.dark.muted),
        hintStyle: TextStyle(color: AppPalette.dark.muted),
      ),
      pageTransitionsTheme: lightTheme.pageTransitionsTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
