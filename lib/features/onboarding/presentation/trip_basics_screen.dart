import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/features/onboarding/domain/trip_basics.dart';

const _logoAsset = 'assets/images/splash/norigo_logo_full.png';
const _headerAsset = 'assets/images/onboarding/trip_basics_header.png';

class TripBasicsScreen extends StatefulWidget {
  const TripBasicsScreen({
    super.key,
    this.logoAsset = _logoAsset,
    this.headerAsset = _headerAsset,
  });

  final String logoAsset;
  final String headerAsset;

  @override
  State<TripBasicsScreen> createState() => _TripBasicsScreenState();
}

class _TripBasicsScreenState extends State<TripBasicsScreen> {
  TripBasics _basics = const TripBasics();

  static const _languages = ['English', '日本語', '中文', 'Français'];
  static const _purposes = ['Sightseeing', 'Food', 'Cafe', 'Culture'];
  static const _companions = ['Solo', 'Friends', 'Family', 'Couple'];
  static const _foodNeeds = ['None', 'Halal', 'Vegetarian', 'Allergy'];

  void _update(TripBasics basics) {
    setState(() {
      _basics = basics;
    });
  }

  void _changeTripLength(int delta) {
    final nextDays = (_basics.tripLengthDays + delta).clamp(1, 30);
    _update(_basics.copyWith(tripLengthDays: nextDays));
  }

