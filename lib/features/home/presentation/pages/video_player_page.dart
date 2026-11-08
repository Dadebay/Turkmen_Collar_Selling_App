import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/services/video_cache_manager.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoPath;
  final String appBarTitle;

  /// Stable cache key (video slug/id). Caching by this instead of the URL
  /// means a clip is never re-downloaded when its remote URL rotates.
  final String? cacheKey;
  const VideoPlayerPage({
    required this.videoPath,
    required this.appBarTitle,
    this.cacheKey,
    super.key,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _error;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (widget.videoPath.startsWith('http')) {
        final file = await _downloadAndCache(widget.videoPath);
        _videoPlayerController = VideoPlayerController.file(file);
      } else {
        _videoPlayerController = VideoPlayerController.asset(widget.videoPath);
      }
      await _videoPlayerController!.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio + 0.05,
          allowFullScreen: true,
          allowMuting: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: ColorConstants.primaryColor,
            handleColor: ColorConstants.primaryColor,
            backgroundColor: AppPalette.of(context).muted.withOpacity(.3),
            bufferedColor: AppPalette.of(context).muted.withOpacity(.5),
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  /// Returns the cached file, downloading once (with progress) if absent.
  Future<File> _downloadAndCache(String url) async {
    final cacheKey = widget.cacheKey ?? url;
    final cached = await VideoCacheManager.instance.getFileFromCache(cacheKey);
    if (cached != null) {
      return cached.file;
    }

    File? result;
    final stream = VideoCacheManager.instance.getFileStream(
      url,
      key: cacheKey,
      withProgress: true,
    );
    await for (final response in stream) {
      if (response is DownloadProgress) {
        if (mounted) {
          setState(() => _downloadProgress = response.progress);
        }
      } else if (response is FileInfo) {
        result = response.file;
      }
    }
    return result!;
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(title: widget.appBarTitle, showBackButton: true),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            : _chewieController != null
            ? Chewie(controller: _chewieController!)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress,
                    color: ColorConstants.primaryColor,
                  ),
                  if (widget.videoPath.startsWith('http')) ...[
                    const SizedBox(height: 16),
                    Text(
                      'video_downloading'.tr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
