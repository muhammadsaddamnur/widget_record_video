import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'widget_record_video_platform_interface.dart';

/// An implementation of [WidgetRecordVideoPlatform] that uses method channels.
class MethodChannelWidgetRecordVideo extends WidgetRecordVideoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('widget_record_video');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
