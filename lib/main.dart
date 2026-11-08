import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_themes.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/theme/theme_reveal.dart';
import 'core/init/app_start_init.dart';
import 'core/l10n/app_translations.dart';
import 'core/router/app_router.dart';
import 'core/router/go_router_extensions.dart';
import 'core/services/android_system_ui.dart';
import 'core/services/error_report_screenshot.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/color_constants.dart';
import 'core/theme/app_palette.dart';
import 'core/utils/dialog_utils.dart';
import 'core/widgets/custom_widgets.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/downloads/domain/entities/download_manager_item.dart';
import 'features/downloads/presentation/bloc/download_manager_bloc.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';
import 'features/home/presentation/bloc/balance/balance_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/payment/presentation/bloc/payment_status_bloc.dart';
import 'global_safe_area_wrapper.dart';
import 'injection_container.dart';

Future<void> main() async {
  await AppStartInit.init();
  // Apply stored locale before app renders
  AppTranslations.setLocale(LocalStorage().locale);
  AppThemeController.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final _router = buildRouter();
  Timer? _restoreNavigationBarTimer;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(AndroidSystemUi.showNavigationBar());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AndroidSystemUi.showNavigationBar());
    }
  }

  @override
  void didChangeMetrics() {
    final keyboardVisible = WidgetsBinding.instance.platformDispatcher.views
        .any((view) => view.viewInsets.bottom > 0);
    if (_keyboardVisible && !keyboardVisible) {
      _restoreNavigationBarTimer?.cancel();
      _restoreNavigationBarTimer = Timer(
        const Duration(milliseconds: 120),
        () => unawaited(AndroidSystemUi.showNavigationBar()),
      );
    } else if (keyboardVisible) {
      _restoreNavigationBarTimer?.cancel();
    }
    _keyboardVisible = keyboardVisible;
  }

  @override
  void dispose() {
    _restoreNavigationBarTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: ErrorReportScreenshot.boundaryKey,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
          BlocProvider<HomeBloc>(create: (_) => sl<HomeBloc>()),
          BlocProvider<BalanceBloc>(create: (_) => sl<BalanceBloc>()),
          BlocProvider<CartBloc>(create: (_) => sl<CartBloc>()),
          BlocProvider<FavoritesBloc>(create: (_) => sl<FavoritesBloc>()),
          BlocProvider<DownloadManagerBloc>(
            create: (_) =>
                sl<DownloadManagerBloc>()
                  ..add(const DownloadManagerLoadRequested()),
          ),
          BlocProvider<PaymentStatusBloc>(
            create: (_) =>
                sl<PaymentStatusBloc>()
                  ..add(const PaymentStatusFetchRequested()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          // Load the user's favorites into the global FavoritesBloc as soon as
          // they are authenticated (startup token check or fresh OTP login), so
          // toggling a favorite from anywhere (cards, product detail) works even
          // if the Favorites tab was never opened.
          listenWhen: (previous, current) =>
              current is AuthAuthenticated ||
              current is AuthOptionalUpdate ||
              current is AuthOtpVerified,
          listener: (context, state) {
            context.read<FavoritesBloc>().add(const FavoritesLoadRequested());
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              AppThemeController.mode,
              AppTranslations.localeNotifier,
            ]),
            builder: (context, _) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Yaka',
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: AppThemeController.mode.value,
                themeAnimationDuration: Duration.zero,
                routerConfig: _router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.noScaling),
                  child: ThemeReveal(
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: GlobalSafeAreaWrapper(
                        top: false,
                        bottom: true,
                        child: _DownloadCompletionListener(
                          // Show "added / removed from favorites" feedback for a
                          // toggle from anywhere (cards, product detail). Lives inside
                          // the MaterialApp subtree so a ScaffoldMessenger exists.
                          child: BlocListener<FavoritesBloc, FavoritesState>(
                            listenWhen: (previous, current) =>
                                current is FavoritesLoaded &&
                                current.lastToggle != null,
                            listener: _showFavoriteToggleFeedback,
                            child: child!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Shows a snackbar for the most recent favorite toggle. Driven off
/// [FavoritesLoaded.lastToggle], so it reports both success (added / removed)
/// and failure, and works no matter where the heart button was tapped.
void _showFavoriteToggleFeedback(BuildContext context, FavoritesState state) {
  if (state is! FavoritesLoaded) {
    return;
  }
  switch (state.lastToggle) {
    case FavoritesToggleResult.added:
      showSnackBar(
        context,
        'favoriteAddedTitle',
        'favoriteAddedSubtitle',
        ColorConstants.greenColor,
      );
    case FavoritesToggleResult.removed:
      showSnackBar(
        context,
        'favoriteRemovedTitle',
        'favoriteRemovedSubtitle',
        ColorConstants.primaryColor,
      );
    case FavoritesToggleResult.addFailed:
      showSnackBar(
        context,
        'operationFailed',
        'favoriteAddFailed',
        ColorConstants.redColor,
      );
    case FavoritesToggleResult.removeFailed:
      showSnackBar(
        context,
        'operationFailed',
        'favoriteRemoveFailed',
        ColorConstants.redColor,
      );
    case null:
      break;
  }
}

/// Watches the global [DownloadManagerBloc] and, while the user is on the
/// Download-Yaka page, mirrors the old GetX flow: a modal progress dialog while
/// a download is running, then a success dialog on completion (a failure
/// snackbar is shown regardless of the current page). Centralising both dialogs
/// here — instead of in a per-page listener — keeps the close-then-succeed
/// ordering deterministic, so we never pop the success dialog by mistake.
class _DownloadCompletionListener extends StatefulWidget {
  const _DownloadCompletionListener({required this.child});
  final Widget child;

  @override
  State<_DownloadCompletionListener> createState() =>
      _DownloadCompletionListenerState();
}

class _DownloadCompletionListenerState
    extends State<_DownloadCompletionListener> {
  Set<String> _previousActive = const {};
  bool _progressDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadManagerBloc, DownloadManagerState>(
      listener: (context, state) {
        final currentActive = state.active.keys.toSet();
        final started = currentActive.difference(_previousActive);
        final finished = _previousActive.difference(currentActive);
        _previousActive = currentActive;

        // A download just began: show the modal progress dialog (only while the
        // user is on the Download-Yaka page, where they kicked it off).
        if (started.isNotEmpty &&
            !_progressDialogOpen &&
            _onDownloadYakaPage()) {
          _showProgressDialog();
        }

        // Every download has left the active set: close the progress dialog
        // first, so the success dialog below is pushed onto a clean stack.
        if (currentActive.isEmpty && _progressDialogOpen) {
          _closeProgressDialog();
        }

        for (final key in finished) {
          DownloadManagerItem? item;
          for (final candidate in state.allItems) {
            if (candidate.storageKey == key) {
              item = candidate;
              break;
            }
          }
          if (item == null) {
            continue;
          }
          if (item.status == DownloadManagerStatus.downloaded) {
            // The success dialog is only relevant while the user is on the
            // Download-Yaka page. On any other screen it would be intrusive.
            final navigatorContext = rootNavigatorKey.currentContext;
            if (navigatorContext != null && _onDownloadYakaPage()) {
              DialogUtils.showDownloadSuccessDialog(context: navigatorContext);
            }
          } else if (item.status == DownloadManagerStatus.failed) {
            showSnackBar(
              context,
              'downloadFailedTitle',
              item.errorMessage.isNotEmpty
                  ? item.errorMessage
                  : 'downloadFailedSubtitle',
              ColorConstants.redColor,
            );
          }
        }
      },
      child: widget.child,
    );
  }

  /// True when the Download-Yaka page (`/download-yaka/:id`) is the current
  /// route. Reads [GoRouterLocation.location] (not `currentConfiguration.uri`
  /// directly): the page is reached via `context.push`, so the raw match list
  /// still reports the base location (e.g. `/home`) — the extension unwraps the
  /// imperative match to give the route actually on screen.
  bool _onDownloadYakaPage() {
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      return false;
    }
    return GoRouter.of(navigatorContext).location.contains('download-yaka');
  }

  void _showProgressDialog() {
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }
    _progressDialogOpen = true;
    showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (_) => const _DownloadProgressDialog(),
    ).whenComplete(() => _progressDialogOpen = false);
  }

  void _closeProgressDialog() {
    _progressDialogOpen = false;
    // The progress dialog is a modal barrier, so it is always the top route.
    rootNavigatorKey.currentState?.pop();
  }
}

/// Modal "downloading…" dialog shown while a collar download runs. Rebuilds on
/// [DownloadManagerBloc] progress so the percentage tracks live, mirroring the
/// old GetX `downloadDialog`.
class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.of(context).surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppPalette.of(context).muted.withOpacity(.25),
              spreadRadius: 3,
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
              const SizedBox(height: 25),
              BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
                builder: (context, state) {
                  final active = state.active.values;
                  final progress = active.isEmpty ? 0.0 : active.first.progress;
                  final percent = (progress * 100).clamp(0, 100).round();
                  return Text(
                    '${'downloadedYakalar'.tr}$percent/100',
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    style: Theme.of(context).textTheme.titleLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
