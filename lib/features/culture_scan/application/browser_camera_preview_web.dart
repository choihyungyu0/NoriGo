import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:web/web.dart' as web;

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
    captureStill: () async => _captureVideoFrame(video),
    dispose: () async {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
      video.srcObject = null;
    },
  );
}

Future<CultureImageCapture?> _captureVideoFrame(
  web.HTMLVideoElement video,
) async {
  final width = video.videoWidth;
  final height = video.videoHeight;
  if (width <= 0 || height <= 0) return null;

  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;
  final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
  if (context == null) return null;

  context.drawImage(video, 0, 0, width, height);
  final dataUrl = canvas.toDataURL('image/jpeg', 0.88.toJS);
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex < 0) return null;

  final bytes = Uint8List.fromList(
    base64Decode(dataUrl.substring(commaIndex + 1)),
  );
  if (bytes.isEmpty) return null;
  return CultureImageCapture(
    bytes: bytes,
    contentType: 'image/jpeg',
    extension: 'jpg',
  );
}
