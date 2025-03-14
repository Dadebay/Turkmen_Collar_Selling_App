// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_constants.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'PlusJakartaSans',
      colorSchemeSeed: ColorConstants.primaryColor,
      useMaterial3: true,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ColorConstants.whiteColor,
      ),
      scaffoldBackgroundColor: ColorConstants.whiteColor,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: ColorConstants.primaryColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
        ),
        elevation: 0,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
