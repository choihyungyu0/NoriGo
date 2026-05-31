import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/features/itinerary/application/crowd_alert_controller.dart';
import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/data/supabase_crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';
import 'package:norigo/features/itinerary/domain/retrip_context.dart';

const _logoAsset = 'assets/images/splash/norigo_logo_full.png';

class CrowdAlertScreen extends StatefulWidget {
  const CrowdAlertScreen({
    super.key,
    this.logoAsset = _logoAsset,
    this.repository = const SupabaseCrowdAlertRepository(),
    this.autoGenerateOnOpen = true,
    this.retripContext,
  });

  final String logoAsset;
  final CrowdAlertRepository repository;
  final bool autoGenerateOnOpen;
  final RetripContext? retripContext;

  @override
  State<CrowdAlertScreen> createState() => _CrowdAlertScreenState();
}

class _CrowdAlertScreenState extends State<CrowdAlertScreen> {
  late final CrowdAlertController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CrowdAlertController(
      repository: widget.repository,
      retripContext: widget.retripContext,
    );
    _loadInitialAlert();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showQueueInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Text(
              'Many popular Korean cafes and restaurants use app-based waiting '
              'systems. A place may look quiet outside, but the digital queue '
              'can already be full.',
              style: TextStyle(
                color: _CrowdColors.deepPurple,
                fontSize: 16,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBottomNavigation(int index) {
    if (index == 1) return;

    final route = switch (index) {
      0 => AppRoutes.home,
      2 => AppRoutes.scan,
      _ => null,
    };

    if (route != null && AppRouter.routes.containsKey(route)) {
      Navigator.of(context).pushReplacementNamed(route);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section will be connected later.')),
    );
  }

  Future<void> _keepOriginalPlan() async {
    final kept = await _controller.keepOriginalPlan();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kept
              ? 'Original plan kept.'
              : _controller.errorMessage ?? 'Unable to keep the original plan.',
        ),
      ),
    );

