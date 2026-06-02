import 'package:flutter/widgets.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';

class BrowserCameraPreviewSession {
  const BrowserCameraPreviewSession({
    required this.widget,
    required this.dispose,
    this.captureStill,
  });

  final Widget widget;
  final Future<void> Function() dispose;
  final Future<CultureImageCapture?> Function()? captureStill;
}

Future<BrowserCameraPreviewSession?> createBrowserCameraPreview() async => null;
