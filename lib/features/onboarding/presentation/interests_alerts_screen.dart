import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
import 'package:norigo/features/onboarding/application/onboarding_preferences_store.dart';
import 'package:norigo/features/onboarding/domain/interests_alerts.dart';

const _logoAsset = 'assets/images/splash/norigo_logo_full.png';
const _readyPenguinAsset =
    'assets/images/onboarding/onboarding_ready_penguin.png';

class InterestsAlertsScreen extends StatefulWidget {
  const InterestsAlertsScreen({
    super.key,
    this.logoAsset = _logoAsset,
    this.readyPenguinAsset = _readyPenguinAsset,
  });

  final String logoAsset;
  final String readyPenguinAsset;

  @override
  State<InterestsAlertsScreen> createState() => _InterestsAlertsScreenState();
}

class _InterestsAlertsScreenState extends State<InterestsAlertsScreen> {
  InterestsAlerts _settings = const InterestsAlerts();

  static const _interests = [
    _InterestOption('Food', '🍜'),
    _InterestOption('Dessert', '🍰'),
    _InterestOption('Hanok', '🏯'),
    _InterestOption('Traditional market', '🏪'),
    _InterestOption('K-drama', '🎬'),
    _InterestOption('Night view', '🌉'),
    _InterestOption('Shopping', '🛍️'),
    _InterestOption('Photo spot', '📷'),
  ];

  void _toggleInterest(String interest) {
    final nextInterests = Set<String>.of(_settings.selectedInterests);

    if (nextInterests.contains(interest)) {
      if (nextInterests.length == 1) {
        _showSnackBar(context.l10n.selectAtLeastOneInterest);
        return;
      }
      nextInterests.remove(interest);
    } else {
      nextInterests.add(interest);
    }

    setState(() {
      _settings = _settings.copyWith(selectedInterests: nextInterests);
    });
  }

  void _update(InterestsAlerts settings) {
    setState(() {
      _settings = settings;
    });
  }

  void _requestEssentialAccess() {
    _update(_settings.copyWith(essentialAccessRequested: true));
    _showSnackBar(context.l10n.permissionFlowPending);
  }

  void _updateToggle(String label, bool value) {
    switch (label) {
      case 'Real-time crowd alerts':
        _update(_settings.copyWith(realTimeCrowdAlerts: value));
        return;
      case 'AI rerouting':
        _update(_settings.copyWith(aiRerouting: value));
        return;
      case 'Cultural scan guide':
        _update(_settings.copyWith(culturalScanGuide: value));
        return;
      case 'Audio guide':
        _update(_settings.copyWith(audioGuide: value));
        return;
      case 'Wait-time & reservation help':
        _update(_settings.copyWith(waitTimeReservationHelp: value));
        return;
    }
  }

  void _finishSetup() {
    OnboardingPreferencesStore.saveInterestsAlerts(_settings);
    if (AppRouter.routes.containsKey(AppRoutes.dataLocationConsent)) {
      try {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.dataLocationConsent,
          (route) => false,
          arguments: OnboardingPreferencesStore.itineraryRequest(),
        );
        return;
      } on FlutterError {
        _showSnackBar(context.l10n.setupCompletePending);
        return;
      }
    }

