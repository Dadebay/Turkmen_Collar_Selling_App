// ignore_for_file: always_put_control_body_on_new_line
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:upgrader/upgrader.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/constants/list_constants.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/utils/upgrader_localization.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../features/ai_chat/data/datasources/chat_socket_service.dart';
import '../../../../features/ai_chat/data/models/message_model.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/home/presentation/bloc/balance/balance_bloc.dart';
import '../../../../features/payment/presentation/widgets/low_payment_dialog.dart';
import '../../../../injection_container.dart';
import '../../../../core/icons/app_icon.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({required this.child, super.key});
  final Widget child;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> with WidgetsBindingObserver {
  Timer? _balanceTimer;
  Timer? _loginPromptTimer;
  final GlobalKey _fabKey = GlobalKey();
  List<TargetFocus> _tutorialTargets = [];
  bool _hasUnreadMessages = false;
  late final void Function(ChatMessage) _chatListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reuse the user fetched during splash token validation (cached) instead of
    // making another `users/me` call, so the wallet shows the fresh value
    // immediately on landing rather than after the first 20s timer tick.
    if (sl<LocalStorage>().token?.isNotEmpty == true) {
      context.read<BalanceBloc>().add(
        const BalanceFetchRequested(forceRefresh: false),
      );
    }
    _startBalanceTimer();
    _startLoginPromptTimer();
    _initUnreadBadge();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeShowUpgradeDialog();
      await _maybeShowTutorial();
      await _maybeAskNotificationPermission();
      await checkPendingLowPaymentGate();
    });
  }

  void _initUnreadBadge() {
    final socket = ChatSocketService();
    final lastSeen = sl<LocalStorage>().lastSeenMessageId;
    _hasUnreadMessages = socket.messages.any(
      (m) => m.senderType == 'admin' && (m.id ?? 0) > lastSeen,
    );
    _chatListener = (ChatMessage msg) {
      if (!mounted) return;
      if (msg.senderType != 'admin') return;
      final currentLocation = GoRouterState.of(context).uri.toString();
      if (currentLocation.contains('ai-chat')) return;
      if ((msg.id ?? 0) <= sl<LocalStorage>().lastSeenMessageId) return;
      if (!_hasUnreadMessages) {
        setState(() => _hasUnreadMessages = true);
      }
    };
    socket.onMessageReceived(_chatListener);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _balanceTimer?.cancel();
    _loginPromptTimer?.cancel();
    ChatSocketService().removeMessageListener(_chatListener);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startBalanceTimer();
      // Re-arms the low-payment gate after the user comes back from the SMS
      // app, and closes it if a COMPLETED push landed while we were away.
      unawaited(checkPendingLowPaymentGate());
    } else if (state == AppLifecycleState.paused) {
      _balanceTimer?.cancel();
    }
  }

  void _startBalanceTimer() {
    _balanceTimer?.cancel();
    _balanceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && sl<LocalStorage>().token?.isNotEmpty == true) {
        context.read<BalanceBloc>().add(const BalanceFetchRequested());
      }
    });
  }

  void _startLoginPromptTimer() {
    _loginPromptTimer?.cancel();
    _loginPromptTimer = Timer(const Duration(seconds: 45), () async {
      if (!mounted) return;
      final token = sl<LocalStorage>().token;
      if (token != null && token.isNotEmpty) return;
      final currentLocation = GoRouterState.of(context).uri.toString();
      if (currentLocation.contains('login') ||
          currentLocation.contains('otp')) {
        return;
      }
      unawaited(
        DialogUtils.showLoginDialog(
          context: context,
          title: 'loginError',
          agreeButton: 'login',
          subtitle: 'loginSubtitle',
          image: IconConstants.loginLottie,
          onRetry: () {
            Navigator.of(context).pop();
            context.push(AppRoutes.login);
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      );
    });
  }

  Future<void> _maybeShowUpgradeDialog() async {
    if (!Upgrader().shouldDisplayUpgrade()) return;
    final languageCode = AppTranslations.currentLocale;
    UpgraderMessages? messages;
    if (languageCode == 'tk') {
      messages = UpgraderMessagesTR();
    } else if (languageCode == 'ru') {
      messages = UpgraderMessagesRU();
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpgradeAlert(
        upgrader: Upgrader(messages: messages, debugDisplayAlways: true),
        showIgnore: false,
        dialogStyle: Platform.isAndroid
            ? UpgradeDialogStyle.material
            : UpgradeDialogStyle.cupertino,
      ),
    );
  }

  Future<void> _maybeShowTutorial() async {
    if (sl<LocalStorage>().tutorialSeen) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _fabKey.currentContext == null) return;
    _buildTutorialTargets();
    TutorialCoachMark(
      targets: _tutorialTargets,
      colorShadow: Colors.black,
      textSkip: 'skip'.tr,
      onSkip: () => true,
    ).show(context: context);
    await sl<LocalStorage>().setTutorialSeen();
  }

  void _buildTutorialTargets() {
    _tutorialTargets = [
      TargetFocus(
        identify: 'fab',
        keyTarget: _fabKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tutorialTitle'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'tutorialDescription'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _maybeAskNotificationPermission() async {
    final storage = sl<LocalStorage>();
    if (storage.notificationPermissionRequested) return;
    final status = await Permission.notification.status;
    if (status.isGranted) {
      await storage.setNotificationPermissionRequested();
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 15));
    if (!mounted) return;
    unawaited(
      DialogUtils.showLoginDialog(
        context: context,
        title: 'notificationTitle',
        agreeButton: 'giveAccess',
        subtitle: 'notificationSubtitle',
        image: IconConstants.loginLottie,
        onCancel: () async {
          await storage.setNotificationPermissionRequested();
          if (mounted) Navigator.of(context).pop();
        },
        onRetry: () async {
          await storage.setNotificationPermissionRequested();
          if (mounted) Navigator.of(context).pop();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          final newStatus = await Permission.notification.request();
          if (newStatus.isPermanentlyDenied || newStatus.isDenied) {
            await openAppSettings();
          }
        },
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/favorites')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  static const List<String> _tabPaths = [
    AppRoutes.home,
    AppRoutes.favorites,
    AppRoutes.cart,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    final languageCode = AppTranslations.currentLocale;
    UpgraderMessages? messages;
    if (languageCode == 'tk') {
      messages = UpgraderMessagesTR();
    } else if (languageCode == 'ru') {
      messages = UpgraderMessagesRU();
    }

    return UpgradeAlert(
      upgrader: Upgrader(messages: messages),
      dialogStyle: Platform.isAndroid
          ? UpgradeDialogStyle.material
          : UpgradeDialogStyle.cupertino,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(AppRoutes.login);
          }
        },
        child: SafeArea(
          top: false,
          bottom: false,
          child: Scaffold(
            appBar: currentIndex == 1
                ? null
                : CustomAppBar(
                    title: ListConstants.pageNames[currentIndex],
                    showBackButton: false,
                    showWallet: true,
                    leadingButton: GestureDetector(
                      onTap: () async {
                        final token = sl<LocalStorage>().token;
                        if (token == null || token.isEmpty) {
                          unawaited(context.push(AppRoutes.login));
                          return;
                        }
                        if (_hasUnreadMessages) {
                          setState(() => _hasUnreadMessages = false);
                        }
                        await context.push(AppRoutes.aiChat);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AppIcon(
                                IconlyLight.message,
                                color: appBarForeground,
                              ),
                              if (_hasUnreadMessages)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'contact'.tr,
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
            // The downloads ribbon sits directly under the app bar (rather than
            // above it at the app root) so the in-progress banner reads as part
            // of the screen. It collapses to zero height when nothing is active.
            body: Column(
              children: [
                const DownloadsRibbon(),
                Expanded(child: widget.child),
              ],
            ),
            floatingActionButton: currentIndex == 2
                ? null
                : FloatingActionButton(
                    key: _fabKey,
                    tooltip: 'tutorialTitle'.tr,
                    onPressed: () => context.push(AppRoutes.instruction),
                    backgroundColor: ColorConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: context.border.highBorderRadius,
                    ),
                    child: AppIcon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
            bottomNavigationBar: CustomBottomNavBar(
              selectedIcons: ListConstants.selectedIcons,
              unselectedIcons: ListConstants.mainIcons,
              currentIndex: currentIndex,
              labels: ListConstants.pageNames,
              onTap: (index) {
                print('Tapped index: $index');
                context.go(_tabPaths[index]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
