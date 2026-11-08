import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/app_palette.dart';

class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key, this.canSkip = false});

  final bool canSkip;

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToStore() async {
    final marketUri = Uri.parse(StringConstants.playStoreMarketLink);
    final webUri = Uri.parse(StringConstants.appShareLink);

    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final logoCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    final titleCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
    );
    final buttonCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.85, curve: Curves.easeOutCubic),
    );
    final skipCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorConstants.primaryColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.primaryColor.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.primaryColor.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: logoCurve,
                      builder: (context, _) {
                        return Opacity(
                          opacity: logoCurve.value,
                          child: Transform.scale(
                            scale: 0.5 + (logoCurve.value * 0.5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                IconConstants.logo,
                                width: 120,
                                height: 120,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: titleCurve,
                      builder: (context, _) {
                        return Opacity(
                          opacity: titleCurve.value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - titleCurve.value) * 20),
                            child: Column(
                              children: [
                                Text(
                                  'forceUpdateTitle'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.of(context).text,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'forceUpdateSubtitle'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppPalette.of(context).text
                                        .withOpacity(0.85),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    AnimatedBuilder(
                      animation: buttonCurve,
                      builder: (context, _) {
                        return Opacity(
                          opacity: buttonCurve.value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - buttonCurve.value) * 20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _goToStore,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.of(context)
                                      .surface,
                                  foregroundColor: ColorConstants.primaryColor,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'yesUpdate'.tr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (widget.canSkip)
                      AnimatedBuilder(
                        animation: skipCurve,
                        builder: (context, _) {
                          return Opacity(
                            opacity: skipCurve.value,
                            child: TextButton(
                              onPressed: () => context.go(AppRoutes.home),
                              child: Text(
                                'noUpdate'.tr,
                                style: TextStyle(
                                  color: AppPalette.of(context).text
                                      .withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
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
