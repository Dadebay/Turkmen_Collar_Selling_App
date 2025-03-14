// ignore_for_file: file_names, void_checks, always_use_package_imports

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

import '../../../product/constants/index.dart';

class PhotoViewPage extends StatefulWidget {
  final String? image;
  final bool networkImage;
  const PhotoViewPage({
    required this.networkImage,
    this.image,
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
        backgroundColor: ColorConstants.blackColor,
        body: Stack(
          children: [
            Center(
              child: widget.networkImage
                  ? InteractiveViewer(
                      child: Stack(
                        children: [
                          Positioned.fill(child: Image.network(widget.image!, fit: BoxFit.contain)),
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
                      tightMode: false,
                      errorBuilder: (context, url, error) => const Icon(Icons.error_outline),
                      loadingBuilder: (context, url) => Loading(),
                    ),
            ),
            Positioned(
              right: 20.0,
              top: 20.0,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(CupertinoIcons.xmark_circle, color: ColorConstants.whiteColor, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
