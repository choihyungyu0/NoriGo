import 'package:flutter/widgets.dart';

class BrowserCameraPreviewSession {
  const BrowserCameraPreviewSession({
    required this.widget,
    required this.dispose,
  });

  final Widget widget;
  final Future<void> Function() dispose;
}

Future<BrowserCameraPreviewSession?> createBrowserCameraPreview() async => null;
