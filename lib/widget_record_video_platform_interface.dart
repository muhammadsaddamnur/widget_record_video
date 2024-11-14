import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'widget_record_video_method_channel.dart';

abstract class WidgetRecordVideoPlatform extends PlatformInterface {
  /// Constructs a WidgetRecordVideoPlatform.
  WidgetRecordVideoPlatform() : super(token: _token);

  static final Object _token = Object();

  static WidgetRecordVideoPlatform _instance = MethodChannelWidgetRecordVideo();

  /// The default instance of [WidgetRecordVideoPlatform] to use.
  ///
  /// Defaults to [MethodChannelWidgetRecordVideo].
  static WidgetRecordVideoPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WidgetRecordVideoPlatform] when
  /// they register themselves.
  static set instance(WidgetRecordVideoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
