import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

const _scanBackgroundAsset = 'assets/images/scan/bulguksa_stone_stack_bg.png';

class CultureScanScreen extends StatefulWidget {
  const CultureScanScreen({this.controller, super.key});

  final CultureScanController? controller;

  @override
  State<CultureScanScreen> createState() => _CultureScanScreenState();
}

class _CultureScanScreenState extends State<CultureScanScreen> {
  late final CultureScanController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        CultureScanController(
          cameraService: const DeviceCultureCameraService(),
        );
    _controller.addListener(_onControllerChanged);
    _controller.initializeCamera();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scanCulture() async {
    if (_controller.scanStatus == CultureScanStatus.scanning) return;
    final baseRequest = _controller.defaultRequest;
    final draft = await _controller.prepareVisionScan(baseRequest);
    if (!mounted) return;

    CultureScanRequest? request;
    if (draft.visionResult.requiresManualSelection) {
      if (draft.visionResult.detectedObjectSource == 'no_match') {
        _showSnack(
          'I couldn’t identify a supported travel situation. Please choose the closest situation.',
        );
      }
      final selection = await _showCultureScanSheet();
      if (!mounted) return;
      request = selection
          ?.toRequest(_controller.selectedLanguage)
          .copyWith(imagePath: draft.imagePath);
    } else {
      final useVision = await _showVisionConfirmationSheet(draft);
      if (!mounted) return;
      if (useVision == true) {
        request = draft.visionResult.toCultureScanRequest(
          base: baseRequest.copyWith(
            userLanguage: _controller.selectedLanguage,
          ),
          imagePath: draft.imagePath,
          detectedObjectSource: draft.visionResult.confirmedObjectSource,
        );
      } else if (useVision == false) {
        final selection = await _showCultureScanSheet();
        if (!mounted) return;
        request = selection
            ?.toRequest(_controller.selectedLanguage)
            .copyWith(imagePath: draft.imagePath);
      }
    }
    if (request == null) return;
    await _controller.runCultureGuide(request);
    if (!mounted) return;
    await _showGuideResultSheet();
  }

  Future<void> _runEnnoiaCultureGuide() async {
    await _controller.runCultureGuide(_controller.defaultRequest);
    if (!mounted) return;
    await _showGuideResultSheet();
  }

  Future<void> _handleGuideTap() async {
    if (_controller.result != null) {
      await _showGuideResultSheet();
      return;
    }
    await _runEnnoiaCultureGuide();
  }