    _showSnackBar(context.l10n.setupCompletePending);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _AlertColors.white,
      ),
      child: Scaffold(
        backgroundColor: _AlertColors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageWidth = math.min(constraints.maxWidth, 560.0);
              final scale = (pageWidth / 430.0).clamp(0.86, 1.06);

              return Center(
                child: SizedBox(
                  width: pageWidth,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20 * scale,
                          18 * scale,
                          20 * scale,
                          96 * scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OnboardingStepHeader(
                              logoAsset: widget.logoAsset,
                              scale: scale,
                            ),
                            SizedBox(height: 18 * scale),
                            Text(
                              context.l10n.interestsAlerts,
                              style: TextStyle(
                                color: _AlertColors.deepPurple,
                                fontSize: 34 * scale,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              context.l10n.personalizeExperience,
                              style: TextStyle(
                                color: _AlertColors.mutedText,
                                fontSize: 17 * scale,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 22 * scale),
                            _SectionTitle(context.l10n.selectYourInterests),
                            SizedBox(height: 10 * scale),
                            _InterestsGrid(
                              interests: _interests,
                              selectedInterests: _settings.selectedInterests,
                              onToggle: _toggleInterest,
                            ),
                            SizedBox(height: 24 * scale),
                            _SectionTitle(context.l10n.crowdPreference),
                            SizedBox(height: 8 * scale),
                            _CrowdPreferenceSlider(
                              value: _settings.crowdPreference,
                              onChanged: (value) {
                                _update(
                                  _settings.copyWith(crowdPreference: value),
                                );
                              },
                            ),
                            SizedBox(height: 18 * scale),
                            _ToggleSettingsCard(
                              settings: _settings,
                              onChanged: _updateToggle,
                            ),
                            SizedBox(height: 14 * scale),
                            _EssentialAccessCard(
                              onEnableAccess: _requestEssentialAccess,
                            ),
                            SizedBox(height: 14 * scale),
                            _ReadyCard(asset: widget.readyPenguinAsset),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20 * scale,
                        right: 20 * scale,
                        bottom: 12 * scale,
                        child: _FinishButton(onPressed: _finishSetup),
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

class _AlertColors {
  const _AlertColors._();

  static const white = Color(0xFFFFFFFF);
  static const purple = Color(0xFF6A00FF);
  static const purpleDark = Color(0xFF4A12E6);
  static const deepPurple = Color(0xFF24104F);
  static const lime = Color(0xFFCCFF00);
  static const lavender = Color(0xFFF3EDFF);
  static const border = Color(0xFFE5E1EE);
  static const mutedText = Color(0xFF5D567A);
  static const darkText = Color(0xFF111333);
  static const shadow = Color(0xFF7B69A5);
}

class _OnboardingStepHeader extends StatelessWidget {
  const _OnboardingStepHeader({required this.logoAsset, required this.scale});

  final String logoAsset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 158 * scale,
              height: 64 * scale,
              child: Image.asset(
                logoAsset,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, _, _) => const _LogoFallback(),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Close onboarding',
              onPressed: () => Navigator.maybeOf(context)?.maybePop(),
              icon: const Icon(Icons.close_rounded),
              color: _AlertColors.mutedText,
              iconSize: 30 * scale,
            ),
          ],
        ),
        SizedBox(height: 20 * scale),
        Row(
          children: [
            _StepCircle(checked: true, scale: scale),
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.symmetric(horizontal: 12 * scale),
                decoration: BoxDecoration(
                  color: _AlertColors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            _StepCircle(text: '2', scale: scale),
            SizedBox(width: 18 * scale),
            Text(
              '2 / 2',
              style: TextStyle(
                color: _AlertColors.purple,
                fontSize: 18 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
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
              style: TextStyle(color: _AlertColors.lime),
            ),
          ],
        ),
        style: TextStyle(
          color: _AlertColors.deepPurple,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.scale, this.checked = false, this.text});

  final double scale;
  final bool checked;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34 * scale,
      height: 34 * scale,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _AlertColors.purple,
        shape: BoxShape.circle,
      ),
      child: checked
          ? Icon(
              Icons.check_rounded,
              color: _AlertColors.white,
              size: 22 * scale,
            )
          : Text(
              text ?? '',
              style: TextStyle(
                color: _AlertColors.white,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _AlertColors.deepPurple,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InterestsGrid extends StatelessWidget {
  const _InterestsGrid({
    required this.interests,
    required this.selectedInterests,
    required this.onToggle,
  });

  final List<_InterestOption> interests;
  final Set<String> selectedInterests;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: interests.map((interest) {
            final selected = selectedInterests.contains(interest.label);

            return SizedBox(
              width: itemWidth,
              child: _InterestChip(
                label: interest.label,
                emoji: interest.emoji,
                selected: selected,
                onTap: () => onToggle(interest.label),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(selected ? 'selected-interest-$label' : 'interest-$label'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _AlertColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _AlertColors.purple : _AlertColors.border,
            width: selected ? 1.5 : 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _AlertColors.purple.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? _AlertColors.deepPurple
                      : _AlertColors.mutedText,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? _AlertColors.purple : _AlertColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _AlertColors.purple : Color(0xFFB9BDCC),
                  width: 1.2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: _AlertColors.white,
                      size: 17,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CrowdPreferenceSlider extends StatelessWidget {
  const _CrowdPreferenceSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _AlertColors.purple,
            inactiveTrackColor: _AlertColors.border,
            overlayColor: _AlertColors.purple.withValues(alpha: 0.08),
            thumbColor: _AlertColors.white,
            trackHeight: 4.5,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 3,
              pressedElevation: 5,
            ),
          ),
          child: Slider(
            key: const ValueKey('crowdPreferenceSlider'),
            value: value,
            min: 0,
            max: 1,
            onChanged: onChanged,
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SliderLabel('Quiet'),
            _SliderLabel('Moderate'),
            _SliderLabel('Lively'),
          ],
        ),
      ],
    );
  }
}

class _SliderLabel extends StatelessWidget {
  const _SliderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _AlertColors.mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ToggleSettingsCard extends StatelessWidget {
  const _ToggleSettingsCard({required this.settings, required this.onChanged});

  final InterestsAlerts settings;
  final void Function(String label, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ToggleData(
        'Real-time crowd alerts',
        Icons.notifications_none_rounded,
        settings.realTimeCrowdAlerts,
      ),
      _ToggleData(
        'AI rerouting',
        Icons.alt_route_rounded,
        settings.aiRerouting,
      ),
      _ToggleData(
        'Cultural scan guide',
        Icons.qr_code_scanner_rounded,
        settings.culturalScanGuide,
      ),
      _ToggleData('Audio guide', Icons.headphones_rounded, settings.audioGuide),
      _ToggleData(
        'Wait-time & reservation help',
        Icons.schedule_rounded,
        settings.waitTimeReservationHelp,
      ),
    ];

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return _ToggleSettingRow(
            data: row,
            showDivider: index != rows.length - 1,
            onChanged: (value) => onChanged(row.label, value),
          );
        }),
      ),
    );
  }
}

class _ToggleSettingRow extends StatelessWidget {
  const _ToggleSettingRow({
    required this.data,
    required this.showDivider,
    required this.onChanged,
  });

  final _ToggleData data;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(data.icon, color: _AlertColors.mutedText, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data.label,
                  style: const TextStyle(
                    color: _AlertColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                key: ValueKey('toggle-${data.label}'),
                value: data.value,
                activeThumbColor: _AlertColors.white,
                activeTrackColor: _AlertColors.purple,
                onChanged: onChanged,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 54, right: 14),
            child: Divider(height: 1, color: _AlertColors.border),
          ),
      ],
    );
  }
}

