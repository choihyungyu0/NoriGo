import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/features/itinerary/application/itinerary_session_store.dart';
import 'package:norigo/features/itinerary/data/mock_itinerary_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';

const _sceneAsset = 'assets/images/itinerary/itinerary_header_bg.png';
const _itineraryRoute = '/itinerary/planner';
const _step3AlternativesRoute = '/step3/alternatives';
const _step3UpdatedItineraryRoute = '/step3/updated-itinerary';
const _step3OriginalItemId = 'bukchon-hanok-village';

void _emptyCallback() {}

const _step3AlternativeOptions = [
  _Step3AlternativeOption(
    place: AlternativePlace(
      id: 'cheongun-hanok-cafe',
      name: '청운 한옥 카페',
      description: '한옥에서 전통차를 즐길 수 있는 조용한 카페입니다.',
      walkingTime: '도보 8분',
      diversityScore: 92,
      crowdLevel: 'Low',
      imageAssetPath: 'assets/images/discover/spot_garden_cafe.png',
      recommendationCopy: '한옥에서 전통차를 즐기며 혼잡한 북촌 동선을 피할 수 있어요.',
    ),
    category: '쉼',
    crowdLabel: '혼잡도 20%',
    englishName: 'Cheongun Hanok Cafe',
    icon: Icons.local_cafe_rounded,
  ),
  _Step3AlternativeOption(
    place: AlternativePlace(
      id: 'national-palace-museum',
      name: '국립고궁박물관',
      description: '조선 왕실의 유물을 전시한 실내 박물관입니다.',
      walkingTime: '도보 12분',
      diversityScore: 88,
      crowdLevel: 'Low',
      imageAssetPath: 'assets/images/discover/spot_bookstore.png',
      recommendationCopy: '실내 전시라 이동 피로가 적고, 같은 역사 문화권 안에서 일정을 이어갈 수 있어요.',
    ),
    category: '역사/문화',
    crowdLabel: '혼잡도 15%',
    englishName: 'National Palace Museum',
    icon: Icons.account_balance_rounded,
  ),
  _Step3AlternativeOption(
    place: AlternativePlace(
      id: 'gyedong-book-cafe-street',
      name: '계동길 북카페거리',
      description: '아기자기한 북카페들이 모인 한적한 거리입니다.',
      walkingTime: '도보 10분',
      diversityScore: 90,
      crowdLevel: 'Low',
      imageAssetPath: 'assets/images/discover/spot_bookstore.png',
      recommendationCopy: '작은 북카페가 이어져 있어 쉬어가기 좋고, 골목 분위기는 그대로 느낄 수 있어요.',
    ),
    category: '카페',
    crowdLabel: '혼잡도 25%',
    englishName: 'Gyedong-gil Book Cafe Street',
    icon: Icons.menu_book_rounded,
  ),
];

class _Step3AlternativeOption {
  const _Step3AlternativeOption({
    required this.place,
    required this.category,
    required this.crowdLabel,
    required this.englishName,
    required this.icon,
  });

  final AlternativePlace place;
  final String category;
  final String crowdLabel;
  final String englishName;
  final IconData icon;
}

AlternativePlace _selectedStep3AlternativeFrom(BuildContext context) {
  final arguments = ModalRoute.of(context)?.settings.arguments;
  if (arguments is AlternativePlace) return arguments;
  return _step3AlternativeOptions[1].place;
}

_Step3AlternativeOption _step3OptionFor(AlternativePlace alternative) {
  for (final option in _step3AlternativeOptions) {
    if (option.place.id == alternative.id ||
        option.place.name == alternative.name) {
      return option;
    }
  }
  return _Step3AlternativeOption(
    place: alternative,
    category: '대안',
    crowdLabel: alternative.crowdLevel.toLowerCase().contains('low')
        ? '혼잡도 낮음'
        : alternative.crowdLevel,
    englishName: alternative.description,
    icon: Icons.place_rounded,
  );
}

void _replaceStep3ItineraryItem(AlternativePlace alternative) {
  if (ItinerarySessionStore.currentPlan == null) {
    ItinerarySessionStore.savePlan(MockItineraryRepository.mockPlan);
  }

  final originalItemId = _findStep3OriginalItemId() ?? _step3OriginalItemId;
  ItinerarySessionStore.replaceItem(
    originalItemId: originalItemId,
    alternative: alternative,
  );
}

