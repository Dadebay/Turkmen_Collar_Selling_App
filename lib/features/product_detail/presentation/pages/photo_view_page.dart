import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/no_image.dart';
import '../../../../core/icons/app_icon.dart';

class PhotoViewPage extends StatefulWidget {
  final String? image;
  final bool networkImage;
  final bool shouldShowWaterMark;
  const PhotoViewPage({
    required this.networkImage,
    this.image,
    this.shouldShowWaterMark = true,
    super.key,
  });

  @override
  State<PhotoViewPage> createState() => _PhotoViewPageState();
}

class _PhotoViewPageState extends State<PhotoViewPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: widget.networkImage
                  ? InteractiveViewer(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: widget.image!,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Loading(),
                              errorWidget: (context, url, error) =>
                                  const NoImage(),
                            ),
                          ),
                          if (widget.shouldShowWaterMark)
                            Positioned.fill(
                              child: Image.asset(
                                IconConstants.waterMarkLogo,
                                fit: BoxFit.fitHeight,
                                filterQuality: FilterQuality.low,
                                opacity: const AlwaysStoppedAnimation(.5),
                              ),
                            ),
                        ],
                      ),
                    )
                  : PhotoView(
                      minScale: 0.4,
                      maxScale: 2.0,
                      imageProvider: AssetImage(widget.image!),
                      errorBuilder: (context, url, error) =>
                          const AppIcon(Icons.error_outline),
                      loadingBuilder: (context, url) => const Loading(),
                    ),
            ),
            Positioned(
              right: 20.0,
              top: 20.0,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: AppIcon(
                  CupertinoIcons.xmark_circle,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
