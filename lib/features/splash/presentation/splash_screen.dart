import 'dart:async';

import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';

const _logoAsset = 'assets/images/splash/norigo_logo_full.png';
const _backgroundAsset = 'assets/images/splash/norigo_splash_bg.png';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.enableAutoNavigation = true});

  final bool enableAutoNavigation;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _dotsController;
  late final Animation<double> _logoOpacity;
  Timer? _timer;
  bool _didPrecacheImages = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    );

    if (widget.enableAutoNavigation) {
      _timer = Timer(const Duration(milliseconds: 1700), _openNextScreen);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheImages) return;

    _didPrecacheImages = true;
    precacheImage(const AssetImage(_logoAsset), context, onError: (_, _) {});
    precacheImage(
      const AssetImage(_backgroundAsset),
      context,
      onError: (_, _) {},
    );
  }

  void _openNextScreen() {
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dotsController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SplashColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final isCompact = height < 620;
            final horizontalPadding = (width * 0.075).clamp(20.0, 44.0);
            final topGap = (height * 0.11).clamp(34.0, 116.0);
            final logoWidth = (width * 0.86).clamp(210.0, 430.0);
            final logoHeight = (height * 0.18).clamp(110.0, 184.0);
            final sceneHeight = (height * 0.48).clamp(280.0, 520.0);
            final loadingGap = (height * 0.065).clamp(26.0, 76.0);

            return Stack(
              children: [
                _SplashBackground(height: sceneHeight),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topGap),
                        FadeTransition(
                          opacity: _logoOpacity,
                          child: _SplashLogo(
                            width: logoWidth,
                            height: logoHeight,
                          ),
                        ),
                        SizedBox(height: loadingGap),
                        _LoadingDots(animation: _dotsController),
                        SizedBox(height: isCompact ? 20 : 28),
                        const _LoadingText(),
                        const Spacer(),
                        const _FooterText(),
                        SizedBox(height: isCompact ? 12 : 18),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashColors {
  const _SplashColors._();

  static const white = Color(0xFFFFFFFF);
  static const softBackground = Color(0xFFFAF7FF);
  static const deepPurple = Color(0xFF24104F);
  static const brandPurple = Color(0xFF6A00FF);
  static const violet = Color(0xFF6E22FF);
  static const lavender = Color(0xFFE9DFFF);
  static const paleLavender = Color(0xFFF2ECFF);
  static const lime = Color(0xFFCCFF00);
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        _logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _FallbackLogo(),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Nori'),
                TextSpan(
                  text: 'Go',
                  style: TextStyle(color: _SplashColors.lime),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _SplashColors.deepPurple,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Travel smart, feel local.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _SplashColors.deepPurple,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final activeIndex = (animation.value * 4).floor() % 4;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final isActive = index == activeIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: isActive ? 18 : 16,
              height: isActive ? 18 : 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? _SplashColors.brandPurple
                    : _SplashColors.lavender,
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x446A00FF),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}

class _LoadingText extends StatelessWidget {
  const _LoadingText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Preparing your local journey...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _SplashColors.deepPurple,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '로컬 여정을 준비하고 있어요...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _SplashColors.violet,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _SplashColors.white,
                    _SplashColors.white,
                    _SplashColors.softBackground,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            height: height,
            child: Opacity(
              opacity: 0.84,
              child: Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_SplashColors.white, _SplashColors.paleLavender],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.42, 0.78, 1.0],
                  colors: [
                    _SplashColors.white,
                    Color(0xF2FFFFFF),
                    Color(0x33FFFFFF),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'AI crowd-aware travel + real-time cultural guide. '),
          TextSpan(
            text: '✦',
            style: TextStyle(
              color: _SplashColors.brandPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: _SplashColors.deepPurple,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}