  Future<void> _showGuideResultSheet() async {
    final guide = _controller.guide;
    if (guide == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _ScanColors.white,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.56,
          alignment: Alignment.bottomCenter,
          child: _GuideResultSheet(
            guide: guide,
            sourceLabel: _controller.ennoiaSourceLabel,
            isEnnoiaLoading: _controller.isRunningEnnoia,
            onRunEnnoia: () {
              Navigator.of(sheetContext).pop();
              _runEnnoiaCultureGuide();
            },
            onPhraseTap: () => _handlePhraseTap(guide),
          ),
        );
      },
    );
  }

  Future<void> _toggleFlash() async {
    final toggled = await _controller.toggleFlash();
    if (!toggled && mounted) {
      _showSnack('Flash is not available on this device.');
    }
  }

  Future<void> _selectLanguage() async {
    final language = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _ScanColors.white,
      builder: (context) {
        const languages = ['English', '한국어', '日本語', '中文'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Language',
                  style: TextStyle(
                    color: _ScanColors.deepText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...languages.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      item == _controller.selectedLanguage
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: _ScanColors.purple,
                    ),
                    title: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (language != null) _controller.updateLanguage(language);
  }

  void _handleBottomNavigation(int index) {
    final route = switch (index) {
      0 => AppRoutes.home,
      1 => AppRoutes.itinerary,
      2 => null,
      4 => AppRoutes.my,
      _ => null,
    };

    if (index == 2) return;

    if (route != null && AppRouter.routes.containsKey(route)) {
      Navigator.of(context).pushReplacementNamed(route);
      return;
    }

    _showSnack('This section will be connected later.');
  }

  Future<_CultureScanSheetSelection?> _showCultureScanSheet() {
    return showModalBottomSheet<_CultureScanSheetSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _ScanColors.white,
      builder: (context) => const _CultureScanContextSheet(),
    );
  }

  Future<bool?> _showVisionConfirmationSheet(CultureVisionScanDraft draft) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _ScanColors.white,
      builder: (context) => _VisionConfirmationSheet(draft: draft),
    );
  }

  Future<void> _handlePhraseTap(CultureGuide guide) async {
    final phrase = guide.koreanSource.trim();
    if (phrase.isEmpty) {
      _showSnack('No phrase is available yet.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: phrase));
    if (!mounted) return;
    _showSnack('Phrase ready: $phrase');
  }

  @override
  Widget build(BuildContext context) {
    final guide =
        _controller.guide ??
        CultureGuideResult.readyPreview(
          _controller.defaultRequest,
        ).toCultureGuide();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _ScanColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _ScanColors.white,
        bottomNavigationBar: _ScanBottomNavigation(
          selectedIndex: 2,
          onChanged: _handleBottomNavigation,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _ScanBackground(controller: _controller)),
            const Positioned.fill(child: _ReadabilityOverlay()),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pageWidth = math.min(constraints.maxWidth, 560.0);
                    final widthScale = pageWidth / 430.0;
                    final heightScale = constraints.maxHeight / 844.0;
                    final scale = math
                        .min(widthScale, heightScale)
                        .clamp(0.76, 1.08)
                        .toDouble();

                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: pageWidth,
                        height: constraints.maxHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 14 * scale,
                              left: 18 * scale,
                              child: _LocationPill(
                                scale: scale,
                                locationName: guide.locationName,
                              ),
                            ),
                            Positioned(
                              top: 14 * scale,
                              right: 18 * scale,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _FlashIconButton(
                                    key: const ValueKey(
                                      'flashToggleIconButton',
                                    ),
                                    scale: scale,
                                    flashEnabled: _controller.flashEnabled,
                                    onTap: _toggleFlash,
                                  ),
                                  SizedBox(width: 10 * scale),
                                  _GuidePill(
                                    key: const ValueKey('guidePill'),
                                    scale: scale,
                                    onTap: _handleGuideTap,
                                  ),
                                ],
                              ),
                            ),
                            if (_controller.friendlyMessage != null &&
                                !_controller.hasCameraPreview)
                              Positioned(
                                top: 70 * scale,
                                left: 18 * scale,
                                right: 18 * scale,
                                child: _CameraFallbackNotice(
                                  message: _controller.friendlyMessage!,
                                  scale: scale,
                                ),
                              ),
                            Positioned(
                              left: 18 * scale,
                              right: 18 * scale,
                              bottom: 24 * scale,
                              child: _BottomScanControls(
                                scale: scale,
                                selectedLanguage: _controller.selectedLanguage,
                                scanStatus: _controller.scanStatus,
                                onLanguageTap: _selectLanguage,
                                onScanCulture: _scanCulture,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFallbackNotice extends StatelessWidget {
  const _CameraFallbackNotice({required this.message, required this.scale});

  final String message;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      radius: 16 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 13 * scale,
        vertical: 10 * scale,
      ),
      opacity: 0.90,
      child: Row(
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: _ScanColors.muted,
            size: 18 * scale,
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ScanColors.bodyText,
                fontSize: 12.4 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBackground extends StatelessWidget {
  const _ScanBackground({required this.controller});

  final CultureScanController controller;

  @override
  Widget build(BuildContext context) {
    final webPreview = controller.cameraPreview;
    if (webPreview != null) {
      return webPreview;
    }

    final cameraController = controller.cameraController;
    if (controller.hasCameraPreview && cameraController != null) {
      return CameraPreview(cameraController);
    }

    return Image.asset(
      _scanBackgroundAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _FallbackScanBackground(),
    );
  }
}

class _FallbackScanBackground extends StatelessWidget {
  const _FallbackScanBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF65B9FF), Color(0xFFCFECC9), Color(0xFF937B5E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _FallbackScenePainter())),
          Positioned(
            left: 28,
            right: 28,
            bottom: 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const SizedBox(height: 156),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roofPaint = Paint()..color = const Color(0xFF263542);
    final trimPaint = Paint()..color = const Color(0xFFB5462E);
    final stonePaint = Paint()..color = const Color(0xFF8A8172);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final roof = Path()
      ..moveTo(-size.width * 0.08, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.12,
        size.width * 0.96,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.25,
        -size.width * 0.08,
        size.height * 0.32,
      )
      ..close();
    canvas.drawPath(roof, shadowPaint);
    canvas.drawPath(roof, roofPaint);

    final trim = Path()
      ..moveTo(0, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.24,
        size.width,
        size.height * 0.32,
      )
      ..lineTo(size.width, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.28,
        0,
        size.height * 0.34,
      )
      ..close();
    canvas.drawPath(trim, trimPaint);

    final pedestal = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.70, size.height * 0.70),
        width: size.width * 0.20,
        height: size.height * 0.16,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(pedestal, stonePaint);

    final stones = [
      Offset(size.width * 0.70, size.height * 0.53),
      Offset(size.width * 0.70, size.height * 0.48),
      Offset(size.width * 0.70, size.height * 0.44),
      Offset(size.width * 0.70, size.height * 0.40),
    ];
    final widths = [84.0, 62.0, 47.0, 32.0];
    final heights = [34.0, 27.0, 23.0, 18.0];

    for (var i = 0; i < stones.length; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: stones[i],
          width: widths[i],
          height: heights[i],
        ),
        stonePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReadabilityOverlay extends StatelessWidget {
  const _ReadabilityOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x11000000), Color(0x00000000), Color(0x33000000)],
        ),
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  const _GlassBox({
    required this.child,
    required this.radius,
    required this.padding,
    this.width,
    this.height,
    this.opacity = 0.94,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: _ScanColors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _ScanColors.white.withValues(alpha: 0.58),
            ),
            boxShadow: [
              BoxShadow(
                color: _ScanColors.shadow.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.scale, required this.locationName});

  final double scale;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      radius: 32 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: _ScanColors.limeDeep,
            size: 29 * scale,
          ),
          SizedBox(width: 10 * scale),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 150 * scale),
            child: Text(
              locationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ScanColors.deepText,
                fontSize: 17 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 10 * scale),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _ScanColors.muted,
            size: 24 * scale,
          ),
        ],
      ),
    );
  }
}

