import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_video/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_video/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quick_video_encoder_fork/flutter_quick_video_encoder.dart';
import 'package:widget_record_video/recording_controller.dart';

class RecordingWidget extends StatefulWidget {
  const RecordingWidget({
    super.key,
    required this.child,
    required this.controller,
    this.limitTime = 120,
    required this.onComplete,
  });

  /// This is the widget you want to record the screen
  final Widget child;

  /// [RecordingController] Used to start, pause, or stop screen recording
  final RecordingController controller;

  /// [limitTime] is the video recording time limit, when the limit is reached, the process automatically stops.
  /// Its default value is 120 seconds. If you do not have a limit, please set the value -1
  final int limitTime;

  /// [onComplete] is the next action after creating a video, it returns the video path
  final Function(String) onComplete;

  @override
  State<RecordingWidget> createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<RecordingWidget> {
  double originalDuration = 0.0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      {}
    });
    widget.controller.start = startRecording;
    widget.controller.stop = stopRecording;
  }

  Directory? tempDir;

  Future<void> getImageSize() async {
    RenderRepaintBoundary boundary =
        recordKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 1);
    width = image.width;
    height = image.height;
  }

  GlobalKey recordKey = GlobalKey();
  int frameIndex = 0;
  bool isRecording = false;
  Timer? timer;
  int width = 0;
  int height = 0;
  static const int fps = 30;

  BuildContext? _context;

  void startRecording() {
    setState(() {
      isRecording = true;
    });
    startExportVideo();
    timer = Timer(Duration(seconds: widget.limitTime), () {
      stopRecording();
    });
  }

  Future stopRecording() async {
    timer?.cancel();
    setState(() {
      isRecording = false;
    });
  }

  Future<void> startExportVideo() async {
    try {
      int startTime = DateTime.now().millisecondsSinceEpoch;
      await getImageSize();

      Directory? appDir = await getDownloadsDirectory();

      await FlutterQuickVideoEncoder.setup(
        width: (width ~/ 2) * 2,
        height: (height ~/ 2) * 2,
        fps: fps,
        videoBitrate: 1000000,
        profileLevel: ProfileLevel.any,
        audioBitrate: 0,
        audioChannels: 0,
        sampleRate: 0,
        filepath: '${appDir!.path}/exportVideoOnly.mp4',
      );

      Completer<void> readyForMore = Completer<void>();
      readyForMore.complete();

      int totalFrames = widget.limitTime * 1000 * 2;
      for (int i = 0; i < totalFrames; i++) {
        Uint8List? videoFrame;
        Uint8List? audioFrame;
        debugPrint("video time: ${(i / 30).round()}");
        videoFrame = await captureWidgetAsRGBA();

        await readyForMore.future;
        readyForMore = Completer<void>();

        try {
          _appendFrames(videoFrame, audioFrame)
              .then((value) => readyForMore.complete())
              .catchError((e) => readyForMore.completeError(e));
        } catch (e) {
          debugPrint(e.toString());
        }
        if (isRecording == false) {
          break;
        }
      }

      await readyForMore.future;

      await FlutterQuickVideoEncoder.finish();
      int endTime = DateTime.now().millisecondsSinceEpoch;
      int videoTime = ((endTime - startTime) / 1000).round() - 1;
      debugPrint("video time: $videoTime");
      var resultPath =
          await _adjustVideoSpeed(FlutterQuickVideoEncoder.filepath, videoTime);
      widget.onComplete(resultPath);

      FlutterQuickVideoEncoder.dispose();
    } catch (e) {
      ('Error: $e');
    }
  }

  Future<Uint8List?> captureWidgetAsRGBA() async {
    try {
      RenderRepaintBoundary boundary =
          recordKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1);
      width = image.width;
      height = image.height;

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint(
        e.toString(),
      );
      return null;
    }
  }

  Future<void> _appendFrames(
      Uint8List? videoFrame, Uint8List? audioFrame) async {
    if (videoFrame != null) {
      await FlutterQuickVideoEncoder.appendVideoFrame(videoFrame);
    } else {
      debugPrint("Error append $videoFrame");
    }
  }

  Future<void> _getVideoDuration(String filepath) async {
    final data = await FFprobeKit.getMediaInformation(filepath);
    final media = data.getMediaInformation();
    final secondsStr = media?.getDuration();
    originalDuration = double.parse(secondsStr ?? "0");
  }

  Future<double> _calculateSpeedRatio(
      String filepath, int targetDuration) async {
    await _getVideoDuration(filepath);
    if (originalDuration == 0.0) {
      return 1.0;
    }
    return targetDuration/ originalDuration ;
  }

  // Điều chỉnh tốc độ video
  Future<String> _adjustVideoSpeed(String filepath, int targetDuration) async {
    final speedRatio = await _calculateSpeedRatio(filepath, targetDuration);
    Directory? appDir = await getDownloadsDirectory();

    // Sử dụng FFmpeg để thay đổi tốc độ video
    String outputPath = '${appDir!.path}/result.mp4';

    final command =
        '-y -i $filepath -filter:v "setpts=$speedRatio*PTS" $outputPath';

    final result = await FFmpegKit.execute(command);
    final returnCode = await result.getReturnCode();

    // var message = await result.getAllLogs();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      return "";
    }
  }

  void showSnackBar(String message) {
    debugPrint(message);
    final snackBar = SnackBar(content: Text(message));
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(snackBar);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      body: RepaintBoundary(
        key: recordKey,
        child: widget.child,
      ),
    );
  }
}