String? _findStep3OriginalItemId() {
  final plan = ItinerarySessionStore.currentPlan;
  if (plan == null || plan.items.isEmpty) return null;

  for (final item in plan.items) {
    final normalized = '${item.id} ${item.placeName}'.toLowerCase();
    if (normalized.contains('bukchon') || normalized.contains('북촌')) {
      return item.id;
    }
  }

  if (plan.items.length > 1) return plan.items[1].id;
  return plan.items.first.id;
}

class Step3MobileMockupsScreen extends StatelessWidget {
  const Step3MobileMockupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _MockupColors.white,
      ),
      child: const Scaffold(
        backgroundColor: _MockupColors.white,
        body: Step3MobileMockupsView(),
      ),
    );
  }
}

class Step3MobileMockupsView extends StatelessWidget {
  const Step3MobileMockupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: _MockupGallery());
  }
}

class Step3CrowdAlertScreen extends StatelessWidget {
  const Step3CrowdAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Step3FlowScaffold(
      child: _CrowdAlertPhone(
        framed: false,
        onViewAlternatives: () =>
            Navigator.of(context).pushNamed(_step3AlternativesRoute),
        onKeepOriginal: () =>
            Navigator.of(context).pushReplacementNamed(_itineraryRoute),
      ),
    );
  }
}

class Step3AlternativePlacesScreen extends StatelessWidget {
  const Step3AlternativePlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Step3FlowScaffold(
      child: _AlternativePlacesPhone(
        framed: false,
        onAlternativeSelected: (alternative) {
          _replaceStep3ItineraryItem(alternative);
          Navigator.of(
            context,
          ).pushNamed(_step3UpdatedItineraryRoute, arguments: alternative);
        },
      ),
    );
  }
}

class Step3UpdatedItineraryScreen extends StatelessWidget {
  const Step3UpdatedItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedAlternative = _selectedStep3AlternativeFrom(context);

    return _Step3FlowScaffold(
      child: _UpdatedItineraryPhone(
        framed: false,
        selectedAlternative: selectedAlternative,
        onStartGuide: () =>
            Navigator.of(context).pushReplacementNamed(_itineraryRoute),
      ),
    );
  }
}

class _Step3FlowScaffold extends StatelessWidget {
  const _Step3FlowScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _MockupColors.white,
      ),
      child: Scaffold(
        backgroundColor: _MockupColors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageWidth = math.min(constraints.maxWidth, 430.0);

              return Center(
                child: SizedBox(
                  width: pageWidth,
                  height: constraints.maxHeight,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MockupGallery extends StatelessWidget {
  const _MockupGallery();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 1180).clamp(0.88, 1.0);
        const phoneWidth = 328.0;
        final contentWidth = phoneWidth * 3 + 86 * 2;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 720 ? 34 : 18,
            vertical: 28,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PhoneMockupStage(
                        number: 1,
                        phone: _CrowdAlertPhone(),
                        notes: [
                          '수동 트리거: 사용자가 피로, 혼잡, 비가 와 등 입력',
                          '자동 트리거: 혼잡도/날씨 데이터 감지 후 알림 표시',
                        ],
                      ),
                      _MockupArrow(),
                      _PhoneMockupStage(
                        number: 2,
                        phone: _AlternativePlacesPhone(),
                        notes: [
                          '원래 장소의 핵심 가치(문화/체험)를 유지한 대안 분석',
                          '거리, 소요시간, 혼잡도 등을 함께 제공',
                        ],
                      ),
                      _MockupArrow(),
                      _PhoneMockupStage(
                        number: 3,
                        phone: _UpdatedItineraryPhone(),
                        notes: [
                          '선택 즉시 일정이 변경되고 지도에 반영',
                          '새로운 경로의 이동 시간 재계산 후 안내 시작',
                        ],
                      ),
                    ],
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

class _PhoneMockupStage extends StatelessWidget {
  const _PhoneMockupStage({
    required this.number,
    required this.phone,
    required this.notes,
  });

  final int number;
  final Widget phone;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 328,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              phone,
              Positioned(left: -15, top: 38, child: _StepBadge(number: number)),
            ],
          ),
          const SizedBox(height: 16),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '+ $note',
                style: const TextStyle(
                  color: _MockupColors.hotPink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockupArrow extends StatelessWidget {
  const _MockupArrow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 86,
      height: 676,
      child: Center(
        child: Icon(
          Icons.chevron_right_rounded,
          color: _MockupColors.hotPink,
          size: 44,
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _MockupColors.hotPink,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _MockupColors.hotPink.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: _MockupColors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 328,
      height: 676,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: _MockupColors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: _MockupColors.phoneBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: _MockupColors.navy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: ColoredBox(color: _MockupColors.white, child: child),
      ),
    );
  }
}

class _PhoneStatusBar extends StatelessWidget {
  const _PhoneStatusBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(9, 2, 8, 0),
      child: SizedBox(
        height: 23,
        child: Row(
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: _MockupColors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            Spacer(),
            Icon(
              Icons.signal_cellular_alt,
              size: 15,
              color: _MockupColors.black,
            ),
            SizedBox(width: 3),
            Icon(Icons.wifi, size: 15, color: _MockupColors.black),
            SizedBox(width: 3),
            Icon(Icons.battery_full, size: 16, color: _MockupColors.black),
          ],
        ),
      ),
    );
  }
}