class _GuidePill extends StatelessWidget {
  const _GuidePill({required this.scale, required this.onTap, super.key});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32 * scale),
          onTap: onTap,
          child: _GlassBox(
            radius: 32 * scale,
            padding: EdgeInsets.symmetric(
              horizontal: 18 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: _ScanColors.purple,
                  size: 25 * scale,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  'Guide',
                  style: TextStyle(
                    color: _ScanColors.deepText,
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashIconButton extends StatelessWidget {
  const _FlashIconButton({
    required this.scale,
    required this.flashEnabled,
    required this.onTap,
    super.key,
  });

  final double scale;
  final bool flashEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = flashEnabled
        ? Icons.flash_on_rounded
        : Icons.flash_off_rounded;
    return Semantics(
      button: true,
      label: flashEnabled ? 'Flash on' : 'Flash off',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24 * scale),
          onTap: onTap,
          child: _GlassBox(
            width: 48 * scale,
            height: 48 * scale,
            radius: 24 * scale,
            padding: EdgeInsets.zero,
            child: Icon(icon, color: _ScanColors.deepText, size: 23 * scale),
          ),
        ),
      ),
    );
  }
}

class _CultureGuideCard extends StatelessWidget {
  const _CultureGuideCard({
    required this.guide,
    required this.scanStatus,
    required this.sourceLabel,
    required this.isEnnoiaLoading,
    required this.onRunEnnoia,
    required this.scale,
  });

  final CultureGuide guide;
  final CultureScanStatus scanStatus;
  final String sourceLabel;
  final bool isEnnoiaLoading;
  final VoidCallback onRunEnnoia;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isScanning = scanStatus == CultureScanStatus.scanning;
    final isReady = sourceLabel == 'Ready to scan';

