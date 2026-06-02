import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class BrowserCameraPreviewSession {
  const BrowserCameraPreviewSession({
    required this.widget,
    required this.dispose,
  });

  final Widget widget;
  final Future<void> Function() dispose;
}

int _nextViewId = 0;

Future<BrowserCameraPreviewSession?> createBrowserCameraPreview() async {
  final constraints = web.MediaStreamConstraints(
    video: true.toJS,
    audio: false.toJS,
  );
  final stream = await web.window.navigator.mediaDevices
      .getUserMedia(constraints)
      .toDart;
  final viewType = 'norigo-culture-camera-preview-${_nextViewId++}';
  final video = web.HTMLVideoElement()
    ..autoplay = true
    ..muted = true
    ..srcObject = stream
    ..setAttribute('playsinline', '');

  video.style
    ..setProperty('width', '100%')
    ..setProperty('height', '100%')
    ..setProperty('object-fit', 'cover')
    ..setProperty('background', '#111')
    ..setProperty('transform', 'scaleX(-1)');

  final frame = web.HTMLDivElement()
    ..style.setProperty('width', '100%')
    ..style.setProperty('height', '100%')
    ..style.setProperty('overflow', 'hidden')
    ..append(video);

  ui_web.platformViewRegistry.registerViewFactory(viewType, (_) => frame);

  try {
    await video.play().toDart;
  } catch (_) {
    // Autoplay can be strict in some browsers; the live srcObject still starts
    // once the user grants camera access or interacts with the page.
  }

  return BrowserCameraPreviewSession(
    widget: HtmlElementView(viewType: viewType),
    dispose: () async {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
      video.srcObject = null;
    },
  );
}