class _CrowdAlertPhone extends StatelessWidget {
  const _CrowdAlertPhone({
    this.framed = true,
    this.onViewAlternatives,
    this.onKeepOriginal,
  });

  final bool framed;
  final VoidCallback? onViewAlternatives;
  final VoidCallback? onKeepOriginal;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      child: Column(
        children: [
          if (framed) ...[const _PhoneStatusBar(), const SizedBox(height: 17)],
          const Text(
            '혼잡도 알림',
            style: TextStyle(
              color: _MockupColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 38),
          const _WarningMark(),
          const SizedBox(height: 26),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                Text(
                  '북촌 한옥마을이 매우 혼잡해요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _MockupColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '현재 방문객이 많아 이동이 불편할 수 있어요.\n다른 일정을 추천해 드릴까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _MockupColors.bodyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _BukchonImageCard(),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                _PinkButton(
                  label: '대안 장소 보기',
                  onPressed: onViewAlternatives ?? _emptyCallback,
                ),
                const SizedBox(height: 12),
                _OutlineButton(
                  label: '일정 그대로 유지',
                  onPressed: onKeepOriginal ?? _emptyCallback,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return framed ? _PhoneFrame(child: content) : content;
  }
}

class _WarningMark extends StatelessWidget {
  const _WarningMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _MockupColors.hotPink,
        shape: BoxShape.circle,
        border: Border.all(
          color: _MockupColors.hotPink.withValues(alpha: 0.22),
          width: 8,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.warning_rounded,
            color: _MockupColors.white,
            size: 76,
          ),
          Positioned(
            top: 30,
            child: Container(
              width: 8,
              height: 31,
              decoration: BoxDecoration(
                color: _MockupColors.hotPink,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 23,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _MockupColors.hotPink,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BukchonImageCard extends StatelessWidget {
  const _BukchonImageCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _sceneAsset,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) =>
                  const _PhotoFallback(icon: Icons.holiday_village_rounded),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _MockupColors.black.withValues(alpha: 0.74),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 15,
              right: 12,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '북촌 한옥마을',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _MockupColors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bukchon Hanok Village',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _MockupColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CrowdBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrowdBadge extends StatelessWidget {
  const _CrowdBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: _MockupColors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, color: _MockupColors.hotPink, size: 14),
          SizedBox(width: 3),
          Text(
            '혼잡도 95%',
            style: TextStyle(
              color: _MockupColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativePlacesPhone extends StatelessWidget {
  const _AlternativePlacesPhone({
    this.framed = true,
    this.onAlternativeSelected,
  });

  final bool framed;
  final ValueChanged<AlternativePlace>? onAlternativeSelected;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Column(
        children: [
          if (framed) ...[const _PhoneStatusBar(), const SizedBox(height: 17)],
          const Text(
            '대안 장소 추천',
            style: TextStyle(
              color: _MockupColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            '북촌 한옥마을 대신 추천해요',
            style: TextStyle(
              color: _MockupColors.bodyText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                for (final option in _step3AlternativeOptions) ...[
                  _AlternativeCard(
                    option: option,
                    onPressed: () => onAlternativeSelected?.call(option.place),
                  ),
                  if (option != _step3AlternativeOptions.last)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return framed ? _PhoneFrame(child: content) : content;
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.option, required this.onPressed});

  final _Step3AlternativeOption option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final place = option.place;

    return Container(
      decoration: BoxDecoration(
        color: _MockupColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MockupColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: _MockupColors.navy.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallPlacePhoto(option: option),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _MockupColors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          const _GreenTag(label: '조용해요'),
                          _GreenTag(label: option.category),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        place.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _MockupColors.bodyText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          _MetricText(
                            icon: Icons.directions_walk_rounded,
                            label: place.walkingTime,
                          ),
                          const SizedBox(width: 10),
                          _MetricText(
                            icon: Icons.groups_rounded,
                            label: option.crowdLabel,
                            green: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 41,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_MockupColors.purple, _MockupColors.purpleDark],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: _MockupColors.white,
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                ),
                child: const Text(
                  '이 장소로 변경',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPlacePhoto extends StatelessWidget {
  const _SmallPlacePhoto({required this.option});

  final _Step3AlternativeOption option;

  @override
  Widget build(BuildContext context) {
    final assetPath = option.place.imageAssetPath;
    final imageUrl = option.place.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 97,
        height: 97,
        child: assetPath != null
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _PhotoFallback(icon: option.icon),
              )
            : imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _PhotoFallback(icon: option.icon),
              )
            : _PhotoFallback(icon: option.icon),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFFE9F9E6), Color(0xFFD9EEFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PhotoTexturePainter())),
          Center(
            child: Icon(
              icon,
              color: _MockupColors.white.withValues(alpha: 0.90),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenTag extends StatelessWidget {
  const _GreenTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _MockupColors.mint,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _MockupColors.green,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({
    required this.icon,
    required this.label,
    this.green = false,
  });

  final IconData icon;
  final String label;
  final bool green;

  @override
  Widget build(BuildContext context) {
    final color = green ? _MockupColors.green : _MockupColors.bodyText;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatedItineraryPhone extends StatelessWidget {
  const _UpdatedItineraryPhone({
    this.framed = true,
    this.selectedAlternative,
    this.onStartGuide,
  });

  final bool framed;
  final AlternativePlace? selectedAlternative;
  final VoidCallback? onStartGuide;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      child: Column(
        children: [
          if (framed) ...[const _PhoneStatusBar(), const SizedBox(height: 17)],
          const Text(
            '일정이 변경되었어요!',
            style: TextStyle(
              color: _MockupColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 25),
          const _CelebrationMark(),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _UpdatedTimeline(selectedAlternative: selectedAlternative),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _PinkButton(
              label: '변경된 경로로 안내 시작',
              onPressed: onStartGuide ?? _emptyCallback,
            ),
          ),
        ],
      ),
    );

    return framed ? _PhoneFrame(child: content) : content;
  }
}

class _CelebrationMark extends StatelessWidget {
  const _CelebrationMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 4,
            top: 7,
            child: _Confetti(color: Color(0xFF22A66F), angle: -0.5),
          ),
          const Positioned(
            right: 3,
            top: 15,
            child: _Confetti(color: Color(0xFFFFB300), angle: 0.35),
          ),
          const Positioned(
            left: 20,
            bottom: 8,
            child: _Confetti(color: Color(0xFF7B4DFF), angle: 0.7),
          ),
          const Positioned(
            right: 20,
            bottom: 5,
            child: _Confetti(color: Color(0xFFFF4F88), angle: -0.7),
          ),
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4A8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _MockupColors.hotPink.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Color(0xFFFF8A00),
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti({required this.color, required this.angle});

  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 5,
        height: 13,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _UpdatedTimeline extends StatelessWidget {
  const _UpdatedTimeline({required this.selectedAlternative});

  final AlternativePlace? selectedAlternative;

  @override
  Widget build(BuildContext context) {
    final alternative =
        selectedAlternative ?? _step3AlternativeOptions[1].place;
    final option = _step3OptionFor(alternative);
    final items = [
      const _TimelineItemData(
        time: '09:00',
        title: '경복궁',
        subtitle: 'Gyeongbokgung Palace',
        completed: true,
      ),
      _TimelineItemData(
        time: '11:00',
        title: alternative.name,
        subtitle: option.englishName,
        active: true,
      ),
      const _TimelineItemData(
        time: '13:00',
        title: '디저트 카페',
        subtitle: 'Dessert Cafe',
      ),
      const _TimelineItemData(
        time: '15:00',
        title: '성수 셀렉트숍',
        subtitle: 'Seongsu Select Shop',
      ),
      const _TimelineItemData(
        time: '18:30',
        title: 'N서울타워',
        subtitle: 'N Seoul Tower',
      ),
    ];

    return Stack(
      children: [
        Positioned(
          left: 9,
          top: 15,
          bottom: 23,
          child: Container(width: 2, color: _MockupColors.timelineLine),
        ),
        Column(
          children: items
              .map(
                (item) => SizedBox(
                  height: item.active ? 96 : 60,
                  child: _TimelineRow(data: item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.data});

  final _TimelineItemData data;

  @override
  Widget build(BuildContext context) {
    final dotColor = data.active ? _MockupColors.green : _MockupColors.purple;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              data.time,
              style: TextStyle(
                color: data.active ? _MockupColors.green : _MockupColors.purple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
        Expanded(
          child: data.active
              ? _ActiveTimelineCard(data: data)
              : _PlainTimelineText(data: data),
        ),
      ],
    );
  }
}

class _PlainTimelineText extends StatelessWidget {
  const _PlainTimelineText({required this.data});

  final _TimelineItemData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _MockupColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _MockupColors.bodyText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (data.completed) const _DoneChip(),
        ],
      ),
    );
  }
}

class _ActiveTimelineCard extends StatelessWidget {
  const _ActiveTimelineCard({required this.data});

  final _TimelineItemData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      decoration: BoxDecoration(
        color: _MockupColors.greenPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MockupColors.greenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _MockupColors.greenDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _MockupColors.greenDark,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 9),
          const _ChangedChip(),
        ],
      ),
    );
  }
}

class _DoneChip extends StatelessWidget {
  const _DoneChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFECECF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '완료',
        style: TextStyle(
          color: _MockupColors.bodyText,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ChangedChip extends StatelessWidget {
  const _ChangedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _MockupColors.mint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '변경됨',
        style: TextStyle(
          color: _MockupColors.green,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _PinkButton extends StatelessWidget {
  const _PinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_MockupColors.hotPink, _MockupColors.hotPinkDark],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: _MockupColors.hotPink.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: _MockupColors.white,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _MockupColors.navy,
          side: const BorderSide(color: _MockupColors.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PhotoTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..color = _MockupColors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.4;
    final darkPaint = Paint()
      ..color = _MockupColors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.1;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.18 + i * 0.16);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 12), lightPaint);
    }

    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.15 + i * 0.23);
      canvas.drawLine(Offset(x, 0), Offset(x + 14, size.height), darkPaint);
    }

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.24),
      size.width * 0.18,
      Paint()..color = _MockupColors.white.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimelineItemData {
  const _TimelineItemData({
    required this.time,
    required this.title,
    required this.subtitle,
    this.completed = false,
    this.active = false,
  });

  final String time;
  final String title;
  final String subtitle;
  final bool completed;
  final bool active;
}

class _MockupColors {
  const _MockupColors._();

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF111226);
  static const navy = Color(0xFF242D52);
  static const bodyText = Color(0xFF4E5878);
  static const phoneBorder = Color(0xFFE6E5EF);
  static const cardBorder = Color(0xFFE8EAF2);
  static const outline = Color(0xFFB9BED0);
  static const timelineLine = Color(0xFFE7E8F0);

  static const hotPink = Color(0xFFFF1E5B);
  static const hotPinkDark = Color(0xFFE8124F);
  static const purple = Color(0xFF7356F1);
  static const purpleDark = Color(0xFF5B3BE4);

  static const mint = Color(0xFFE5F8EF);
  static const green = Color(0xFF21A15D);
  static const greenDark = Color(0xFF0C7436);
  static const greenPale = Color(0xFFEFF9EF);
  static const greenBorder = Color(0xFFDDF0DF);
}
