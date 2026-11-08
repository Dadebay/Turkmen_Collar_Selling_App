import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/icons/app_icon.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_palette.dart';

/// Opens the profile language picker and returns the selected language code.
Future<String?> showLanguageSheet(
  BuildContext context, {
  required String currentLocale,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: 0.24),
    builder: (sheetContext) {
      final bottomGap = math.max(
        12.0,
        MediaQuery.viewPaddingOf(sheetContext).bottom,
      );

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, bottomGap),
                  child: _LanguageSheet(currentLocale: currentLocale),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.currentLocale});

  final String currentLocale;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 390,
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AppIcon(
                        Icons.language_rounded,
                        size: 40,
                        color: palette.text,
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            fixedSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                          ),
                          icon: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: AppIcon(
                              Icons.close_rounded,
                              size: 18,
                              color: palette.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'select_language'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'language_selection_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 26),
                Material(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LanguageRow(
                        code: 'tk',
                        title: 'Türkmençe',
                        subtitle: 'turkmen_lang'.tr,
                        selected: currentLocale == 'tk',
                      ),
                      Divider(height: 1, thickness: 1, color: palette.surface),
                      _LanguageRow(
                        code: 'ru',
                        title: 'Русский',
                        subtitle: 'russian_lang'.tr,
                        selected: currentLocale == 'ru',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final flag = code == 'tk' ? IconConstants.tmIcon : IconConstants.ruIcon;

    return InkWell(
      key: Key('language-option-$code'),
      onTap: () => Navigator.of(context).pop(code),
      child: SizedBox(
        height: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: ClipOval(child: Image.asset(flag, fit: BoxFit.cover)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              if (selected)
                AppIcon(Icons.check_rounded, size: 28, color: palette.text),
            ],
          ),
        ),
      ),
    );
  }
}
