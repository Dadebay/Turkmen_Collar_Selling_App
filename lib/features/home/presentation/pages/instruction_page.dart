import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/icons/app_icon.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/video_cache_manager.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../features/payment/presentation/bloc/payment_status_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/home_repository.dart';

class InstructionPage extends StatefulWidget {
  const InstructionPage({super.key, this.initialTab = 0});

  /// 0 = video tab, 1 = image tab.
  final int initialTab;

  @override
  State<InstructionPage> createState() => _InstructionPageState();
}

class _InstructionPageState extends State<InstructionPage>
    with SingleTickerProviderStateMixin {
  late Future<Result<List<VideoEntity>>> _videosFuture;
  late Future<Result<List<PhotoEntity>>> _photosFuture;
  late final TabController _tabController;
  late int _activeTab;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _activeTab,
    )..addListener(_onTabChanged);
    _videosFuture = sl<HomeRepository>().getVideos();
    _photosFuture = sl<HomeRepository>().getPhotos();
  }

  void _onTabChanged() {
    if (_activeTab != _tabController.index) {
      setState(() => _activeTab = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _videosFuture = sl<HomeRepository>().getVideos();
    });
  }

  void _retryPhotos() {
    setState(() {
      _photosFuture = sl<HomeRepository>().getPhotos();
    });
  }

  bool _onGridScroll(
    ScrollNotification notification, {
    required bool paymentsDisabled,
  }) {
    if (!paymentsDisabled && _activeTab == 1) {
      return false;
    }
    if (notification.metrics.axis != Axis.vertical ||
        notification is! ScrollUpdateNotification) {
      return false;
    }

    final delta = notification.scrollDelta ?? 0;
    if (_showIntro && delta > 0 && notification.metrics.pixels > 8) {
      setState(() => _showIntro = false);
    } else if (!_showIntro &&
        delta < 0 &&
        notification.metrics.pixels <= 0 &&
        (notification.dragDetails != null ||
            notification.metrics.pixels < -4)) {
      setState(() => _showIntro = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentStatusBloc, PaymentStatusState>(
      builder: (context, paymentState) {
        final paymentsDisabled = paymentState.isDisabled;
        return Scaffold(
          backgroundColor: AppPalette.of(context).surfaceAlt,
          appBar: const CustomAppBar(title: 'insPage', showBackButton: true),
          body: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _showIntro && (paymentsDisabled || _activeTab == 0)
                    ? const _InstructionIntro()
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => _onGridScroll(
                    notification,
                    paymentsDisabled: paymentsDisabled,
                  ),
                  child: paymentsDisabled
                      ? _InstructionSection(
                          titleKey: 'instruction_video_heading',
                          child: _VideosTab(
                            future: _videosFuture,
                            onRetry: _retry,
                            limit: 1,
                          ),
                        )
                      : Column(
                          children: [
                            _InstructionTabs(controller: _tabController),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _VideosTab(
                                    future: _videosFuture,
                                    onRetry: _retry,
                                  ),
                                  _PhotosTab(
                                    future: _photosFuture,
                                    onRetry: _retryPhotos,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InstructionSection extends StatelessWidget {
  const _InstructionSection({required this.titleKey, required this.child});

  final String titleKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              titleKey.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _InstructionIntro extends StatelessWidget {
  const _InstructionIntro();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = ColorConstants.primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const AppIcon(
                Icons.play_circle_outline,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'instruction_intro_title'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'instruction_intro_subtitle'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionTabs extends StatelessWidget {
  const _InstructionTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: ColorConstants.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: palette.muted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIcon(IconlyLight.play, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'instruction_video_heading'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIcon(IconlyLight.image, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'instruction_photo_heading'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.future, required this.onRetry, this.limit});
  final Future<Result<List<VideoEntity>>> future;
  final VoidCallback onRetry;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<VideoEntity>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Loading();
        }
        if (!snapshot.hasData) {
          return _InstructionMessage(
            icon: Icons.error_outline,
            title: 'noConnection1'.tr,
            subtitle: 'noConnection2'.tr,
            onRetry: onRetry,
          );
        }
        return snapshot.data!.when(
          success: (videos) {
            final list = limit != null ? videos.take(limit!).toList() : videos;
            if (list.isEmpty) {
              return _InstructionMessage(
                icon: Icons.inbox_outlined,
                title: 'instruction_empty'.tr,
              );
            }
            return _InstructionGrid(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final video = list[index];
                final title = video.name?.isNotEmpty == true
                    ? video.name!
                    : video.slug ?? 'videoTitle${index + 1}';
                final url = _instructionMediaUrl(video.videoUrl) ?? '';
                final cacheKey = video.slug ?? video.id?.toString() ?? url;
                return _InstructionCard(
                  index: index + 1,
                  title: title.tr,
                  thumbnailUrl: _instructionMediaUrl(video.pictureUrl),
                  videoUrl: url,
                  videoCacheKey: cacheKey,
                  icon: Icons.videocam_outlined,
                  isVideo: true,
                  onTap: url.isEmpty
                      ? null
                      : () => context.push(
                          AppRoutes.videoPlayer,
                          extra: {
                            'videoPath': url,
                            'appBarTitle': title,
                            'cacheKey': cacheKey,
                          },
                        ),
                );
              },
            );
          },
          failure: (_) => _InstructionMessage(
            icon: Icons.error_outline,
            title: 'noConnection1'.tr,
            subtitle: 'noConnection2'.tr,
            onRetry: onRetry,
          ),
        );
      },
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({required this.future, required this.onRetry});
  final Future<Result<List<PhotoEntity>>> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<PhotoEntity>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Loading();
        }
        if (!snapshot.hasData) {
          return _InstructionMessage(
            icon: Icons.error_outline,
            title: 'noConnection1'.tr,
            subtitle: 'noConnection2'.tr,
            onRetry: onRetry,
          );
        }
        return snapshot.data!.when(
          success: (photos) {
            if (photos.isEmpty) {
              return _InstructionMessage(
                icon: Icons.inbox_outlined,
                title: 'instruction_empty'.tr,
              );
            }
            return _PhotoInstructionList(photos: photos);
          },
          failure: (_) => _InstructionMessage(
            icon: Icons.error_outline,
            title: 'noConnection1'.tr,
            subtitle: 'noConnection2'.tr,
            onRetry: onRetry,
          ),
        );
      },
    );
  }
}

class _PhotoInstructionList extends StatefulWidget {
  const _PhotoInstructionList({required this.photos});

  final List<PhotoEntity> photos;

  @override
  State<_PhotoInstructionList> createState() => _PhotoInstructionListState();
}

class _PhotoInstructionListState extends State<_PhotoInstructionList> {
  final ScrollController _controller = ScrollController();
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateScrollHint);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final show = position.maxScrollExtent > 24 && position.pixels < 24;
    if (show != _showScrollHint && mounted) {
      setState(() => _showScrollHint = show);
    }
  }

  void _scrollToMore() {
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final target = (position.pixels + position.viewportDimension * 0.75)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());

    return Stack(
      children: [
        Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          thickness: 3,
          radius: const Radius.circular(3),
          child: ListView.builder(
            key: const ValueKey('instruction-photo-list'),
            controller: _controller,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 76),
            physics: const BouncingScrollPhysics(),
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              final title = photo.title?.isNotEmpty == true
                  ? photo.title!
                  : 'photoTitle${index + 1}';
              final images = photo.images
                  .map(_instructionMediaUrl)
                  .whereType<String>()
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PhotoInstructionCarousel(
                  index: index + 1,
                  title: title.tr,
                  images: images,
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 12,
          child: _InstructionScrollHint(
            visible: _showScrollHint,
            onTap: _scrollToMore,
          ),
        ),
      ],
    );
  }
}

class _PhotoInstructionCarousel extends StatefulWidget {
  const _PhotoInstructionCarousel({
    required this.index,
    required this.title,
    required this.images,
  });

  final int index;
  final String title;
  final List<String> images;

  @override
  State<_PhotoInstructionCarousel> createState() =>
      _PhotoInstructionCarouselState();
}

class _PhotoInstructionCarouselState extends State<_PhotoInstructionCarousel> {
  late final PageController _controller;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.93);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final images = widget.images;

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    widget.index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: ColorConstants.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.4,
            child: images.isEmpty
                ? Center(child: Text('noImage'.tr))
                : PageView.builder(
                    key: ValueKey('instruction-photo-carousel-${widget.index}'),
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (index) =>
                        setState(() => _imageIndex = index),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Material(
                          color: palette.surfaceAlt,
                          child: InkWell(
                            onTap: () => context.push(
                              AppRoutes.photoGallery,
                              extra: {
                                'images': images,
                                'title': widget.title,
                                'initialIndex': index,
                              },
                            ),
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Center(
                                child: AppIcon(
                                  IconlyLight.image,
                                  size: 30,
                                  color: palette.muted,
                                ),
                              ),
                              errorWidget: (_, __, ___) =>
                                  Center(child: Text('noImage'.tr)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (images.length > 1 && images.length <= 8) ...[
                    for (var index = 0; index < images.length; index++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == _imageIndex ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == _imageIndex
                              ? ColorConstants.primaryColor
                              : palette.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${_imageIndex + 1} / ${images.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InstructionGrid extends StatefulWidget {
  const _InstructionGrid({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  State<_InstructionGrid> createState() => _InstructionGridState();
}

class _InstructionGridState extends State<_InstructionGrid> {
  final ScrollController _controller = ScrollController();
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateScrollHint);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final show = position.maxScrollExtent > 24 && position.pixels < 24;
    if (show != _showScrollHint && mounted) {
      setState(() => _showScrollHint = show);
    }
  }

  void _scrollToMore() {
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final target = (position.pixels + position.viewportDimension * 0.75)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());

    return Stack(
      children: [
        Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          thickness: 3,
          radius: const Radius.circular(3),
          child: GridView.builder(
            controller: _controller,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 76),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 184,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: widget.itemCount,
            itemBuilder: widget.itemBuilder,
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 12,
          child: _InstructionScrollHint(
            visible: _showScrollHint,
            onTap: _scrollToMore,
          ),
        ),
      ],
    );
  }
}

class _InstructionScrollHint extends StatelessWidget {
  const _InstructionScrollHint({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: Center(
          child: Material(
            color: palette.text,
            elevation: 5,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'instruction_scroll_hint'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: palette.surface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppIcon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: palette.surface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.onTap,
    this.thumbnailUrl,
    this.videoUrl,
    this.videoCacheKey,
    this.isVideo = false,
  });

  final int index;
  final String title;
  final Object icon;
  final VoidCallback? onTap;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? videoCacheKey;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _InstructionThumbnail(
                  index: index,
                  imageUrl: thumbnailUrl,
                  videoUrl: videoUrl,
                  videoCacheKey: videoCacheKey,
                  icon: icon,
                  showPlay: isVideo,
                ),
                if (onTap != null && !isVideo)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        IconlyLight.arrowRightCircle,
                        size: 21,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.text,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
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

class _InstructionThumbnail extends StatelessWidget {
  const _InstructionThumbnail({
    required this.index,
    required this.imageUrl,
    required this.videoUrl,
    required this.videoCacheKey,
    required this.icon,
    required this.showPlay,
  });

  final int index;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoCacheKey;
  final Object icon;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    final accent = ColorConstants.primaryColor;
    final hasImage = imageUrl?.isNotEmpty == true;
    final fallback = ColoredBox(
      color: accent.withValues(alpha: 0.11),
      child: Center(child: AppIcon(icon, size: 32, color: accent)),
    );
    final imageFallback = hasImage
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          )
        : fallback;
    final preview = showPlay && videoUrl?.isNotEmpty == true
        ? _VideoFramePreview(
            videoUrl: videoUrl!,
            cacheKey: videoCacheKey ?? videoUrl!,
            fallback: imageFallback,
          )
        : imageFallback;

    return SizedBox(
      height: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          preview,
          if (showPlay)
            Center(
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  IconlyLight.play,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            top: 7,
            left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _instructionMediaUrl(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(path);
  if (uri == null) {
    return null;
  }
  if (uri.hasScheme) {
    return path;
  }
  if (path.startsWith('//')) {
    return 'https:$path';
  }
  final relative = path.startsWith('/') ? path : '/$path';
  return Uri.parse(ApiConstants.baseUrl).resolve(relative).toString();
}

class _VideoFramePreview extends StatelessWidget {
  const _VideoFramePreview({
    required this.videoUrl,
    required this.cacheKey,
    required this.fallback,
  });

  final String videoUrl;
  final String cacheKey;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _VideoFrameCache.get(videoUrl, cacheKey),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return fallback;
        }
        return Image.memory(
          bytes,
          key: ValueKey('instruction-video-preview-$videoUrl'),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }
}

class _VideoFrameCache {
  static final Map<String, Future<Uint8List?>> _frames = {};

  static Future<Uint8List?> get(String url, String cacheKey) {
    final cached = _frames[cacheKey];
    if (cached != null) {
      return cached;
    }

    final preview = _generate(url, cacheKey);
    _frames[cacheKey] = preview;
    preview.then((bytes) {
      if ((bytes == null || bytes.isEmpty) &&
          identical(_frames[cacheKey], preview)) {
        _frames.remove(cacheKey);
      }
    });
    return preview;
  }

  static Future<Uint8List?> _generate(String url, String cacheKey) async {
    try {
      final cached = await VideoCacheManager.instance.getFileFromCache(
        cacheKey,
      );
      final file = cached != null && cached.file.existsSync()
          ? cached.file
          : await VideoCacheManager.instance.getSingleFile(url, key: cacheKey);
      return await VideoThumbnailPlus.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 360,
        timeMs: 1000,
        quality: 72,
      );
    } catch (error) {
      debugPrint('[VideoPreview] $cacheKey: $error');
      return null;
    }
  }
}

class _InstructionMessage extends StatelessWidget {
  const _InstructionMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  final Object icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      icon,
                      color: ColorConstants.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle case final details?) ...[
                    const SizedBox(height: 6),
                    Text(
                      details,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.muted),
                    ),
                  ],
                  if (onRetry case final retry?) ...[
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: retry,
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                      ),
                      child: Text('noConnection3'.tr),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
