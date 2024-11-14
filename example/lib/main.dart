import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:widget_record_video/widget_record_video.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final RecordingController recordingController = RecordingController();
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Timer _colorChangeTimer;
  VideoPlayerController? _videoController;
  String? _videoPath;

  @override
  void initState() {
    super.initState();

    // Start color change timer for the animated container
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 3), // Set duration of the color change cycle
    )..repeat(); // Repeat animation infinitely

    // Create the color animation using a Tween
    _colorAnimation = ColorTween(
      begin: Colors.blue, // Starting color
      end: Colors.red, // Ending color
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _colorChangeTimer.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _startRecording() {
    recordingController.start?.call();
  }

  Future<void> _stopRecording() async {
    recordingController.stop?.call();
  }

  Future<void> _onRecordingComplete(String path) async {
    setState(() {
      _videoPath = path;
    });

    _videoController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Widget Record Example App'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 300.0,
                  child: RecordingWidget(
                    controller: recordingController,
                    onComplete: _onRecordingComplete,
                    child: AnimatedBuilder(
                      animation: _colorAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: _colorAnimation.value,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _startRecording,
                      child: const Text('Start Recording'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _stopRecording,
                      child: const Text('Stop Recording'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_videoPath != null) ...[
                  const Text('Playback of Recorded Video:'),
                  const SizedBox(height: 10),
                  _videoController != null &&
                          _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
