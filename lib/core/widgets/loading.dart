import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import 'package:shimmer/shimmer.dart';

import '../constants/string_constants.dart';
import '../theme/color_constants.dart';
import '../icons/app_icon.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: AppPalette.of(context).muted,
        highlightColor: AppPalette.of(context).surface,
        child: Text(
          StringConstants.appName.toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 2),
        ),
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = AppPalette.of(context).muted.withOpacity(.2);
    final highlight = AppPalette.of(context).muted.withOpacity(.1);
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: screenHeight / 4.2,
                decoration: BoxDecoration(
                  color: AppPalette.of(context).surface,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 22,
                width: 140,
                color: AppPalette.of(context).surface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 6,
                itemBuilder: (_, __) => Container(
                  width: 68,
                  height: 68,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppPalette.of(context).surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 22,
                width: 160,
                color: AppPalette.of(context).surface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  width: 180,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.of(context).surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 80, color: AppPalette.of(context).muted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppPalette.of(context).muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onRetry,
                child: Text(retryLabel ?? 'noConnection3'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