  void _continue() {
    if (AppRouter.routes.containsKey(AppRoutes.interests)) {
      Navigator.of(context).pushNamed(AppRoutes.interests, arguments: _basics);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Trip basics saved. Interests screen will be added next.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _TripColors.white,
      ),
      child: Scaffold(
        backgroundColor: _TripColors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final viewportHeight = constraints.maxHeight;
              final pageWidth = math.min(viewportWidth, 560.0);
              final scale = (pageWidth / 430.0).clamp(0.86, 1.08);
              final compact = pageWidth < 430;

              return Center(
                child: SizedBox(
                  width: pageWidth,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          18 * scale,
                          18 * scale,
                          18 * scale,
                          96 * scale,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: viewportHeight - 114 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _OnboardingHeader(
                                logoAsset: widget.logoAsset,
                                headerAsset: widget.headerAsset,
                                scale: scale,
                              ),
                              SizedBox(height: 16 * scale),
                              _SectionCard(
                                icon: Icons.translate_rounded,
                                title: '1. Preferred language',
                                child: _ChipRow(
                                  group: 'language',
                                  values: _languages,
                                  selected: _basics.preferredLanguage,
                                  onSelected: (value) {
                                    _update(
                                      _basics.copyWith(
                                        preferredLanguage: value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 12 * scale),
                              _SectionCard(
                                icon: Icons.location_on_rounded,
                                title: '2. Destination',
                                child: DropdownButtonFormField<String>(
                                  initialValue: _basics.destination,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'South Korea',
                                      child: Text('South Korea'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    _update(
                                      _basics.copyWith(destination: value),
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12 * scale),
                              _SectionCard(
                                icon: Icons.groups_rounded,
                                title: '3. First visit?',
                                child: _ChipRow(
                                  group: 'firstVisit',
                                  values: const ['Yes', 'No'],
                                  selected: _basics.isFirstVisit ? 'Yes' : 'No',
                                  onSelected: (value) {
                                    _update(
                                      _basics.copyWith(
                                        isFirstVisit: value == 'Yes',
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 12 * scale),
                              _SectionCard(
                                icon: Icons.card_travel_rounded,
                                title: '4. Main purpose',
                                child: _ChipRow(
                                  group: 'purpose',
                                  values: _purposes,
                                  selected: _basics.mainPurpose,
                                  icons: const {
                                    'Sightseeing': Icons.camera_alt_outlined,
                                    'Food': Icons.restaurant_rounded,
                                    'Cafe': Icons.local_cafe_outlined,
                                    'Culture': Icons.account_balance_outlined,
                                  },
                                  onSelected: (value) {
                                    _update(
                                      _basics.copyWith(mainPurpose: value),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 12 * scale),
                              _ResponsivePair(
                                compact: compact,
                                left: _SectionCard(
                                  icon: Icons.calendar_month_rounded,
                                  title: '5. Trip length',
                                  child: _TripLengthStepper(
                                    days: _basics.tripLengthDays,
                                    onMinus: () => _changeTripLength(-1),
                                    onPlus: () => _changeTripLength(1),
                                  ),
                                ),
                                right: _SectionCard(
                                  icon: Icons.groups_rounded,
                                  title: '6. Need queue help?',
                                  child: _QueueHelpToggle(
                                    value: _basics.needQueueHelp,
                                    onChanged: (value) {
                                      _update(
                                        _basics.copyWith(needQueueHelp: value),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 12 * scale),
                              _SectionCard(
                                icon: Icons.groups_rounded,
                                title: '7. Who are you traveling with?',
                                child: _ChipRow(
                                  group: 'companion',
                                  values: _companions,
                                  selected: _basics.companionType,
                                  icons: const {
                                    'Solo': Icons.person_outline_rounded,
                                    'Friends': Icons.people_outline_rounded,
                                    'Family': Icons.family_restroom_rounded,
                                    'Couple': Icons.favorite_border_rounded,
                                  },
                                  onSelected: (value) {
                                    _update(
                                      _basics.copyWith(companionType: value),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 12 * scale),
                              _SectionCard(
                                icon: Icons.restaurant_menu_rounded,
                                title: '8. Food needs',
                                child: _ChipRow(
                                  group: 'food',
                                  values: _foodNeeds,
                                  selected: _basics.foodNeed,
                                  icons: const {
                                    'None': Icons.check_circle_outline_rounded,
                                    'Halal': Icons.nightlight_round,
                                    'Vegetarian': Icons.eco_outlined,
                                    'Allergy': Icons.warning_amber_rounded,
                                  },
                                  onSelected: (value) {
                                    _update(_basics.copyWith(foodNeed: value));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18 * scale,
                        right: 18 * scale,
                        bottom: 12 * scale,
                        child: _PrimaryButton(onPressed: _continue),
                      ),
                    ],
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

class _TripColors {
  const _TripColors._();

  static const white = Color(0xFFFFFFFF);
  static const purple = Color(0xFF6A00FF);
  static const purpleDark = Color(0xFF4A12E6);
  static const deepPurple = Color(0xFF24104F);
  static const lime = Color(0xFFCCFF00);
  static const lavender = Color(0xFFF3EDFF);
  static const border = Color(0xFFE5E1EE);
  static const mutedText = Color(0xFF5D567A);
  static const shadow = Color(0xFF7B69A5);
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.logoAsset,
    required this.headerAsset,
    required this.scale,
  });

  final String logoAsset;
  final String headerAsset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _Logo(asset: logoAsset, scale: scale),
          ),
          Positioned(right: 0, top: 0, child: _ProgressPill(scale: scale)),
          Positioned(
            right: -10 * scale,
            bottom: 0,
            width: 250 * scale,
            height: 180 * scale,
            child: Image.asset(
              headerAsset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, _, _) => const _HeaderImageFallback(),
            ),
          ),
          Positioned(
            left: 0,
            right: 150 * scale,
            bottom: 22 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Basics',
                  style: TextStyle(
                    color: _TripColors.deepPurple,
                    fontSize: 38 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: 14 * scale),
                Text(
                  'Set up your trip for smarter recommendations.',
                  style: TextStyle(
                    color: _TripColors.mutedText,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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

class _Logo extends StatelessWidget {
  const _Logo({required this.asset, required this.scale});

  final String asset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 158 * scale,
      height: 64 * scale,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (_, _, _) => const _LogoFallback(),
      ),
    );
  }
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
              style: TextStyle(color: _TripColors.lime),
            ),
          ],
        ),
        style: TextStyle(
          color: _TripColors.deepPurple,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _HeaderImageFallback extends StatelessWidget {
  const _HeaderImageFallback();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: 160,
        height: 160,
        decoration: const BoxDecoration(
          color: _TripColors.lavender,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.location_on_rounded,
          color: _TripColors.purple,
          size: 68,
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78 * scale,
      child: Column(
        children: [
          Container(
            height: 32 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _TripColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _TripColors.border),
              boxShadow: [
                BoxShadow(
                  color: _TripColors.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '1',
                    style: TextStyle(
                      color: _TripColors.purple,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: '  /  '),
                  const TextSpan(text: '2'),
                ],
              ),
              style: TextStyle(
                color: _TripColors.mutedText,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _TripColors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _TripColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.compact,
    required this.left,
    required this.right,
  });

  final bool compact;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(children: [left, const SizedBox(height: 12), right]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _TripColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TripColors.border),
        boxShadow: [
          BoxShadow(
            color: _TripColors.shadow.withValues(alpha: 0.075),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _TripColors.purple, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _TripColors.deepPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.group,
    required this.values,
    required this.selected,
    required this.onSelected,
    this.icons = const {},
  });

  final String group;
  final List<String> values;
  final String selected;
  final Map<String, IconData> icons;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((value) {
        return _SelectableChip(
          group: group,
          label: value,
          icon: icons[value],
          selected: selected == value,
          onTap: () => onSelected(value),
        );
      }).toList(),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.group,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String group;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(selected ? 'selected-$group-$label' : 'chip-$group-$label'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 44, minWidth: 84),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: selected
              ? const LinearGradient(
                  colors: [_TripColors.purple, _TripColors.purpleDark],
                )
              : null,
          color: selected ? null : _TripColors.white,
          border: Border.all(
            color: selected ? Colors.transparent : _TripColors.border,
            width: 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _TripColors.purple.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: selected ? _TripColors.white : _TripColors.mutedText,
                size: 18,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? _TripColors.white : _TripColors.deepPurple,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripLengthStepper extends StatelessWidget {
  const _TripLengthStepper({
    required this.days,
    required this.onMinus,
    required this.onPlus,
  });

  final int days;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _TripColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TripColors.border),
      ),
      child: Row(
        children: [
          _CounterButton(
            key: const ValueKey('tripLengthMinus'),
            icon: Icons.remove_rounded,
            onPressed: onMinus,
          ),
          const VerticalDivider(width: 1, color: _TripColors.border),
          Expanded(
            child: Center(
              child: Text(
                '$days days',
                style: const TextStyle(
                  color: _TripColors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: _TripColors.border),
          _CounterButton(
            key: const ValueKey('tripLengthPlus'),
            icon: Icons.add_rounded,
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: double.infinity,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: _TripColors.purple,
        tooltip: icon == Icons.add_rounded ? 'Add day' : 'Remove day',
      ),
    );
  }
}

class _QueueHelpToggle extends StatelessWidget {
  const _QueueHelpToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Get tips to skip the lines',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _TripColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Switch(
          key: const ValueKey('queueHelpSwitch'),
          value: value,
          activeThumbColor: _TripColors.white,
          activeTrackColor: _TripColors.purple,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [_TripColors.purple, _TripColors.purpleDark],
          ),
          boxShadow: [
            BoxShadow(
              color: _TripColors.purple.withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          key: const ValueKey('tripBasicsNextButton'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '✨ Next',
            style: TextStyle(
              color: _TripColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
