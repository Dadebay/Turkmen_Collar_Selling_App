import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';

import '../../../../core/constants/widget_sizes.dart';
import '../../../../core/icons/app_icon.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/buttons/add_cart_button.dart';
import '../../../../core/widgets/buttons/download_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_functions.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/no_image.dart';
import '../../../favorites/presentation/widgets/fav_button.dart';
import '../../../home/domain/entities/collar_entity.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../bloc/product_detail_bloc.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.productId,
    this.product,
    this.isCollar = false,
    super.key,
  });

  final int productId;
  final ProductEntity? product;
  final bool isCollar;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool get _isCollar => widget.product?.downloadable ?? widget.isCollar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<ProductDetailBloc>().add(
      ProductDetailLoadRequested(id: widget.productId, isCollar: _isCollar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialName = widget.product?.name ?? '';
    return Scaffold(
      bottomNavigationBar: widget.product == null
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppPalette.of(context).surface,
                border: Border(
                  top: BorderSide(color: AppPalette.of(context).border),
                ),
              ),
              child: SafeArea(
                top: false,
                child: _isCollar
                    ? DownloadButton(
                        productModel: widget.product!,
                        makeBigger: true,
                      )
                    : AddCartButton(
                        productModel: widget.product!,
                        productProfilDesign: true,
                      ),
              ),
            ),
      appBar: CustomAppBar(
        title: initialName,
        showBackButton: true,
        actionButton: widget.product == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FavButton(
                  changeBackColor: true,
                  name: widget.product!.name,
                  id: widget.product!.id,
                  isCollar: _isCollar,
                ),
              ),
      ),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailInitial || state is ProductDetailLoading) {
            return const Loading();
          }
          if (state is ProductDetailError) {
            return ErrorState(onTap: _load);
          }
          if (state is ProductDetailLoaded) {
            return _OrderPage(
              product: state.product,
              categoryName:
                  widget.product?.categoryName ?? state.product.categoryName,
              videoUrl: state.product.videoUrl,
            );
          }
          if (state is ProductDetailCollarLoaded) {
            return _DownloadablePage(collar: state.collar);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OrderPage extends StatelessWidget {
  const _OrderPage({
    required this.product,
    required this.categoryName,
    required this.videoUrl,
  });

  final ProductEntity product;
  final String categoryName;
  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _CarouselImages(
          images: product.images.isNotEmpty
              ? product.images
              : (product.image.isNotEmpty ? [product.image] : const []),
          videoUrl: videoUrl,
          productName: product.name,
        ),
        _TextPart(
          name: product.name,
          price: CustomFunctions.findPrice(product.price),
          machineName: '',
          barcode: product.barcode ?? '',
          category: categoryName,
          downloads: '',
          views: product.views ?? '',
          desc: product.description ?? '',
        ),
      ],
    );
  }
}

class _DownloadablePage extends StatelessWidget {
  const _DownloadablePage({required this.collar});
  final CollarEntity collar;

  @override
  Widget build(BuildContext context) {
    final images = collar.images.map((e) => e.toString()).toList();
    return ListView(
      children: [
        _CarouselImages(
          images: images,
          videoUrl: null,
          productName: collar.name ?? '',
        ),
        _TextPart(
          name: collar.name ?? '',
          price: CustomFunctions.findPrice((collar.price ?? 0).toString()),
          barcode: '',
          category: collar.tag ?? '',
          desc: collar.description ?? '',
          downloads: (collar.downloads ?? 0).toString(),
          machineName: collar.machineName ?? '',
          views: (collar.views ?? 0).toString(),
        ),
      ],
    );
  }
}

class _CarouselImages extends StatefulWidget {
  const _CarouselImages({
    required this.images,
    required this.videoUrl,
    required this.productName,
  });

  final List<String> images;
  final String? videoUrl;
  final String productName;

  @override
  State<_CarouselImages> createState() => _CarouselImagesState();
}

