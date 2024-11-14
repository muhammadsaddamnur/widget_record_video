// import 'package:flutter_test/flutter_test.dart';
// import 'package:widget_record_video/widget_record_video.dart';
// import 'package:widget_record_video/widget_record_video_platform_interface.dart';
// import 'package:widget_record_video/widget_record_video_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockWidgetRecordVideoPlatform
//     with MockPlatformInterfaceMixin
//     implements WidgetRecordVideoPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final WidgetRecordVideoPlatform initialPlatform = WidgetRecordVideoPlatform.instance;

//   test('$MethodChannelWidgetRecordVideo is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelWidgetRecordVideo>());
//   });

//   test('getPlatformVersion', () async {
//     WidgetRecordVideo widgetRecordVideoPlugin = WidgetRecordVideo();
//     MockWidgetRecordVideoPlatform fakePlatform = MockWidgetRecordVideoPlatform();
//     WidgetRecordVideoPlatform.instance = fakePlatform;

//     expect(await widgetRecordVideoPlugin.getPlatformVersion(), '42');
//   });
// }
