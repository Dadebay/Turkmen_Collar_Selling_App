// ignore_for_file: always_put_control_body_on_new_line
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, MethodChannel;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/constants/list_constants.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firebase_messaging_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme_controller.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/theme_reveal.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/profile_button.dart';
import '../../../ai_chat/data/datasources/chat_socket_service.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../widgets/language_sheet.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  static const _usbStorageChannel = MethodChannel('com.example.usb_storage');

  Future<void> _openDownloadsFolder() async {
    try {
      final openedUsbFolder =
          await _usbStorageChannel.invokeMethod<bool>('openSourceFolder') ??
          false;
      if (openedUsbFolder) return;
    } catch (_) {
      /* fall through to system downloads folder */
    }
    await _usbStorageChannel.invokeMethod<bool>('openDownloadsFolder');
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final selected = await showLanguageSheet(
      context,
      currentLocale: AppTranslations.currentLocale,
    );
    if (selected == null || selected == AppTranslations.currentLocale) return;

    await LocalStorage().saveLocale(selected);
    AppTranslations.setLocale(selected);
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    const danger = Color(0xFFC92A2A);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = AppPalette.of(dialogContext);
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          backgroundColor: palette.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: danger.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: danger,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'deleteAccount'.tr,
                      style: textTheme.titleLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'deleteAccountSubtitle'.tr,
                      style: textTheme.bodyMedium?.copyWith(
                        color: palette.muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: ColorConstants.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'deleteAccountDataNotice'.tr,
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.text,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.text,
                          side: BorderSide(color: palette.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text('deleteAccountCancel'.tr),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text('deleteAccount'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await LocalStorage().clearAuth();
    ChatSocketService().disconnect();
    if (!context.mounted) return;
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    // Replace the stack so the protected pages cannot be returned to.
    context.go(AppRoutes.login);
  }

  void _setDarkMode(BuildContext context, bool enabled) {
    void change() => unawaited(
      AppThemeController.setMode(enabled ? ThemeMode.dark : ThemeMode.light),
    );

    final reveal = ThemeReveal.maybeOf(context);
    if (reveal == null) {
      change();
      return;
    }
    unawaited(
      reveal.run(
        change,
        direction: enabled
            ? ThemeRevealDirection.leftToRight
            : ThemeRevealDirection.rightToLeft,
      ),
    );
  }

  Future<void> _showFcmTokenDialog(BuildContext context) async {
    final token = await FirebaseMessagingService.instance().getToken();
    if (!context.mounted) return;

    if (token == null || token.isEmpty) {
      showSnackBar(context, 'attention', 'error', ColorConstants.redColor);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('FCM Token'),
          content: SelectableText(token),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: token));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('ok'.tr),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.localeNotifier,
      builder: (context, locale, _) => _buildBody(context, locale),
    );
  }

  Widget _buildBody(BuildContext context, String locale) {
    final isLoggedIn = (LocalStorage().token ?? '').isNotEmpty;
    final palette = AppPalette.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final groups = <List<_ProfileItem>>[
      [
        _ProfileItem(
          name: 'language',
          icon: Icons.language_rounded,
          trailing: Semantics(
            label: locale == 'tk' ? 'Türkmençe' : 'Русский',
            child: Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
              ),
              child: ClipOval(
                child: Image.asset(
                  locale == 'tk' ? IconConstants.tmIcon : IconConstants.ruIcon,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          onTap: () => _showLanguageDialog(context),
        ),
        _ProfileItem(
          name: 'themeDark',
          icon: Icons.dark_mode_outlined,
          onTap: () => _setDarkMode(context, !isDark),
          switchValue: isDark,
          onSwitchChanged: (value) => _setDarkMode(context, value),
        ),
        _ProfileItem(
          name: 'addMoney',
          icon: IconlyLight.wallet,
          onTap: () {
            if (!isLoggedIn) {
              showSnackBar(
                context,
                'loginError',
                'loginErrorSubtitle1',
                ColorConstants.redColor,
              );
              context.push(AppRoutes.login);
              return;
            }
            context.push(AppRoutes.addMoney);
          },
        ),
      ],
      [
        _ProfileItem(
          name: 'open_folder',
          icon: Icons.folder_open_rounded,
          onTap: _openDownloadsFolder,
        ),
        _ProfileItem(
          name: 'downloaded',
          icon: IconlyLight.download,
          onTap: () => context.push(AppRoutes.downloads),
        ),
        _ProfileItem(
          name: 'copyToUsb',
          icon: Icons.usb_rounded,
          onTap: () => context.push(AppRoutes.usbTransfer),
        ),
      ],
      [
        _ProfileItem(
          name: 'aboutUs',
          icon: IconlyLight.user3,
          onTap: () => context.push(AppRoutes.aboutUs),
          onLongPress: () => _showFcmTokenDialog(context),
        ),
        if (isLoggedIn)
          _ProfileItem(
            name: 'deleteAccount',
            icon: IconlyLight.delete,
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context),
          )
        else
          _ProfileItem(
            name: 'signUp',
            icon: IconlyLight.login,
            onTap: () => context.push(AppRoutes.login),
          ),
      ],
    ];

    return ColoredBox(
      color: palette.surfaceAlt,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              physics: const BouncingScrollPhysics(),
              children: [
                for (final group in groups) ...[
                  Material(
                    color: palette.surface,
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: palette.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var index = 0; index < group.length; index++) ...[
                          ProfilButton(
                            name: group[index].name,
                            icon: group[index].icon,
                            onTap: group[index].onTap,
                            onLongPress: group[index].onLongPress,
                            trailing: group[index].trailing,
                            isDestructive: group[index].isDestructive,
                            switchValue: group[index].switchValue,
                            onSwitchChanged: group[index].onSwitchChanged,
                          ),
                          if (index < group.length - 1)
                            Divider(
                              height: 1,
                              indent: 72,
                              endIndent: 16,
                              color: palette.border,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.32)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 17, color: accent),
                    const SizedBox(width: 7),
                    Text(
                      'version'.trParams({'version': ListConstants.appVersion}),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem {
  _ProfileItem({
    required this.name,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.isDestructive = false,
    this.switchValue,
    this.onSwitchChanged,
  });

  final String name;
  final Object icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool isDestructive;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
}
