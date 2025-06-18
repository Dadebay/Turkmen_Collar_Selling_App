import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:yaka2/app/product/custom_widgets/custom_app_bar.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoPath;
  final String appBarTitle;
  const VideoPlayerPage({required this.videoPath, required this.appBarTitle, super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    if (widget.videoPath.startsWith('http')) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    } else {
      _videoPlayerController = VideoPlayerController.asset(widget.videoPath);
    }

    _videoPlayerController.initialize().then((_) {
      setState(() {
        print(_videoPlayerController.value.aspectRatio);
        print(_videoPlayerController.value.aspectRatio);
        print(_videoPlayerController.value.aspectRatio);
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController.value.aspectRatio + 0.05,
          allowPlaybackSpeedChanging: true,
          allowFullScreen: true,
          allowMuting: true,
        );
      });
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.appBarTitle, showBackButton: true),
      body: Center(
        child: _chewieController != null ? Chewie(controller: _chewieController!) : const CircularProgressIndicator(),
      ),
    );
  }
}
