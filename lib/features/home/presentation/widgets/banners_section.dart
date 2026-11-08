import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/cards_loading.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/no_image.dart';
import '../../domain/entities/banner_entity.dart';
import '../bloc/home_bloc.dart';

class BannersSection extends StatefulWidget {
  const BannersSection({super.key});

  @override
  State<BannersSection> createState() => _BannersSectionState();
}

class _BannersSectionState extends State<BannersSection> {
  int _dotIndex = 0;
  double _dragDistance = 0;
  bool _dragging = false;
  Timer? _autoPlayTimer;
  String? _preloadedImage;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted ||
          _dragging ||
          !TickerMode.of(context) ||
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)) {
        return;
      }
      final state = context.read<HomeBloc>().state;
      if (state is HomeLoaded && state.banners.length > 1) {
        _showBanner(1, state.banners.length);
      }
    });
  }

  void _showBanner(int direction, int count) {
    if (count > 1) {
      setState(() => _dotIndex = (_dotIndex + direction + count) % count);
    }
  }

  void _preloadNextBanner(List<BannerEntity> banners, int selectedIndex) {
    if (banners.length < 2) {
      return;
    }
    final image = banners[(selectedIndex + 1) % banners.length].image ?? '';
    if (image.isEmpty || image == _preloadedImage) {
      return;
    }
    _preloadedImage = image;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        precacheImage(
          CachedNetworkImageProvider(image),
          context,
          onError: (_, __) {},
        ),
      );
    });
  }

  static Widget _slideFadeTransition(
    Widget child,
    Animation<double> animation,
  ) => DualTransitionBuilder(
    animation: animation,
    forwardBuilder: (context, enter, child) => child ?? const SizedBox.shrink(),
    reverseBuilder: (context, exit, child) => FadeTransition(
      opacity: exit
          .drive(CurveTween(curve: const Interval(0.2, 0.8)))
          .drive(Tween<double>(begin: 1, end: 0)),
      child: SlideTransition(
        position: exit
            .drive(CurveTween(curve: Curves.easeInOutCubic))
            .drive(Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))),
        child: child,
      ),
    ),
    child: child,
  );

  static Widget _fadeTransition(Widget child, Animation<double> animation) =>
      FadeTransition(opacity: animation, child: child);

  static Widget _bannerLayout(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) => Stack(
    alignment: Alignment.center,
    children: [if (currentChild != null) currentChild, ...previousChildren],
  );

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const CardsLoading(loaderType: LoaderType.banner);
        }
        if (state is! HomeLoaded || state.banners.isEmpty) {
          return const SizedBox.shrink();
        }
        final banners = state.banners;
        final selectedIndex = _dotIndex % banners.length;
        _preloadNextBanner(banners, selectedIndex);
        final reduceMotion =
            MediaQuery.disableAnimationsOf(context) ||
            MediaQuery.accessibleNavigationOf(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onHorizontalDragStart: (_) {
                _dragging = true;
                _dragDistance = 0;
              },
              onHorizontalDragUpdate: (details) =>
                  _dragDistance += details.delta.dx,
              onHorizontalDragCancel: () => _dragging = false,
              onHorizontalDragEnd: (details) {
                _dragging = false;
                final velocity = details.primaryVelocity ?? 0;
                final distance = _dragDistance;
                if (distance.abs() > 30 || velocity.abs() > 200) {
                  final movement = velocity.abs() > 200 ? velocity : distance;
                  _showBanner(movement < 0 ? 1 : -1, banners.length);
                  _startAutoPlay();
                }
              },
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height / 4,
                width: double.infinity,
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: reduceMotion ? 150 : 450),
                    switchInCurve: Curves.linear,
                    switchOutCurve: Curves.linear,
                    transitionBuilder: reduceMotion
                        ? _fadeTransition
                        : _slideFadeTransition,
                    layoutBuilder: _bannerLayout,
                    child: _BannerCard(
                      key: ValueKey(
                        'banner-$selectedIndex-${banners[selectedIndex].id}-${banners[selectedIndex].image}',
                      ),
                      banner: banners[selectedIndex],
                    ),
                  ),
                ),
              ),
            ),
            _dots(banners.length, selectedIndex),
          ],
        );
      },
    );
  }

  Widget _dots(int length, int selectedIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 4,
        width: MediaQuery.sizeOf(context).width,
        child: Center(
          child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: length,
            itemBuilder: (context, index) => _dot(index, selectedIndex),
          ),
        ),
      ),
    );
  }

  AnimatedContainer _dot(int index, int selectedIndex) {
    return AnimatedContainer(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      duration: const Duration(milliseconds: 250),
      curve: Curves.decelerate,
      height: 4,
      width: 18,
      decoration: BoxDecoration(
        color: selectedIndex == index
            ? ColorConstants.primaryColor
            : AppPalette.of(context).muted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, super.key});
  final BannerEntity banner;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.bannerDetail,
        extra: <String, String>{
          'pageName': banner.title ?? '',
          'image': banner.image ?? '',
          'description': banner.description ?? '',
        },
      ),
      child: SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: banner.image ?? '',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          fadeInDuration: Duration.zero,
          placeholder: (context, url) => const Loading(),
          errorWidget: (context, url, error) => const NoImage(),
        ),
      ),
    );
  }
}