class _CarouselImagesState extends State<_CarouselImages> {
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant _CarouselImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.images, widget.images) ||
        oldWidget.videoUrl != widget.videoUrl) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.videoUrl?.isNotEmpty ?? false;
    final itemCount = widget.images.length + (hasVideo ? 1 : 0);
    final galleryHeight = (MediaQuery.sizeOf(context).width * .95)
        .clamp(280.0, 440.0)
        .toDouble();
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: galleryHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        child: Stack(
          children: [
            if (itemCount == 0)
              const Positioned.fill(child: NoImage())
            else
              CarouselSlider.builder(
                itemCount: itemCount,
                itemBuilder: (context, index, _) {
                  if (hasVideo && index == widget.images.length) {
                    return _videoPreview(context);
                  }
                  return GestureDetector(
                    onTap: () => context.push(
                      AppRoutes.photoView,
                      extra: {
                        'image': widget.images[index],
                        'networkImage': true,
                      },
                    ),
                    child: SizedBox.expand(
                      child: CustomWidgets.customImageView(
                        image: widget.images[index],
                        cover: true,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  viewportFraction: 1,
                  height: galleryHeight,
                  enableInfiniteScroll: itemCount > 1,
                  autoPlay: itemCount > 1,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration: const Duration(milliseconds: 450),
                  autoPlayCurve: Curves.easeInOutCubic,
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (index, _) =>
                      setState(() => _currentPage = index),
                ),
              ),
            if (itemCount > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.62),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1}/$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  Widget _videoPreview(BuildContext context) {
    final firstImage = widget.images.isNotEmpty ? widget.images[0] : '';
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.videoPlayer,
        extra: {
          'videoPath': widget.videoUrl,
          'appBarTitle': widget.productName,
        },
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: firstImage.isEmpty
                ? const NoImage()
                : CustomWidgets.customImageView(
                    image: firstImage,
                    cover: true,
                    borderRadius: BorderRadius.zero,
                  ),
          ),
          Positioned.fill(
            child: Container(
              color: AppPalette.of(context).muted.withOpacity(.3),
            ),
          ),
          Center(
            child: Container(
              padding: context.padding.normal,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.8),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                IconlyBold.play,
                color: ColorConstants.primaryColor,
                size: WidgetSizes.size64.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextPart extends StatelessWidget {
  const _TextPart({
    required this.name,
    required this.price,
    required this.machineName,
    required this.barcode,
    required this.category,
    required this.views,
    required this.downloads,
    required this.desc,
  });

  final String name;
  final String price;
  final String machineName;
  final String barcode;
  final String category;
  final String views;
  final String downloads;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final details =
        <MapEntry<String, String>>[
          MapEntry('data1', machineName),
          MapEntry('data2', category),
          MapEntry('data6', barcode),
          MapEntry('data3', views),
          MapEntry('data4', downloads),
        ].where((entry) {
          final value = entry.value.trim();
          return value.isNotEmpty && value.toLowerCase() != 'null';
        }).toList();
    final description = desc.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: context.general.textTheme.headlineSmall?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text: ' TMT',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ColorConstants.primaryColor),
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 22),
            _sectionCard(
              context: context,
              title: 'data'.tr,
              child: Column(
                children: [
                  for (var index = 0; index < details.length; index++) ...[
                    if (index > 0) Divider(height: 1, color: palette.border),
                    _infoRow(
                      context: context,
                      label: details[index].key.tr,
                      value: details[index].value.tr,
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (description.isNotEmpty &&
              description.toLowerCase() != 'null') ...[
            const SizedBox(height: 16),
            _sectionCard(
              context: context,
              title: 'data5'.tr,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Text(
                  description,
                  style: context.general.textTheme.bodyLarge?.copyWith(
                    color: palette.text,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: context.general.textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _infoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: context.general.textTheme.bodyMedium?.copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.general.textTheme.bodyMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
