import 'package:flutter/material.dart';

extension ContextPaddingExtension on BuildContext {
  _PaddingHelper get padding => const _PaddingHelper();
}

class _PaddingHelper {
  const _PaddingHelper();

  EdgeInsets get low => const EdgeInsets.all(8);
  EdgeInsets get normal => const EdgeInsets.all(16);
  EdgeInsets get medium => const EdgeInsets.all(24);
  EdgeInsets get high => const EdgeInsets.all(32);

  EdgeInsets get horizontalLow => const EdgeInsets.symmetric(horizontal: 8);
  EdgeInsets get horizontalNormal => const EdgeInsets.symmetric(horizontal: 16);
  EdgeInsets get horizontalMedium => const EdgeInsets.symmetric(horizontal: 24);
  EdgeInsets get horizontalHigh => const EdgeInsets.symmetric(horizontal: 32);

  EdgeInsets get verticalLow => const EdgeInsets.symmetric(vertical: 8);
  EdgeInsets get verticalNormal => const EdgeInsets.symmetric(vertical: 16);
  EdgeInsets get verticalMedium => const EdgeInsets.symmetric(vertical: 24);
  EdgeInsets get verticalHigh => const EdgeInsets.symmetric(vertical: 32);

  EdgeInsets get onlyTopLow => const EdgeInsets.only(top: 8);
  EdgeInsets get onlyTopNormal => const EdgeInsets.only(top: 16);
  EdgeInsets get onlyBottomLow => const EdgeInsets.only(bottom: 8);
  EdgeInsets get onlyBottomNormal => const EdgeInsets.only(bottom: 16);
  EdgeInsets get onlyLeftLow => const EdgeInsets.only(left: 8);
  EdgeInsets get onlyLeftNormal => const EdgeInsets.only(left: 16);
  EdgeInsets get onlyRightLow => const EdgeInsets.only(right: 8);
  EdgeInsets get onlyRightNormal => const EdgeInsets.only(right: 16);
}

extension ContextBorderExtension on BuildContext {
  _BorderHelper get border => const _BorderHelper();
}

class _BorderHelper {
  const _BorderHelper();

  BorderRadius get lowBorderRadius => BorderRadius.circular(8);
  BorderRadius get normalBorderRadius => BorderRadius.circular(15);
  BorderRadius get highBorderRadius => BorderRadius.circular(30);
}

extension ContextGeneralExtension on BuildContext {
  _GeneralHelper get general => _GeneralHelper(this);
}

class _GeneralHelper {
  const _GeneralHelper(this._context);

  final BuildContext _context;

  TextTheme get textTheme => Theme.of(_context).textTheme;
  ThemeData get theme => Theme.of(_context);
  ColorScheme get colorScheme => Theme.of(_context).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(_context);
  MediaQueryData get mediaQuery => MediaQuery.of(_context);
}
