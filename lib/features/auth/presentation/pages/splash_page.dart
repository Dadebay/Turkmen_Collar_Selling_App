import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/constants/list_constants.dart';
import '../../../../core/constants/widget_sizes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(
      AuthCheckRequested(
        platform: Platform.isAndroid ? 'android' : 'ios',
        version: ListConstants.appVersion.split('+').first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthAuthenticated():
            context.go(AppRoutes.home);
          case AuthOptionalUpdate():
            context.go(AppRoutes.home);
            // Show optional update dialog after navigation
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                DialogUtils.showCustomUpdateDialog(
                  context: context,
                  releaseNotes: '',
                  currentVersion: ListConstants.appVersion.split('+').first,
                  newVersion: '',
                  onUpdate: () {},
                  onLater: () => context.pop(),
                );
              }
            });
          case AuthUnauthenticated():
            context.go(AppRoutes.home);
          case AuthForceUpdate():
            context.go(AppRoutes.forceUpdate);
          case AuthError():
            // Version-check or auth call failed (usually no network). Land the
            // user on home so they can still browse cached content instead of
            // staring at the splash spinner forever.
            context.go(AppRoutes.home);
          case _:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: context.border.highBorderRadius,
                  child: Image.asset(
                    IconConstants.logo,
                    width: WidgetSizes.size180.value,
                    height: WidgetSizes.size180.value,
                  ),
                ),
              ),
            ),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
