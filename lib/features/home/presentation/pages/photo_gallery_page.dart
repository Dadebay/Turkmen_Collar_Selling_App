import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/no_image.dart';

/// Shows the list of images of a single photo instruction as a carousel.
/// Tapping an image opens it full-screen in [AppRoutes.photoView].
class PhotoGalleryPage extends StatefulWidget {
  const PhotoGalleryPage({
    required this.images,
    this.title,
    this.initialIndex = 0,
    super.key,
  });

  final List<String> images;
  final String? title;
  final int initialIndex;

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  late int _dotIndex;

  @override
  void initState() {
    super.initState();
    _dotIndex = widget.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.images.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title ?? 'insPage',
        showBackButton: true,
      ),
      body: images.isEmpty
          ? const EmptyState(name: 'emptyData', type: EmptyStateType.lottie)
          : Column(
              children: [
                Expanded(
                  child: CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: images.length,
                    itemBuilder: (context, index, count) {
                      final url = images[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.photoView,
                            extra: {
                              'image': url,
                              'networkImage': true,
                              'shouldShowWaterMark': false,
                            },
                          ),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Loading(),
                            errorWidget: (context, url, error) =>
                                const NoImage(),
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      initialPage: _dotIndex,
                      onPageChanged: (index, _) =>
                          setState(() => _dotIndex = index),
                      height: double.infinity,
                      viewportFraction: 0.8,
                      enableInfiniteScroll: images.length > 1,
                      scrollPhysics: const BouncingScrollPhysics(),
                    ),
                  ),
                ),
                if (images.length > 1) ...[
                  _dots(images.length),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }

  SizedBox _dots(int length) {
    return SizedBox(
      height: 16,
      width: MediaQuery.sizeOf(context).width,
      child: Center(
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _carouselController.animateToPage(index),
            child: _dot(index),
          ),
        ),
      ),
    );
  }

  AnimatedContainer _dot(int index) {
    return AnimatedContainer(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        color: _dotIndex == index
            ? ColorConstants.primaryColor
            : AppPalette.of(context).muted.withOpacity(0.5),
        // borderRadius: BorderRadius.circular(2),
        shape: BoxShape.circle,
      ),
    );
  }
}
