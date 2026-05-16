import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:norigo/ai/clients/mock_ai_client.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/data/culture_guide_mock_data.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/presentation/widgets/culture_bottom_controls.dart';
import 'package:norigo/features/culture_scan/presentation/widgets/culture_info_card.dart';
import 'package:norigo/features/culture_scan/presentation/widgets/culture_top_pill.dart';

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
          harness: const CultureGuideHarness(client: MockAiClient()),
        );
    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.cameraStatus == CultureCameraStatus.initial) {
        _controller.initializeCamera();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final guide = _controller.guide ?? CultureGuideMockData.fallbackGuide;
    final hasResult =
        _controller.scanStatus == CultureScanStatus.result ||
        _controller.scanStatus == CultureScanStatus.error;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _CameraBackground(
              cameraController: _controller.cameraController,
              hasPreview: _controller.hasCameraPreview,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopOverlay(
                  cameraStatus: _controller.cameraStatus,
                  message: _controller.friendlyMessage,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _DetectedTextOverlay(guide: guide),
                        const SizedBox(height: 18),
                        _GuideResultCard(
                          guide: guide,
                          hasResult: hasResult,
                          scanStatus: _controller.scanStatus,
                        ),
                        const SizedBox(height: 12),
                        if (hasResult) ...[
                          CultureInfoCard(
                            title: 'Meaning',
                            body: guide.meaning,
                            icon: Icons.favorite_outline,
                            color: NoriGoColors.purple,
                          ),
                          const SizedBox(height: 10),
                          CultureInfoCard(
                            title: 'Etiquette',
                            body: guide.etiquette,
                            icon: Icons.volunteer_activism_outlined,
                            color: NoriGoColors.blue,
                          ),
                          const SizedBox(height: 10),
                          CultureInfoCard(
                            title: 'Story',
                            body: guide.story,
                            icon: Icons.auto_stories_outlined,
                            color: NoriGoColors.gold,
                          ),
                        ],
                        if (_controller.scanStatus == CultureScanStatus.error)
                          _FriendlyError(message: _controller.friendlyMessage),
                      ],
                    ),
                  ),
                ),
                CultureBottomControls(
                  selectedLanguage: _controller.selectedLanguage,
                  scanStatus: _controller.scanStatus,
                  flashEnabled: _controller.flashEnabled,
                  onLanguageChanged: _controller.updateLanguage,
                  onScanCulture: _controller.scanCulture,
                  onToggleFlash: _controller.toggleFlash,
                  onArView: _showArPlaceholder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showArPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AR View is a placeholder for a future iteration.'),
      ),
    );
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({required this.cameraStatus, required this.message});

  final CultureCameraStatus cameraStatus;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              const CultureTopPill(
                label: 'Bulguksa',
                icon: Icons.temple_buddhist,
              ),
              const Spacer(),
              CultureTopPill(
                label: 'Guide',
                icon: Icons.menu_book_outlined,
                isAction: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Guide mode is ready for mock scanning.'),
                    ),
                  );
                },
              ),
            ],
          ),
          if (cameraStatus == CultureCameraStatus.loading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              minHeight: 3,
              color: NoriGoColors.lime,
              backgroundColor: Colors.white24,
            ),
          ],
          if (cameraStatus == CultureCameraStatus.unavailable &&
              message != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: NoriGoColors.ink),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CameraBackground extends StatelessWidget {
  const _CameraBackground({
    required this.cameraController,
    required this.hasPreview,
  });

  final CameraController? cameraController;
  final bool hasPreview;

  @override
  Widget build(BuildContext context) {
    final controller = cameraController;
    if (hasPreview && controller != null) {
      final previewSize = controller.value.previewSize;
      if (previewSize != null) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        );
      }
      return CameraPreview(controller);
    }

    return const _FallbackCameraBackground();
  }
}

class _FallbackCameraBackground extends StatelessWidget {
  const _FallbackCameraBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF201033), Color(0xFF163D5A), Color(0xFF2C2A24)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 140,
            right: 28,
            child: Icon(
              Icons.temple_buddhist,
              size: 104,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: 190,
            left: 32,
            right: 32,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: const Center(
                child: Icon(
                  Icons.landscape_outlined,
                  size: 78,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedTextOverlay extends StatelessWidget {
  const _DetectedTextOverlay({required this.guide});

  final CultureGuide guide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: NoriGoColors.purple.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            guide.koreanSource,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: NoriGoColors.purple,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            guide.translation,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _GuideResultCard extends StatelessWidget {
  const _GuideResultCard({
    required this.guide,
    required this.hasResult,
    required this.scanStatus,
  });

  final CultureGuide guide;
  final bool hasResult;
  final CultureScanStatus scanStatus;

  @override
  Widget build(BuildContext context) {
    final isScanning = scanStatus == CultureScanStatus.scanning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: NoriGoColors.lime,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  guide.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: NoriGoColors.purple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(guide.question, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (isScanning)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reading the scene and preparing a local explanation...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          else
            Text(
              hasResult
                  ? guide.description
                  : 'Point the camera at a cultural sign, object, or behavior, then tap Scan Culture.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NoriGoColors.lime.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