    return _GlassBox(
      radius: 24 * scale,
      padding: EdgeInsets.all(16 * scale),
      opacity: 0.96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: _ScanColors.purple,
                size: 24 * scale,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  guide.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ScanColors.deepText,
                    fontSize: 15.5 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Row(
            children: [
              _AgentSourceBadge(label: sourceLabel, scale: scale),
              SizedBox(width: 8 * scale),
              Expanded(
                child: SizedBox(
                  height: 34 * scale,
                  child: OutlinedButton.icon(
                    key: const ValueKey('runEnnoiaCultureGuideButton'),
                    onPressed: isEnnoiaLoading ? null : onRunEnnoia,
                    icon: isEnnoiaLoading
                        ? SizedBox(
                            width: 15 * scale,
                            height: 15 * scale,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _ScanColors.purple,
                            ),
                          )
                        : Icon(Icons.travel_explore_rounded, size: 16 * scale),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isReady ? 'Run Guide' : 'Refresh Guide',
                        style: TextStyle(
                          fontSize: 11.8 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ScanColors.purple,
                      side: const BorderSide(color: _ScanColors.purple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          Text(
            guide.question,
            style: TextStyle(
              color: _ScanColors.deepText,
              fontSize: 25.5 * scale,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 13 * scale),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isScanning
                ? Row(
                    key: const ValueKey('scan-loading-message'),
                    children: [
                      SizedBox(
                        width: 18 * scale,
                        height: 18 * scale,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: _ScanColors.purple,
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: Text(
                          'Understanding the local context...',
                          style: TextStyle(
                            color: _ScanColors.bodyText,
                            fontSize: 13.5 * scale,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    guide.description,
                    key: const ValueKey('guide-description'),
                    style: TextStyle(
                      color: _ScanColors.bodyText,
                      fontSize: 14.6 * scale,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          SizedBox(height: 16 * scale),
          _CultureInfoRow(
            scale: scale,
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFF8D6BF4),
            bubbleColor: const Color(0xFFEAE1FF),
            title: 'Meaning',
            body: guide.meaning,
          ),
          SizedBox(height: 10 * scale),
          _CultureInfoRow(
            scale: scale,
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFF39A217),
            bubbleColor: const Color(0xFFEAF8DE),
            title: 'Etiquette',
            body: guide.etiquette,
          ),
          SizedBox(height: 10 * scale),
          _CultureInfoRow(
            scale: scale,
            icon: Icons.menu_book_rounded,
            iconColor: _ScanColors.blue,
            bubbleColor: const Color(0xFFE0F1FF),
            title: 'Story',
            body: guide.story,
          ),
        ],
      ),
    );
  }
}

class _GuideResultSheet extends StatelessWidget {
  const _GuideResultSheet({
    required this.guide,
    required this.sourceLabel,
    required this.isEnnoiaLoading,
    required this.onRunEnnoia,
    required this.onPhraseTap,
  });

  final CultureGuide guide;
  final String sourceLabel;
  final bool isEnnoiaLoading;
  final VoidCallback onRunEnnoia;
  final VoidCallback onPhraseTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetWidth = math.min(constraints.maxWidth, 560.0);
        final scale = (sheetWidth / 430.0).clamp(0.88, 1.0).toDouble();

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: sheetWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                0,
                18 * scale,
                24 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InlinePhraseButton(
                    guide: guide,
                    scale: scale,
                    onTap: onPhraseTap,
                  ),
                  SizedBox(height: 12 * scale),
                  _CultureGuideCard(
                    guide: guide,
                    scanStatus: CultureScanStatus.idle,
                    sourceLabel: sourceLabel,
                    isEnnoiaLoading: isEnnoiaLoading,
                    onRunEnnoia: onRunEnnoia,
                    scale: scale,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InlinePhraseButton extends StatelessWidget {
  const _InlinePhraseButton({
    required this.guide,
    required this.scale,
    required this.onTap,
  });

  final CultureGuide guide;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final phrase = guide.koreanSource.trim();
    final translation = guide.translation.trim();
    if (phrase.isEmpty && translation.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * scale),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 12 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3FF),
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: const Color(0xFFE2D9FF)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.volume_up_rounded,
                color: _ScanColors.purple,
                size: 22 * scale,
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phrase.isNotEmpty)
                      Text(
                        phrase,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ScanColors.deepText,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    if (translation.isNotEmpty) ...[
                      SizedBox(height: 2 * scale),
                      Text(
                        translation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ScanColors.bodyText,
                          fontSize: 12.5 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentSourceBadge extends StatelessWidget {
  const _AgentSourceBadge({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isReal =
        label.contains('Culture DB + ennoia') || label.contains('Culture DB');
    final isLimited = label.contains('Travel behavior only');
    final isReady = label == 'Ready to scan';
    final isLocal = label == 'Local guide';
    final isEnnoia = label.contains('ennoia');
    return Container(
      height: 26 * scale,
      constraints: BoxConstraints(maxWidth: 176 * scale),
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isReal
            ? const Color(0xFFEAF8DE)
            : isLimited
            ? const Color(0xFFE8F1FF)
            : isReady
            ? const Color(0xFFF0EAFF)
            : isEnnoia
            ? const Color(0xFFF0EAFF)
            : isLocal
            ? const Color(0xFFF4F4F6)
            : const Color(0xFFFFF2D7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReal
              ? const Color(0xFFD3E9C6)
              : isLimited
              ? const Color(0xFFCFE0FF)
              : isReady
              ? const Color(0xFFDDD0FF)
              : isEnnoia
              ? const Color(0xFFDDD0FF)
              : isLocal
              ? const Color(0xFFE1E2EA)
              : const Color(0xFFFFD998),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: isReal
                ? const Color(0xFF258616)
                : isLimited
                ? _ScanColors.blue
                : isReady
                ? _ScanColors.purple
                : isEnnoia
                ? _ScanColors.purple
                : isLocal
                ? _ScanColors.muted
                : const Color(0xFF985900),
            fontSize: 10.8 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _CultureInfoRow extends StatelessWidget {
  const _CultureInfoRow({
    required this.scale,
    required this.icon,
    required this.iconColor,
    required this.bubbleColor,
    required this.title,
    required this.body,
  });

  final double scale;
  final IconData icon;
  final Color iconColor;
  final Color bubbleColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(11 * scale),
      decoration: BoxDecoration(
        color: _ScanColors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: _ScanColors.white.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: _ScanColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46 * scale,
            height: 46 * scale,
            decoration: BoxDecoration(
              color: bubbleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 25 * scale),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _ScanColors.deepText,
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  body,
                  style: TextStyle(
                    color: _ScanColors.bodyText,
                    fontSize: 12.9 * scale,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomScanControls extends StatelessWidget {
  const _BottomScanControls({
    required this.scale,
    required this.selectedLanguage,
    required this.scanStatus,
    required this.onLanguageTap,
    required this.onScanCulture,
  });

  final double scale;
  final String selectedLanguage;
  final CultureScanStatus scanStatus;
  final VoidCallback onLanguageTap;
  final VoidCallback onScanCulture;

  @override
  Widget build(BuildContext context) {
    final isScanning = scanStatus == CultureScanStatus.scanning;

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerWidth = 104 * scale;
        final sideWidth = math
            .min(132 * scale, (constraints.maxWidth - centerWidth - 24) / 2)
            .clamp(96 * scale, 132 * scale)
            .toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: sideWidth,
              child: _SmallControlPill(
                key: const ValueKey('languageSelectorPill'),
                icon: Icons.language_rounded,
                text: selectedLanguage,
                trailing: Icons.keyboard_arrow_down_rounded,
                scale: scale,
                onTap: onLanguageTap,
              ),
            ),
            _ScanButton(
              scale: scale,
              isScanning: isScanning,
              onPressed: isScanning ? null : onScanCulture,
            ),
            SizedBox(width: sideWidth),
          ],
        );
      },
    );
  }
}

class _SmallControlPill extends StatelessWidget {
  const _SmallControlPill({
    required this.icon,
    required this.text,
    required this.scale,
    required this.onTap,
    super.key,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final double scale;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28 * scale),
          onTap: onTap,
          child: _GlassBox(
            radius: 28 * scale,
            padding: EdgeInsets.symmetric(
              horizontal: 13 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _ScanColors.muted, size: 22 * scale),
                SizedBox(width: 9 * scale),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ScanColors.bodyText,
                      fontSize: 14.5 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: 5 * scale),
                  Icon(trailing, color: _ScanColors.muted, size: 21 * scale),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.scale,
    required this.isScanning,
    required this.onPressed,
  });

  final double scale;
  final bool isScanning;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'Scan Culture',
            child: SizedBox(
              width: 88 * scale,
              height: 88 * scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_ScanColors.purple, _ScanColors.purpleDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _ScanColors.purple.withValues(alpha: 0.34),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(6 * scale),
                  child: FilledButton(
                    key: const ValueKey('scanCultureButton'),
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: _ScanColors.white,
                      foregroundColor: _ScanColors.purple,
                      disabledBackgroundColor: _ScanColors.white,
                      disabledForegroundColor: _ScanColors.purple,
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: isScanning
                        ? SizedBox(
                            width: 28 * scale,
                            height: 28 * scale,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.8,
                              color: _ScanColors.purple,
                            ),
                          )
                        : Icon(Icons.crop_free_rounded, size: 34 * scale),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Scan Culture',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ScanColors.white,
              fontSize: 17 * scale,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CultureScanContextSheet extends StatefulWidget {
  const _CultureScanContextSheet();

  @override
  State<_CultureScanContextSheet> createState() =>
      _CultureScanContextSheetState();
}

class _CultureScanContextSheetState extends State<_CultureScanContextSheet> {
  final _questionController = TextEditingController();
  _PlaceOption _selectedPlace = _placeOptions.first;
  late _SituationOption _selectedSituation = _situationsFor(
    _selectedPlace.key,
  ).first;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final situations = _situationsFor(_selectedPlace.key);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 2, 22, 22 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan context',
              style: TextStyle(
                color: _ScanColors.deepText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            const _SheetLabel(text: 'Place type'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _placeOptions
                  .map(
                    (place) => ChoiceChip(
                      label: Text(place.label),
                      selected: _selectedPlace == place,
                      onSelected: (_) {
                        setState(() {
                          _selectedPlace = place;
                          _selectedSituation = _situationsFor(
                            _selectedPlace.key,
                          ).first;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            const _SheetLabel(text: 'Situation'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: situations
                  .map(
                    (situation) => ChoiceChip(
                      label: Text(situation.label),
                      selected: _selectedSituation == situation,
                      onSelected: (_) {
                        setState(() => _selectedSituation = situation);
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _questionController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Optional question',
                hintText: _selectedSituation.defaultQuestion,
                filled: true,
                fillColor: const Color(0xFFF7F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0D7FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0D7FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _ScanColors.purple),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const ValueKey('runCultureGuideFromSheetButton'),
                onPressed: () {
                  Navigator.of(context).pop(
                    _CultureScanSheetSelection(
                      place: _selectedPlace,
                      situation: _selectedSituation,
                      userQuestion: _questionController.text,
                    ),
                  );
                },
                icon: const Icon(Icons.travel_explore_rounded),
                label: const Text('Scan Culture'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ScanColors.purple,
                  foregroundColor: _ScanColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisionConfirmationSheet extends StatelessWidget {
  const _VisionConfirmationSheet({required this.draft});

  final CultureVisionScanDraft draft;

  @override
  Widget build(BuildContext context) {
    final vision = draft.visionResult;
    final confidence = '${(vision.confidence * 100).round()}%';
    final title = vision.confidence >= 0.75
        ? 'I found this situation'
        : 'Maybe this is...';
    final bottom = MediaQuery.paddingOf(context).bottom;
    final alternatives = vision.alternatives
        .where((item) => item.detectedObject != vision.detectedObject)
        .take(3)
        .toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 2, 22, 22 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ScanColors.deepText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0D7FF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.center_focus_strong_rounded,
                    color: _ScanColors.purple,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vision.label,
                          style: const TextStyle(
                            color: _ScanColors.deepText,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vision.sourceBadge} · confidence $confidence',
                          style: const TextStyle(
                            color: _ScanColors.bodyText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SheetLabel(text: 'Other possible matches'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: alternatives
                    .map(
                      (item) => Chip(
                        label: Text(
                          '${item.label} ${(item.confidence * 100).round()}%',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ScanColors.purple,
                      side: const BorderSide(color: _ScanColors.purple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('useVisionCandidateButton'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Use this'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ScanColors.purple,
                      foregroundColor: _ScanColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _ScanColors.bodyText,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CultureScanSheetSelection {
  const _CultureScanSheetSelection({
    required this.place,
    required this.situation,
    required this.userQuestion,
  });

  final _PlaceOption place;
  final _SituationOption situation;
  final String userQuestion;

  CultureScanRequest toRequest(String userLanguage) {
    final trimmedQuestion = userQuestion.trim();
    return CultureScanRequest(
      userLanguage: userLanguage,
      currentLocation: place.defaultLocation,
      placeType: place.key,
      detectedObject: situation.objectKey,
      koreanKeyword: situation.koreanKeyword,
      userIntent: 'Understand local culture and etiquette',
      userQuestion: trimmedQuestion.isEmpty
          ? situation.defaultQuestion
          : trimmedQuestion,
    );
  }
}

class _PlaceOption {
  const _PlaceOption(this.label, this.key, this.defaultLocation);

  final String label;
  final String key;
  final String defaultLocation;
}

class _SituationOption {
  const _SituationOption({
    required this.label,
    required this.objectKey,
    required this.koreanKeyword,
    required this.defaultQuestion,
  });

  final String label;
  final String objectKey;
  final String koreanKeyword;
  final String defaultQuestion;
}

const _placeOptions = [
  _PlaceOption('Temple', 'temple', 'Bulguksa'),
  _PlaceOption('Palace', 'palace', 'Gyeongbokgung Palace'),
  _PlaceOption('Restaurant', 'restaurant', 'Korean restaurant'),
  _PlaceOption('Cafe', 'cafe', 'Seoul cafe'),
  _PlaceOption('Subway', 'subway', 'Seoul subway'),
  _PlaceOption('Market', 'market', 'Gwangjang Market'),
  _PlaceOption('Hanok Village', 'hanok_village', 'Bukchon Hanok Village'),
];

List<_SituationOption> _situationsFor(String placeType) {
  return switch (placeType) {
    'temple' => const [
      _SituationOption(
        label: 'Stone stack',
        objectKey: 'temple_stone_stack',
        koreanKeyword: '소원 성취',
        defaultQuestion: 'Why do Koreans stack stones here?',
      ),
      _SituationOption(
        label: 'Photo etiquette',
        objectKey: 'palace_photo_etiquette',
        koreanKeyword: '사진 찍어도 되나요?',
        defaultQuestion: 'Can I take photos here?',
      ),
    ],
    'palace' => const [
      _SituationOption(
        label: 'Photo etiquette',
        objectKey: 'palace_photo_etiquette',
        koreanKeyword: '사진 찍어도 되나요?',
        defaultQuestion: 'Can I take photos here?',
      ),
    ],
    'restaurant' => const [
      _SituationOption(
        label: 'Call bell',
        objectKey: 'restaurant_call_bell',
        koreanKeyword: '여기요',
        defaultQuestion: 'Is it polite to press the call bell?',
      ),
      _SituationOption(
        label: 'Kiosk',
        objectKey: 'kiosk_ordering',
        koreanKeyword: '도와주실 수 있나요?',
        defaultQuestion: 'Should I order at the kiosk?',
      ),
      _SituationOption(
        label: 'Queue ticket',
        objectKey: 'waiting_number_ticket',
        koreanKeyword: '대기번호',
        defaultQuestion: 'How do waiting numbers work?',
      ),
    ],
    'cafe' => const [
      _SituationOption(
        label: 'Quiet cafe',
        objectKey: 'cafe_quiet_work',
        koreanKeyword: '조용히 할게요',
        defaultQuestion: 'Why is everyone so quiet in this cafe?',
      ),
      _SituationOption(
        label: 'Kiosk',
        objectKey: 'kiosk_ordering',
        koreanKeyword: '도와주실 수 있나요?',
        defaultQuestion: 'Should I order at the kiosk?',
      ),
    ],
    'subway' => const [
      _SituationOption(
        label: 'Pregnant priority seat',
        objectKey: 'subway_pregnant_seat',
        koreanKeyword: '임산부 배려석',
        defaultQuestion: 'Can I sit in the pink subway seat?',
      ),
    ],
    'market' => const [
      _SituationOption(
        label: 'Queue ticket',
        objectKey: 'market_queue_ticket',
        koreanKeyword: '대기표',
        defaultQuestion: 'Why are people taking number tickets?',
      ),
      _SituationOption(
        label: 'Cash and food',
        objectKey: 'market_cash_food',
        koreanKeyword: '카드 돼요?',
        defaultQuestion: 'Can I pay by card and eat while walking?',
      ),
    ],
    'hanok_village' => const [
      _SituationOption(
        label: 'Resident etiquette',
        objectKey: 'hanok_resident_etiquette',
        koreanKeyword: '조용히 지나갈게요',
        defaultQuestion: 'Why are there quiet signs in the village?',
      ),
      _SituationOption(
        label: 'Photo etiquette',
        objectKey: 'palace_photo_etiquette',
        koreanKeyword: '사진 찍어도 되나요?',
        defaultQuestion: 'Can I take photos here?',
      ),
    ],
    _ => const [
      _SituationOption(
        label: 'Stone stack',
        objectKey: 'temple_stone_stack',
        koreanKeyword: '소원 성취',
        defaultQuestion: 'Why do Koreans stack stones here?',
      ),
    ],
  };
}

class _ScanBottomNavigation extends StatelessWidget {
  const _ScanBottomNavigation({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = math.min(constraints.maxWidth, 560.0);
        final scale = (pageWidth / 430.0).clamp(0.84, 1.08).toDouble();
        final safeBottom = MediaQuery.paddingOf(context).bottom;

        final height = 78 * scale + safeBottom;

        return SizedBox(
          height: height,
          child: ColoredBox(
            color: _ScanColors.white,
            child: Center(
              child: SizedBox(
                width: pageWidth,
                height: height,
                child: Padding(
                  padding: EdgeInsets.only(top: 6 * scale, bottom: safeBottom),
                  child: Row(
                    children: List.generate(_ScanNavData.items.length, (index) {
                      final item = _ScanNavData.items[index];
                      return Expanded(
                        child: _ScanNavItem(
                          key: ValueKey(
                            selectedIndex == index
                                ? 'active-nav-${item.label}'
                                : 'nav-${item.label}',
                          ),
                          item: item,
                          selected: selectedIndex == index,
                          scale: scale,
                          onTap: () => onChanged(index),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScanNavItem extends StatelessWidget {
  const _ScanNavItem({
    required this.item,
    required this.selected,
    required this.scale,
    required this.onTap,
    super.key,
  });

  final _ScanNavData item;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _ScanColors.purple : _ScanColors.navMuted;
    final isScan = item.label == 'Scan';

    return InkWell(
      onTap: onTap,
      child: Transform.translate(
        offset: Offset(0, isScan ? -8 * scale : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScan)
              Container(
                width: 52 * scale,
                height: 52 * scale,
                decoration: BoxDecoration(
                  color: _ScanColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _ScanColors.shadow.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: color, size: 29 * scale),
              )
            else
              SizedBox(
                height: 42 * scale,
                child: Icon(item.icon, color: color, size: 27 * scale),
              ),
            SizedBox(height: 3 * scale),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5 * scale,
                height: 1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanNavData {
  const _ScanNavData(this.label, this.icon);

  final String label;
  final IconData icon;

  static const items = [
    _ScanNavData('Home', Icons.home_outlined),
    _ScanNavData('Itinerary', Icons.calendar_month_outlined),
    _ScanNavData('Scan', Icons.crop_free_rounded),
    _ScanNavData('Discover', Icons.explore_outlined),
    _ScanNavData('My', Icons.person_outline_rounded),
  ];
}

class _ScanColors {
  const _ScanColors._();

  static const white = Color(0xFFFFFFFF);
  static const deepText = Color(0xFF24104F);
  static const bodyText = Color(0xFF17192F);
  static const muted = Color(0xFF5E6576);
  static const navMuted = Color(0xFF747A91);
  static const purple = Color(0xFF6A00FF);
  static const purpleDark = Color(0xFF3912D8);
  static const limeDeep = Color(0xFF8CCB00);
  static const blue = Color(0xFF007BFF);
  static const shadow = Color(0xFF382B5E);
}