class _EssentialAccessCard extends StatelessWidget {
  const _EssentialAccessCard({required this.onEnableAccess});

  final VoidCallback onEnableAccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            'Enable essential access',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AlertColors.deepPurple,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _AccessItem(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: 'For local tips & directions',
                ),
              ),
              _VerticalRule(),
              Expanded(
                child: _AccessItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  subtitle: 'For scan & photo features',
                ),
              ),
              _VerticalRule(),
              Expanded(
                child: _AccessItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'For alerts & updates',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              key: const ValueKey('enableAccessButton'),
              onPressed: onEnableAccess,
              style: _purpleButtonStyle(),
              child: const Text(
                'Enable access',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessItem extends StatelessWidget {
  const _AccessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: _AlertColors.lavender,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _AlertColors.purple, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _AlertColors.deepPurple,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _AlertColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: _AlertColors.border,
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationWidth = (constraints.maxWidth * 0.34).clamp(
          126.0,
          176.0,
        );

        return Container(
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                _AlertColors.lavender,
                _AlertColors.lavender.withValues(alpha: 0.30),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: illustrationWidth,
                child: Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (_, _, _) => const _ReadyImageFallback(),
                ),
              ),
              Positioned(
                left: illustrationWidth - 34,
                top: 0,
                bottom: 0,
                width: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _AlertColors.lavender.withValues(alpha: 0),
                        _AlertColors.lavender.withValues(alpha: 0.56),
                        _AlertColors.lavender.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: illustrationWidth - 4,
                right: 14,
                top: 0,
                bottom: 0,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your local travel recommendations are ready.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _AlertColors.deepPurple,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'We’ll tailor routes and tips just for you.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _AlertColors.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadyImageFallback extends StatelessWidget {
  const _ReadyImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _AlertColors.lavender),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 68,
          height: 68,
          margin: const EdgeInsets.only(left: 18),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _AlertColors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: _AlertColors.purple,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _FinishButton extends StatelessWidget {
  const _FinishButton({required this.onPressed});

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
            colors: [_AlertColors.purple, _AlertColors.purpleDark],
          ),
          boxShadow: [
            BoxShadow(
              color: _AlertColors.purple.withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          key: const ValueKey('finishSetupButton'),
          onPressed: onPressed,
          style: _purpleButtonStyle(),
          child: Text(
            context.l10n.finishSetup,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: _AlertColors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _AlertColors.border),
    boxShadow: [
      BoxShadow(
        color: _AlertColors.shadow.withValues(alpha: 0.07),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

ButtonStyle _purpleButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

class _InterestOption {
  const _InterestOption(this.label, this.emoji);

  final String label;
  final String emoji;
}

class _ToggleData {
  const _ToggleData(this.label, this.icon, this.value);

  final String label;
  final IconData icon;
  final bool value;
}