    if (kept && Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _switchPlan() async {
    final switched = await _controller.switchPlan();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switched
              ? 'Plan updated.'
              : _controller.errorMessage ??
                    'Recommendation selected, but plan update could not be saved.',
        ),
      ),
    );

    if (switched && Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _selectAlternative(AlternativePlace alternative) async {
    _controller.selectAlternative(alternative);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${alternative.name} selected as your new plan.')),
    );
  }

  Future<void> _generateRetripAlternatives() async {
    await _controller.generateRetripAlternatives();
  }

  void _loadInitialAlert() {
    if (widget.autoGenerateOnOpen) {
      _controller.generateRetripAlternatives();
      return;
    }
    _controller.loadAlert();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _CrowdColors.white,
      ),
      child: Scaffold(
        backgroundColor: _CrowdColors.white,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageWidth = math.min(constraints.maxWidth, 560.0);
              final scale = (pageWidth / 430.0).clamp(0.86, 1.06).toDouble();
              final safeBottom = MediaQuery.paddingOf(context).bottom;
              final navHeight = 76 * scale + safeBottom;
              final actionHeight = 58 * scale;

              return Center(
                child: SizedBox(
                  width: pageWidth,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final alert = _controller.alert;

                      if ((_controller.isLoading ||
                              _controller.isGeneratingRetrip) &&
                          alert == null) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _CrowdColors.purple,
                          ),
                        );
                      }

                      if (alert == null) {
                        return _ErrorState(
                          message:
                              _controller.errorMessage ??
                              'Unable to load crowd alert.',
                          onRetry: _loadInitialAlert,
                        );
                      }

                      return Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              18 * scale,
                              14 * scale,
                              18 * scale,
                              navHeight + actionHeight + 36 * scale,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CrowdAlertHeader(
                                  logoAsset: widget.logoAsset,
                                  scale: scale,
                                ),
                                SizedBox(height: 16 * scale),
                                _MiniItineraryTimeline(
                                  alert: alert,
                                  retripContext: widget.retripContext,
                                  scale: scale,
                                ),
                                SizedBox(height: 18 * scale),
                                _AlertMessageCard(
                                  alert: alert,
                                  scale: scale,
                                  onInfoPressed: _showQueueInfo,
                                ),
                                SizedBox(height: 18 * scale),
                                _AlternativesSection(
                                  alert: alert,
                                  selectedAlternative:
                                      _controller.selectedAlternative,
                                  sourceLabel: _controller.sourceLabel,
                                  isGenerating: _controller.isGeneratingRetrip,
                                  scale: scale,
                                  onGenerate: _generateRetripAlternatives,
                                  onSelectAlternative: _selectAlternative,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 18 * scale,
                            right: 18 * scale,
                            bottom: navHeight + 12 * scale,
                            child: _BottomActionButtons(
                              isSwitching: _controller.isSwitching,
                              scale: scale,
                              onKeepOriginal: _keepOriginalPlan,
                              onSwitchPlan: _switchPlan,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _BottomNavigation(
                              selectedIndex: 1,
                              scale: scale,
                              height: navHeight,
                              safeBottom: safeBottom,
                              onChanged: _handleBottomNavigation,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CrowdAlertHeader extends StatelessWidget {
  const _CrowdAlertHeader({required this.logoAsset, required this.scale});

  final String logoAsset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 152 * scale,
          height: 58 * scale,
          child: Image.asset(
            logoAsset,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, _, _) => const _LogoFallback(),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 42 * scale,
          height: 42 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: _CrowdColors.deepPurple,
                size: 32 * scale,
              ),
              Positioned(
                top: 7 * scale,
                right: 8 * scale,
                child: Container(
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: const BoxDecoration(
                    color: _CrowdColors.lime,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10 * scale),
        Container(
          width: 42 * scale,
          height: 42 * scale,
          decoration: BoxDecoration(
            color: _CrowdColors.lavender,
            shape: BoxShape.circle,
            border: Border.all(color: _CrowdColors.border),
            boxShadow: _softShadow(scale),
          ),
          child: Icon(
            Icons.person_rounded,
            color: _CrowdColors.purple,
            size: 26 * scale,
          ),
        ),
      ],
    );
  }
}

class _MiniItineraryTimeline extends StatelessWidget {
  const _MiniItineraryTimeline({
    required this.alert,
    required this.retripContext,
    required this.scale,
  });

  final CrowdAlert alert;
  final RetripContext? retripContext;
  final double scale;

  static const _points = [
    _MiniTimelinePoint(
      title: 'Gyeongbokgung\nPalace',
      time: '09:30',
      icon: Icons.account_balance_rounded,
    ),
    _MiniTimelinePoint(
      title: 'Bukchon Hanok\nVillage',
      time: '11:00',
      icon: Icons.holiday_village_rounded,
    ),
    _MiniTimelinePoint(
      title: 'Cafe Arte',
      time: '13:00',
      icon: Icons.local_cafe_rounded,
      selected: true,
    ),
    _MiniTimelinePoint(
      title: 'Namsan\nTower',
      time: '15:30',
      icon: Icons.cell_tower_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final points = _timelinePoints();
    return SizedBox(
      height: 142 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 62 * scale,
            right: 62 * scale,
            top: 44 * scale,
            child: Row(
              children: [
                const Expanded(child: _DashedLine()),
                _ArrowDot(scale: scale),
                const Expanded(child: _DashedLine()),
                _ArrowDot(scale: scale),
                const Expanded(child: _DashedLine()),
                _ArrowDot(scale: scale),
                const Expanded(child: _DashedLine()),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((point) {
              return Expanded(
                child: _MiniTimelineItem(point: point, scale: scale),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<_MiniTimelinePoint> _timelinePoints() {
    final context = retripContext;
    if (context == null) return _points;

    final items = context.plan.items.take(4).toList(growable: true);
    if (!items.any((item) => item.id == context.item.id)) {
      if (items.length == 4) {
        items[2] = context.item;
      } else {
        items.add(context.item);
      }
    }
    if (items.isEmpty) return _points;

    return items
        .map((item) {
          final selected = item.id == context.item.id;
          return _MiniTimelinePoint(
            title: _compactTitle(item.placeName),
            time: selected ? alert.scheduledTime : item.time,
            icon: _iconFor(item.placeName, item.contentTypeId),
            selected: selected,
          );
        })
        .toList(growable: false);
  }

  String _compactTitle(String title) {
    final words = title.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final compact = words.take(3).join('\n');
    return compact.isEmpty ? title : compact;
  }

  IconData _iconFor(String name, String? contentTypeId) {
    final lower = name.toLowerCase();
    if (contentTypeId == '39' ||
        lower.contains('cafe') ||
        lower.contains('coffee') ||
        lower.contains('카페')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('hanok') || lower.contains('한옥')) {
      return Icons.holiday_village_rounded;
    }
    if (lower.contains('tower') || lower.contains('view')) {
      return Icons.cell_tower_rounded;
    }
    return Icons.account_balance_rounded;
  }
}

class _MiniTimelineItem extends StatelessWidget {
  const _MiniTimelineItem({required this.point, required this.scale});

  final _MiniTimelinePoint point;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final selected = point.selected;

    return Column(
      children: [
        SizedBox(
          height: 72 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (selected)
                Positioned(
                  top: -13 * scale,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 30 * scale,
                    color: _CrowdColors.purple,
                  ),
                ),
              Positioned(
                top: selected ? 16 * scale : 20 * scale,
                child: Container(
                  width: selected ? 67 * scale : 58 * scale,
                  height: selected ? 67 * scale : 58 * scale,
                  padding: EdgeInsets.all(selected ? 3 * scale : 0),
                  decoration: BoxDecoration(
                    color: _CrowdColors.white,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: _CrowdColors.purple,
                            width: 2.3 * scale,
                          )
                        : null,
                    boxShadow: _softShadow(scale),
                  ),
                  child: _TimelineThumbnail(
                    icon: point.icon,
                    selected: selected,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10 * scale),
        Text(
          point.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? _CrowdColors.purple : _CrowdColors.deepPurple,
            fontSize: 13.2 * scale,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            height: 1.08,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          point.time,
          style: TextStyle(
            color: selected ? _CrowdColors.purple : _CrowdColors.textSub,
            fontSize: 15.5 * scale,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _TimelineThumbnail extends StatelessWidget {
  const _TimelineThumbnail({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? const [Color(0xFFFFF0DF), Color(0xFFE9DCFF)]
                : const [Color(0xFFE9F7FF), Color(0xFFEDE5FF)],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: _CrowdColors.purple, size: 26),
      ),
    );
  }
}

class _ArrowDot extends StatelessWidget {
  const _ArrowDot({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25 * scale,
      height: 25 * scale,
      margin: EdgeInsets.symmetric(horizontal: 5 * scale),
      decoration: BoxDecoration(
        color: _CrowdColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _CrowdColors.border),
        boxShadow: _softShadow(scale, alpha: 0.08),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: _CrowdColors.purple,
        size: 20 * scale,
      ),
    );
  }
}

class _AlertMessageCard extends StatelessWidget {
  const _AlertMessageCard({
    required this.alert,
    required this.scale,
    required this.onInfoPressed,
  });

  final CrowdAlert alert;
  final double scale;
  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 14),
      decoration: BoxDecoration(
        color: _CrowdColors.alertBg,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: _CrowdColors.alertBorder),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12 * scale),
            onTap: onInfoPressed,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 51 * scale,
                  height: 51 * scale,
                  decoration: const BoxDecoration(
                    color: _CrowdColors.alertRed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    size: 31 * scale,
                    color: _CrowdColors.white,
                  ),
                ),
                SizedBox(width: 14 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Crowd Alert',
                              style: TextStyle(
                                color: _CrowdColors.deepPurple,
                                fontSize: 28 * scale,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.info_outline_rounded,
                            color: _CrowdColors.textSub,
                            size: 19 * scale,
                          ),
                        ],
                      ),
                      SizedBox(height: 9 * scale),
                      Text(
                        alert.alertMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _CrowdColors.blackNavy,
                          fontSize: 15.7 * scale,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                        ),
                      ),
                      SizedBox(height: 5 * scale),
                      Text(
                        alert.foreignerQueueTip,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _CrowdColors.textSub,
                          fontSize: 12.8 * scale,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),
          _OriginalPlanCard(alert: alert, scale: scale),
        ],
      ),
    );
  }
}

class _OriginalPlanCard extends StatelessWidget {
  const _OriginalPlanCard({required this.alert, required this.scale});

  final CrowdAlert alert;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: _CrowdColors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: _softShadow(scale, alpha: 0.08, blur: 20, y: 8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 370;
          final image = _PlaceImagePlaceholder(
            icon: Icons.local_cafe_rounded,
            width: compact ? double.infinity : 126 * scale,
            height: compact ? 120 * scale : 112 * scale,
            radius: 10 * scale,
          );
          final details = _OriginalPlanDetails(alert: alert, scale: scale);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                image,
                SizedBox(height: 12 * scale),
                details,
              ],
            );
          }

          return Row(
            children: [
              image,
              SizedBox(width: 16 * scale),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _OriginalPlanDetails extends StatelessWidget {
  const _OriginalPlanDetails({required this.alert, required this.scale});

  final CrowdAlert alert;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112 * scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.originalPlace,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _CrowdColors.deepPurple,
              fontSize: 27 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 9 * scale),
          Text(
            alert.recommendedAction ?? 'Original stop from your itinerary',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _CrowdColors.textSub,
              fontSize: 13.8 * scale,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _AlertMetricBox(
                  icon: Icons.groups_rounded,
                  title: alert.crowdLevel,
                  subtitle: 'crowd',
                  color: _CrowdColors.alertRed,
                  scale: scale,
                ),
              ),
              SizedBox(width: 7 * scale),
              Expanded(
                child: _AlertMetricBox(
                  icon: Icons.schedule_rounded,
                  title: alert.estimatedWait,
                  subtitle: 'Est. wait',
                  color: _CrowdColors.alertRed,
                  scale: scale,
                ),
              ),
              SizedBox(width: 7 * scale),
              Expanded(
                child: _AlertMetricBox(
                  icon: Icons.schedule_outlined,
                  title: alert.scheduledTime,
                  subtitle: 'Scheduled',
                  color: _CrowdColors.textSub,
                  scale: scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertMetricBox extends StatelessWidget {
  const _AlertMetricBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.scale,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 * scale,
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: _CrowdColors.metricBg,
        borderRadius: BorderRadius.circular(9 * scale),
        border: Border.all(color: _CrowdColors.metricBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16 * scale, color: color),
                SizedBox(width: 4 * scale),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.8 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scale),
            Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 11.3 * scale,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternativesSection extends StatelessWidget {
  const _AlternativesSection({
    required this.alert,
    required this.selectedAlternative,
    required this.sourceLabel,
    required this.isGenerating,
    required this.scale,
    required this.onGenerate,
    required this.onSelectAlternative,
  });

  final CrowdAlert alert;
  final AlternativePlace? selectedAlternative;
  final String sourceLabel;
  final bool isGenerating;
  final double scale;
  final VoidCallback onGenerate;
  final ValueChanged<AlternativePlace> onSelectAlternative;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'AI alternatives ✨',
                style: TextStyle(
                  color: _CrowdColors.deepPurple,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            _AgentSourceBadge(label: sourceLabel, scale: scale),
          ],
        ),
        SizedBox(height: 4 * scale),
        Text(
          'Real-time recommendations',
          style: TextStyle(
            color: _CrowdColors.textSub,
            fontSize: 14.2 * scale,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
        ),
        SizedBox(height: 10 * scale),
        SizedBox(
          height: 44 * scale,
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('generateRetripAlternativesButton'),
            onPressed: isGenerating ? null : onGenerate,
            icon: isGenerating
                ? SizedBox(
                    width: 18 * scale,
                    height: 18 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: _CrowdColors.white,
                    ),
                  )
                : Icon(Icons.travel_explore_rounded, size: 21 * scale),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isGenerating
                    ? 'Generating...'
                    : 'Generate Re-Trip alternatives',
                style: TextStyle(
                  fontSize: 15.6 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _CrowdColors.purple,
              foregroundColor: _CrowdColors.white,
              disabledBackgroundColor: _CrowdColors.purpleDark,
              disabledForegroundColor: _CrowdColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(height: 10 * scale),
        ...alert.alternatives.map((alternative) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8 * scale),
            child: _AlternativePlaceCard(
              alternative: alternative,
              selected: selectedAlternative?.id == alternative.id,
              scale: scale,
              onSwitch: () => onSelectAlternative(alternative),
            ),
          );
        }),
      ],
    );
  }
}

class _AgentSourceBadge extends StatelessWidget {
  const _AgentSourceBadge({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isReal = label == 'KTO OpenAPI + ennoia';
    return Container(
      height: 30 * scale,
      constraints: BoxConstraints(maxWidth: 134 * scale),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isReal ? _CrowdColors.diversityBg : _CrowdColors.lavender,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReal ? _CrowdColors.diversityBorder : _CrowdColors.border,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: isReal ? _CrowdColors.green : _CrowdColors.purple,
            fontSize: 11.5 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _AlternativePlaceCard extends StatelessWidget {
  const _AlternativePlaceCard({
    required this.alternative,
    required this.selected,
    required this.scale,
    required this.onSwitch,
  });

  final AlternativePlace alternative;
  final bool selected;
  final double scale;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      constraints: BoxConstraints(minHeight: 74 * scale),
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: _CrowdColors.white,
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(
          color: selected ? _CrowdColors.purple : _CrowdColors.cardBorder,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: _softShadow(scale, alpha: selected ? 0.12 : 0.07, blur: 17),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final content = [
            _PlaceImagePlaceholder(
              icon: Icons.local_cafe_rounded,
              width: compact ? 92 * scale : 105 * scale,
              height: 56 * scale,
              radius: 8 * scale,
              imageUrl: alternative.imageUrl,
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: _AlternativeText(alternative: alternative, scale: scale),
            ),
            SizedBox(width: 8 * scale),
            _DiversityScoreBadge(
              score: alternative.diversityScore,
              scale: scale,
            ),
            SizedBox(width: 10 * scale),
            _SwitchButton(
              selected: selected,
              scale: scale,
              onPressed: onSwitch,
            ),
          ];

          return Row(children: content);
        },
      ),
    );
  }
}

class _AlternativeText extends StatelessWidget {
  const _AlternativeText({required this.alternative, required this.scale});

  final AlternativePlace alternative;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          alternative.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _CrowdColors.deepPurple,
            fontSize: 16.2 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          alternative.recommendationCopy ?? alternative.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _CrowdColors.textSub,
            fontSize: 11.8 * scale,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
        if (alternative.recommendationCopy != null &&
            alternative.recommendationCopy != alternative.description) ...[
          SizedBox(height: 5 * scale),
          Text(
            alternative.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _CrowdColors.textSub,
              fontSize: 11.2 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
        SizedBox(height: 7 * scale),
        Row(
          children: [
            Icon(
              Icons.directions_walk_rounded,
              color: _CrowdColors.purple,
              size: 16 * scale,
            ),
            SizedBox(width: 4 * scale),
            Flexible(
              child: Text(
                [
                  alternative.walkingTime,
                  alternative.crowdLevel,
                  if (alternative.contentId != null)
                    'KTO ${alternative.contentId}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _CrowdColors.purple,
                  fontSize: 12.8 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiversityScoreBadge extends StatelessWidget {
  const _DiversityScoreBadge({required this.score, required this.scale});

  final int score;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 53 * scale,
      height: 48 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _CrowdColors.diversityBg,
        borderRadius: BorderRadius.circular(9 * scale),
        border: Border.all(color: _CrowdColors.diversityBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(
              'Diversity',
              style: TextStyle(
                color: _CrowdColors.green,
                fontSize: 10.4 * scale,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            SizedBox(height: 5 * scale),
            Text(
              '$score%',
              style: TextStyle(
                color: _CrowdColors.green,
                fontSize: 17.2 * scale,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({
    required this.selected,
    required this.scale,
    required this.onPressed,
  });

  final bool selected;
  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66 * scale,
      height: 45 * scale,
      child: OutlinedButton(
        key: const ValueKey('alternativeSwitchButton'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _CrowdColors.purple,
          backgroundColor: selected
              ? _CrowdColors.lavender
              : _CrowdColors.white,
          side: BorderSide(
            color: selected ? _CrowdColors.purple : _CrowdColors.purple,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11 * scale),
          ),
          padding: EdgeInsets.zero,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            selected ? 'Selected' : 'Switch',
            style: TextStyle(
              fontSize: 14.2 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionButtons extends StatelessWidget {
  const _BottomActionButtons({
    required this.isSwitching,
    required this.scale,
    required this.onKeepOriginal,
    required this.onSwitchPlan,
  });

  final bool isSwitching;
  final double scale;
  final VoidCallback onKeepOriginal;
  final VoidCallback onSwitchPlan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52 * scale,
            child: OutlinedButton(
              key: const ValueKey('keepOriginalPlanButton'),
              onPressed: isSwitching ? null : onKeepOriginal,
              style: OutlinedButton.styleFrom(
                foregroundColor: _CrowdColors.purple,
                backgroundColor: _CrowdColors.white,
                side: const BorderSide(color: _CrowdColors.purple, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13 * scale),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Keep original plan',
                  style: TextStyle(
                    fontSize: 15.5 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 14 * scale),
        Expanded(
          child: Container(
            height: 52 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13 * scale),
              gradient: const LinearGradient(
                colors: [_CrowdColors.purple, _CrowdColors.purpleDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: _CrowdColors.purple.withValues(alpha: 0.23),
                  blurRadius: 16 * scale,
                  offset: Offset(0, 8 * scale),
                ),
              ],
            ),
            child: FilledButton(
              key: const ValueKey('switchPlanButton'),
              onPressed: isSwitching ? null : onSwitchPlan,
              style: FilledButton.styleFrom(
                foregroundColor: _CrowdColors.white,
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13 * scale),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isSwitching ? 'Updating...' : 'Switch plan',
                  style: TextStyle(
                    fontSize: 15.5 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.scale,
    required this.height,
    required this.safeBottom,
    required this.onChanged,
  });

  final int selectedIndex;
  final double scale;
  final double height;
  final double safeBottom;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      _BottomNavData('Home', Icons.home_outlined),
      _BottomNavData('Itinerary', Icons.calendar_month_rounded),
      _BottomNavData('Scan', Icons.crop_free_rounded),
      _BottomNavData('Discover', Icons.explore_outlined),
      _BottomNavData('My', Icons.person_outline_rounded),
    ];

    return Container(
      key: const ValueKey('crowdAlertBottomNavigation'),
      height: height,
      decoration: BoxDecoration(
        color: _CrowdColors.white,
        border: const Border(top: BorderSide(color: _CrowdColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: _CrowdColors.shadow.withValues(alpha: 0.12),
            blurRadius: 18 * scale,
            offset: Offset(0, -6 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 5 * scale, bottom: safeBottom),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == selectedIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                child: Column(
                  key: ValueKey(
                    selected ? 'active-nav-${item.label}' : 'nav-${item.label}',
                  ),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      width: selected ? 52 * scale : 0,
                      height: 2.5 * scale,
                      margin: EdgeInsets.only(bottom: 7 * scale),
                      decoration: BoxDecoration(
                        color: selected
                            ? _CrowdColors.purple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Icon(
                      item.icon,
                      color: selected
                          ? _CrowdColors.purple
                          : _CrowdColors.navMuted,
                      size: 27 * scale,
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: selected
                            ? _CrowdColors.purple
                            : _CrowdColors.navMuted,
                        fontSize: 11.4 * scale,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PlaceImagePlaceholder extends StatelessWidget {
  const _PlaceImagePlaceholder({
    required this.icon,
    required this.width,
    required this.height,
    required this.radius,
    this.imageUrl,
  });

  final IconData icon;
  final double width;
  final double height;
  final double radius;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF2D7), Color(0xFFE9DEFF)],
          ),
        ),
        alignment: Alignment.center,
        child: url == null || url.isEmpty
            ? Icon(icon, color: _CrowdColors.purple, size: 32)
            : Image.network(
                url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: _CrowdColors.purple, size: 32),
              ),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(),
      child: const SizedBox(height: 2, width: double.infinity),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _CrowdColors.purple
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    const dashWidth = 2.8;
    const dashGap = 6.0;

    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(math.min(startX + dashWidth, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.contain,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Nori'),
            TextSpan(
              text: 'Go',
              style: TextStyle(color: _CrowdColors.lime),
            ),
          ],
        ),
        style: TextStyle(
          color: _CrowdColors.deepPurple,
          fontSize: 44,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CrowdColors.deepPurple,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _MiniTimelinePoint {
  const _MiniTimelinePoint({
    required this.title,
    required this.time,
    required this.icon,
    this.selected = false,
  });

  final String title;
  final String time;
  final IconData icon;
  final bool selected;
}

class _BottomNavData {
  const _BottomNavData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _CrowdColors {
  const _CrowdColors._();

  static const white = Color(0xFFFFFFFF);
  static const deepPurple = Color(0xFF24104F);
  static const blackNavy = Color(0xFF111333);
  static const textSub = Color(0xFF60667F);
  static const navMuted = Color(0xFF757B93);

  static const purple = Color(0xFF6A00FF);
  static const purpleDark = Color(0xFF4A12E6);
  static const lime = Color(0xFFCCFF00);

  static const alertRed = Color(0xFFFF3B3B);
  static const alertBg = Color(0xFFFFF1F1);
  static const alertBorder = Color(0xFFFFD9D9);

  static const cardBorder = Color(0xFFE8EBF4);
  static const border = Color(0xFFDDE1EE);
  static const shadow = Color(0xFF6F668D);

  static const lavender = Color(0xFFF3EDFF);
  static const metricBg = Color(0xFFFFFAFA);
  static const metricBorder = Color(0xFFF3E2E2);

  static const green = Color(0xFF139528);
  static const diversityBg = Color(0xFFEFF9EB);
  static const diversityBorder = Color(0xFFDDEFD7);
}

List<BoxShadow> _softShadow(
  double scale, {
  double alpha = 0.1,
  double blur = 12,
  double y = 5,
}) {
  return [
    BoxShadow(
      color: _CrowdColors.shadow.withValues(alpha: alpha),
      blurRadius: blur * scale,
      offset: Offset(0, y * scale),
    ),
  ];
}
