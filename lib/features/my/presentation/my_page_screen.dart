import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/core/localization/app_locale_controller.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/widgets/nori_bottom_navigation.dart';
import 'package:norigo/features/my/application/my_page_controller.dart';
import 'package:norigo/features/my/data/my_page_repository.dart';
import 'package:norigo/features/my/domain/my_page_summary.dart';
import 'package:norigo/l10n/app_localizations.dart';

class MyPageAssets {
  const MyPageAssets._();

  static const logo = 'assets/images/splash/norigo_logo_full.png';
  static const headerBackground = 'assets/images/my/my_header_bg.png';
  static const explorerBadge = 'assets/images/my/local_explorer_badge.png';
  static const explorerBackpack =
      'assets/images/my/local_explorer_backpack.png';
}

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({
    super.key,
    this.logoAsset = MyPageAssets.logo,
    this.headerAsset = MyPageAssets.headerBackground,
    this.badgeAsset = MyPageAssets.explorerBadge,
    this.backpackAsset = MyPageAssets.explorerBackpack,
    this.repository = const SupabaseMyPageRepository(),
    this.showBottomNavigation = true,
  });

  final String logoAsset;
  final String headerAsset;
  final String badgeAsset;
  final String backpackAsset;
  final MyPageRepository repository;
  final bool showBottomNavigation;

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late MyPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MyPageController(repository: widget.repository)..load();
  }

  @override
  void didUpdateWidget(covariant MyPageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository == widget.repository) return;
    _controller.dispose();
    _controller = MyPageController(repository: widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBottomNavigation(int index) {
    if (index == 4) return;

    final route = switch (index) {
      0 => AppRoutes.home,
      1 => AppRoutes.itinerary,
      2 => AppRoutes.scan,
      3 => AppRoutes.discover,
      _ => null,
    };

    if (route != null && AppRouter.routes.containsKey(route)) {
      Navigator.of(context).pushReplacementNamed(route);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.sectionComingSoon)));
  }

  void _openMenuSheet(_MyMenuAction action, MyPageSummary summary) {
    final l10n = context.l10n;
    switch (action) {
      case _MyMenuAction.itineraries:
        _showSheet(
          title: l10n.myItineraries,
          child: _ItinerariesSheet(
            plans: summary.itineraries,
            onOpenPlan: _openItineraryDetail,
          ),
        );
      case _MyMenuAction.savedPlaces:
        _showSheet(
          title: l10n.savedPlaces,
          child: _SavedPlacesSheet(places: summary.savedPlaces),
        );
      case _MyMenuAction.translationHistory:
        _showSheet(
          title: l10n.translationHistory,
          child: _MessageSheet(message: l10n.translationHistoryEmpty),
        );
      case _MyMenuAction.cultureGuides:
        _showSheet(
          title: l10n.savedCultureGuides,
          child: _CultureGuidesSheet(guides: summary.cultureGuides),
        );
      case _MyMenuAction.waitTimeHistory:
        _showSheet(
          title: l10n.waitTimeHelpHistory,
          child: _RetripEventsSheet(events: summary.retripEvents),
        );
      case _MyMenuAction.interests:
        _showSheet(
          title: l10n.interests,
          child: _InterestsSheet(
            interests: summary.interests,
            foodNeeds: summary.foodNeeds,
          ),
        );
      case _MyMenuAction.languageNotifications:
        _showLanguageSheet();
      case _MyMenuAction.privacyData:
        _showSheet(
          title: l10n.privacyData,
          child: _MessageSheet(message: l10n.privacyDataMessage),
        );
      case _MyMenuAction.helpCenter:
        _showSheet(
          title: l10n.helpCenter,
          child: _MessageSheet(message: l10n.helpCenterMessage),
        );
    }
  }

  Future<void> _showLanguageSheet() async {
    final localeController = AppLocaleScope.of(context);
    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      backgroundColor: _MyColors.white,
      builder: (context) {
        return _LanguageSheet(selectedLocale: localeController.locale);
      },
    );
    if (selectedLocale == null) return;

    await localeController.setLocale(selectedLocale);
    if (!mounted) return;
    final l10n = lookupAppLocalizations(selectedLocale);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.languageUpdated)));
    _controller.load();
  }

  void _openItineraryDetail(MyItineraryPlanPreview plan) {
    _showSheet(
      title: plan.title,
      child: _ItineraryDetailSheet(plan: plan),
    );
  }

  void _showSheet({required String title, required Widget child}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _MyColors.white,
      builder: (context) {
        return _SheetFrame(title: title, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _MyColors.white,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final summary = _controller.summary;
          final isInitialLoading = _controller.isLoading && summary == null;

          return Scaffold(
            key: const ValueKey('myPageScreen'),
            backgroundColor: _MyColors.white,
            bottomNavigationBar: widget.showBottomNavigation
                ? NoriBottomNavigation(
                    currentIndex: 4,
                    onChanged: _handleBottomNavigation,
                  )
                : null,
            body: SafeArea(
              bottom: false,
              child: isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _MyColors.purple),
                    )
                  : _MyPageContent(
                      summary: summary ?? MyPageSummary.localPreview(),
                      logoAsset: widget.logoAsset,
                      headerAsset: widget.headerAsset,
                      badgeAsset: widget.badgeAsset,
                      backpackAsset: widget.backpackAsset,
                      onMenuSelected: _openMenuSheet,
                      isRefreshing: _controller.isLoading,
                    ),
            ),
          );
        },
      ),
    );
  }
}

String _menuActionLabel(BuildContext context, _MyMenuAction action) {
  final l10n = context.l10n;
  return switch (action) {
    _MyMenuAction.itineraries => l10n.myItineraries,
    _MyMenuAction.savedPlaces => l10n.savedPlaces,
    _MyMenuAction.translationHistory => l10n.translationHistory,
    _MyMenuAction.cultureGuides => l10n.savedCultureGuides,
    _MyMenuAction.waitTimeHistory => l10n.waitTimeHelpHistory,
    _MyMenuAction.interests => l10n.interests,
    _MyMenuAction.languageNotifications => l10n.languageNotifications,
    _MyMenuAction.privacyData => l10n.privacyData,
    _MyMenuAction.helpCenter => l10n.helpCenter,
  };
}

String _languageDisplayLabel(BuildContext context, String language) {
  if (AppLocaleScope.maybeOf(context) == null) return language;
  final locale = AppLocaleController.localeForUserLanguage(language);
  if (locale.languageCode == 'ko') return context.l10n.koreanNative;
  return context.l10n.english;
}

class _MyPageContent extends StatelessWidget {
  const _MyPageContent({
    required this.summary,
    required this.logoAsset,
    required this.headerAsset,
    required this.badgeAsset,
    required this.backpackAsset,
    required this.onMenuSelected,
    required this.isRefreshing,
  });

  final MyPageSummary summary;
  final String logoAsset;
  final String headerAsset;
  final String badgeAsset;
  final String backpackAsset;
  final void Function(_MyMenuAction action, MyPageSummary summary)
  onMenuSelected;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = math.min(constraints.maxWidth, 430.0);
        final scale = (pageWidth / 430.0).clamp(0.86, 1.0).toDouble();
        final bottomPadding =
            (MediaQuery.paddingOf(context).bottom + 24) * scale;

        return Center(
          child: SizedBox(
            width: pageWidth,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                18 * scale,
                16 * scale,
                bottomPadding + 10 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    logoAsset: logoAsset,
                    summary: summary,
                    scale: scale,
                    isRefreshing: isRefreshing,
                  ),
                  SizedBox(height: 20 * scale),
                  _ProfileHeader(
                    summary: summary,
                    headerAsset: headerAsset,
                    scale: scale,
                  ),
                  if (summary.localOnly) ...[
                    SizedBox(height: 8 * scale),
                    _LocalModeNote(scale: scale),
                  ],
                  SizedBox(height: 18 * scale),
                  _MenuCard(
                    scale: scale,
                    onSelected: (action) => onMenuSelected(action, summary),
                  ),
                  SizedBox(height: 18 * scale),
                  _ExplorerProgressCard(
                    summary: summary,
                    badgeAsset: badgeAsset,
                    backpackAsset: backpackAsset,
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.logoAsset,
    required this.summary,
    required this.scale,
    required this.isRefreshing,
  });

  final String logoAsset;
  final MyPageSummary summary;
  final double scale;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 210 * scale,
          height: 68 * scale,
          child: Image.asset(
            logoAsset,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, _, _) => const _LogoFallback(),
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: context.l10n.notifications,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.notificationsPending)),
                );
              },
              icon: Icon(
                Icons.notifications_none_rounded,
                color: _MyColors.deepPurple,
                size: 30 * scale,
              ),
            ),
            Positioned(
              right: 10 * scale,
              top: 8 * scale,
              child: Container(
                width: 11 * scale,
                height: 11 * scale,
                decoration: BoxDecoration(
                  color: _MyColors.lime,
                  shape: BoxShape.circle,
                  border: Border.all(color: _MyColors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 10 * scale),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _ProfileAvatar(summary: summary, size: 48 * scale),
            if (isRefreshing)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _MyColors.white.withValues(alpha: 0.60),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12 * scale),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _MyColors.purple,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.summary,
    required this.headerAsset,
    required this.scale,
  });

  final MyPageSummary summary;
  final String headerAsset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final heroHeight = 270 * scale;
    final statsHeight = 104 * scale;

    return SizedBox(
      height: heroHeight + statsHeight - 28 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: statsHeight - 30 * scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24 * scale),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _MyColors.lavender,
                  boxShadow: [
                    BoxShadow(
                      color: _MyColors.shadow.withValues(alpha: 0.12),
                      blurRadius: 18 * scale,
                      offset: Offset(0, 8 * scale),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        headerAsset,
                        key: const ValueKey('my-header-bg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        errorBuilder: (_, _, _) => const _HeaderFallback(),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              _MyColors.white.withValues(alpha: 0.90),
                              _MyColors.white.withValues(alpha: 0.52),
                              _MyColors.white.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        22 * scale,
                        34 * scale,
                        18 * scale,
                        56 * scale,
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _ProfileAvatar(
                                summary: summary,
                                size: 92 * scale,
                              ),
                              Positioned(
                                right: -4 * scale,
                                bottom: -4 * scale,
                                child: Container(
                                  width: 38 * scale,
                                  height: 38 * scale,
                                  decoration: BoxDecoration(
                                    color: _MyColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _MyColors.shadow.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 10 * scale,
                                        offset: Offset(0, 5 * scale),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: _MyColors.navMuted,
                                    size: 18 * scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 24 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  summary.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _MyColors.deepPurple,
                                    fontSize: 31 * scale,
                                    fontWeight: FontWeight.w900,
                                    height: 1.08,
                                  ),
                                ),
                                SizedBox(height: 14 * scale),
                                _MetaLine(
                                  icon: Icons.location_on_outlined,
                                  label: summary.locationLabel,
                                  scale: scale,
                                ),
                                SizedBox(height: 8 * scale),
                                _MetaLine(
                                  icon: Icons.translate_rounded,
                                  label:
                                      AppLocaleScope.maybeOf(
                                        context,
                                      )?.languageDisplayName ??
                                      _languageDisplayLabel(
                                        context,
                                        summary.languageLabel,
                                      ),
                                  scale: scale,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StatsPanel(summary: summary, scale: scale),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.summary, required this.size});

  final MyPageSummary summary;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = summary.avatarUrl;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.045),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _MyColors.white,
        border: Border.all(color: _MyColors.purple, width: size * 0.035),
      ),
      child: ClipOval(
        child: avatarUrl == null
            ? _AvatarFallback(initials: summary.initials)
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _AvatarFallback(initials: summary.initials),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE3FF), Color(0xFFB7EAFF)],
        ),
      ),
      child: Center(
        child: RegExp(r'^\d+$').hasMatch(initials)
            ? const Icon(
                Icons.person_rounded,
                color: _MyColors.deepPurple,
                size: 34,
              )
            : Text(
                initials,
                style: const TextStyle(
                  color: _MyColors.deepPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _LocalModeNote extends StatelessWidget {
  const _LocalModeNote({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scale,
          vertical: 6 * scale,
        ),
        decoration: BoxDecoration(
          color: _MyColors.lavender.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _MyColors.purple.withValues(alpha: 0.12)),
        ),
        child: Text(
          'Local mode',
          style: TextStyle(
            color: _MyColors.purple,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _MyColors.muted, size: 18 * scale),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _MyColors.muted,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.summary, required this.scale});

  final MyPageSummary summary;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = [
      _StatData(
        icon: Icons.bookmark_border_rounded,
        value: '${summary.savedPlansCount}',
        label: l10n.savedPlans,
        color: _MyColors.purple,
      ),
      _StatData(
        icon: Icons.location_on_outlined,
        value: '${summary.savedPlacesCount}',
        label: l10n.savedPlaces,
        color: _MyColors.green,
      ),
      _StatData(
        icon: Icons.crop_free_rounded,
        value: '${summary.cultureScansCount}',
        label: l10n.cultureScans,
        color: _MyColors.purple,
      ),
      _StatData(
        icon: Icons.schedule_rounded,
        value: summary.timeSavedLabel,
        label: l10n.timeSaved,
        color: _MyColors.orange,
      ),
    ];

    return Container(
      height: 104 * scale,
      decoration: BoxDecoration(
        color: _MyColors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: _MyColors.border),
        boxShadow: [
          BoxShadow(
            color: _MyColors.shadow.withValues(alpha: 0.10),
            blurRadius: 16 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Row(
        children: List.generate(stats.length, (index) {
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Container(
                    width: 1,
                    height: 54 * scale,
                    color: _MyColors.border,
                  ),
                Expanded(
                  child: _StatItem(data: stats[index], scale: scale),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.data, required this.scale});

  final _StatData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, color: data.color, size: 28 * scale),
              SizedBox(width: 7 * scale),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.value,
                    maxLines: 1,
                    style: TextStyle(
                      color: _MyColors.deepPurple,
                      fontSize: 25 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _MyColors.muted,
              fontSize: 12.5 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.scale, required this.onSelected});

  final double scale;
  final ValueChanged<_MyMenuAction> onSelected;

  static const _items = [
    _MenuItemData(
      action: _MyMenuAction.itineraries,
      icon: Icons.calendar_month_rounded,
      label: 'My itineraries',
      color: _MyColors.purple,
    ),
    _MenuItemData(
      action: _MyMenuAction.savedPlaces,
      icon: Icons.location_on_outlined,
      label: 'Saved places',
      color: _MyColors.green,
    ),
    _MenuItemData(
      action: _MyMenuAction.translationHistory,
      icon: Icons.translate_rounded,
      label: 'Translation history',
      color: _MyColors.blue,
    ),
    _MenuItemData(
      action: _MyMenuAction.cultureGuides,
      icon: Icons.menu_book_outlined,
      label: 'Saved culture guides',
      color: _MyColors.purple,
    ),
    _MenuItemData(
      action: _MyMenuAction.waitTimeHistory,
      icon: Icons.schedule_rounded,
      label: 'Wait-time help history',
      color: _MyColors.green,
    ),
    _MenuItemData(
      action: _MyMenuAction.interests,
      icon: Icons.favorite_border_rounded,
      label: 'Interests',
      color: _MyColors.orange,
    ),
    _MenuItemData(
      action: _MyMenuAction.languageNotifications,
      icon: Icons.notifications_none_rounded,
      label: 'Language & notifications',
      color: _MyColors.purple,
    ),
    _MenuItemData(
      action: _MyMenuAction.privacyData,
      icon: Icons.lock_outline_rounded,
      label: 'Privacy & data',
      color: _MyColors.blue,
    ),
    _MenuItemData(
      action: _MyMenuAction.helpCenter,
      icon: Icons.help_outline_rounded,
      label: 'Help center',
      color: _MyColors.navMuted,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MyColors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: _MyColors.border),
        boxShadow: [
          BoxShadow(
            color: _MyColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          return _MenuRow(
            data: item,
            label: _menuActionLabel(context, item.action),
            scale: scale,
            showDivider: index < _items.length - 1,
            onTap: () => onSelected(item.action),
          );
        }),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.data,
    required this.label,
    required this.scale,
    required this.showDivider,
    required this.onTap,
  });

  final _MenuItemData data;
  final String label;
  final double scale;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 18 * scale, right: 14 * scale),
        child: Column(
          children: [
            SizedBox(
              height: 58 * scale,
              child: Row(
                children: [
                  Icon(data.icon, color: data.color, size: 26 * scale),
                  SizedBox(width: 18 * scale),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _MyColors.deepPurple,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _MyColors.navMuted,
                    size: 28 * scale,
                  ),
                ],
              ),
            ),
            if (showDivider)
              Padding(
                padding: EdgeInsets.only(left: 44 * scale),
                child: const Divider(height: 1, color: _MyColors.border),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerProgressCard extends StatelessWidget {
  const _ExplorerProgressCard({
    required this.summary,
    required this.badgeAsset,
    required this.backpackAsset,
    required this.scale,
  });

  final MyPageSummary summary;
  final String badgeAsset;
  final String backpackAsset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150 * scale,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF6EFFF), Color(0xFFEEDFFF), Color(0xFFE0C9F7)],
        ),
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: _MyColors.border),
        boxShadow: [
          BoxShadow(
            color: _MyColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22 * scale),
        child: Stack(
          children: [
            Positioned(
              right: -8 * scale,
              bottom: -4 * scale,
              width: 136 * scale,
              height: 136 * scale,
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.38,
                  alignment: Alignment.center,
                  child: Image.asset(
                    backpackAsset,
                    key: const ValueKey('local-explorer-backpack'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const _AssetIconFallback(icon: Icons.backpack_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                18 * scale,
                116 * scale,
                16 * scale,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 76 * scale,
                    height: 76 * scale,
                    child: Image.asset(
                      badgeAsset,
                      key: const ValueKey('local-explorer-badge'),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const _AssetIconFallback(
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * scale),
                  Expanded(
                    child: _ExplorerProgressCopy(
                      summary: summary,
                      scale: scale,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerProgressCopy extends StatelessWidget {
  const _ExplorerProgressCopy({required this.summary, required this.scale});

  final MyPageSummary summary;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary.levelBadge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _MyColors.deepPurple,
                  fontSize: 23 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        Text(
          context.l10n.keepExploring,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _MyColors.muted,
            fontSize: 14 * scale,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        SizedBox(height: 14 * scale),
        ClipRRect(
          borderRadius: BorderRadius.circular(12 * scale),
          child: LinearProgressIndicator(
            minHeight: 9 * scale,
            value: summary.xpProgress,
            backgroundColor: _MyColors.purple.withValues(alpha: 0.20),
            valueColor: const AlwaysStoppedAnimation(_MyColors.purple),
          ),
        ),
        SizedBox(height: 10 * scale),
        Text(
          '${_formatNumber(summary.xp)} / ${_formatNumber(summary.xpTarget)} XP',
          style: TextStyle(
            color: _MyColors.deepPurple,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _MyColors.deepPurple,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ItinerariesSheet extends StatelessWidget {
  const _ItinerariesSheet({required this.plans, required this.onOpenPlan});

  final List<MyItineraryPlanPreview> plans;
  final ValueChanged<MyItineraryPlanPreview> onOpenPlan;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return _EmptySheetMessage(message: context.l10n.noSavedItineraries);
    }

    return Column(
      children: plans
          .map((plan) {
            final places = plan.placeNames.take(3).join(' · ');
            return _SheetListTile(
              icon: Icons.calendar_month_rounded,
              title: plan.title,
              subtitle: [
                plan.createdAtLabel,
                plan.sourceBadge,
                if (plan.summary.isNotEmpty) plan.summary,
                if (places.isNotEmpty) places,
              ].join('\n'),
              onTap: () {
                Navigator.of(context).pop();
                onOpenPlan(plan);
              },
            );
          })
          .toList(growable: false),
    );
  }
}

class _ItineraryDetailSheet extends StatelessWidget {
  const _ItineraryDetailSheet({required this.plan});

  final MyItineraryPlanPreview plan;

  @override
  Widget build(BuildContext context) {
    if (plan.placeNames.isEmpty) {
      return _EmptySheetMessage(message: context.l10n.noSavedItineraries);
    }
    return Column(
      children: plan.placeNames
          .map(
            (name) => _SheetListTile(
              icon: Icons.place_outlined,
              title: name,
              subtitle: context.l10n.savedItineraryStop,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SavedPlacesSheet extends StatelessWidget {
  const _SavedPlacesSheet({required this.places});

  final List<MySavedPlacePreview> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return _EmptySheetMessage(message: context.l10n.noSavedPlaces);
    }
    return Column(
      children: places
          .map(
            (place) => _SheetListTile(
              icon: Icons.location_on_outlined,
              title: place.name,
              subtitle: place.subtitle,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CultureGuidesSheet extends StatelessWidget {
  const _CultureGuidesSheet({required this.guides});

  final List<MyCultureGuidePreview> guides;

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) {
      return _EmptySheetMessage(message: context.l10n.noSavedCultureGuides);
    }
    return Column(
      children: guides
          .map((guide) {
            final details = [
              guide.createdAtLabel,
              if (guide.detectedObject.isNotEmpty)
                guide.detectedObject.replaceAll('_', ' '),
              if (guide.detectedObjectSource.isNotEmpty)
                guide.detectedObjectSource,
              if (guide.sourceBadge.isNotEmpty) guide.sourceBadge,
              if (guide.koreanPhrase.isNotEmpty) guide.koreanPhrase,
              if (guide.detectedObject.isEmpty && guide.sourceBadge.isEmpty)
                guide.subtitle,
            ].join('\n');
            return _SheetListTile(
              icon: Icons.menu_book_outlined,
              leading: _CultureGuideThumbnail(guide: guide),
              title: guide.locationName.isEmpty
                  ? guide.title
                  : guide.locationName,
              subtitle: details,
            );
          })
          .toList(growable: false),
    );
  }
}

class _RetripEventsSheet extends StatelessWidget {
  const _RetripEventsSheet({required this.events});

  final List<MyRetripEventPreview> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptySheetMessage(message: context.l10n.noWaitTimeHistory);
    }
    return Column(
      children: events
          .map(
            (event) => _SheetListTile(
              icon: Icons.schedule_rounded,
              title: event.originalPlaceName,
              subtitle:
                  '${event.triggerType}\n${event.sourceBadge} · ${event.createdAtLabel}',
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InterestsSheet extends StatelessWidget {
  const _InterestsSheet({required this.interests, required this.foodNeeds});

  final List<String> interests;
  final String foodNeeds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (interests.isEmpty)
          _EmptySheetMessage(message: context.l10n.noInterestsSelected)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests
                .map((interest) => _InfoChip(label: interest))
                .toList(growable: false),
          ),
        const SizedBox(height: 16),
        _SheetListTile(
          icon: Icons.restaurant_menu_rounded,
          title: context.l10n.foodNeeds,
          subtitle: foodNeeds,
        ),
      ],
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.selectedLocale});

  final Locale selectedLocale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.language,
              style: const TextStyle(
                color: _MyColors.deepPurple,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _LanguageOptionTile(
              locale: const Locale('en'),
              selectedLocale: selectedLocale,
              title: l10n.english,
            ),
            _LanguageOptionTile(
              locale: const Locale('ko'),
              selectedLocale: selectedLocale,
              title: l10n.koreanNative,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.locale,
    required this.selectedLocale,
    required this.title,
  });

  final Locale locale;
  final Locale selectedLocale;
  final String title;

  @override
  Widget build(BuildContext context) {
    final selected = locale.languageCode == selectedLocale.languageCode;
    return _SheetListTile(
      icon: selected ? Icons.check_circle_rounded : Icons.circle_outlined,
      title: title,
      subtitle: selected ? context.l10n.preferredLanguage : '',
      onTap: () => Navigator.of(context).pop(locale),
    );
  }
}

class _MessageSheet extends StatelessWidget {
  const _MessageSheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: _MyColors.muted,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SheetListTile extends StatelessWidget {
  const _SheetListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.leading,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _MyColors.lavender.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _MyColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: leading ?? Icon(icon, color: _MyColors.purple),
          title: Text(
            title,
            style: const TextStyle(
              color: _MyColors.deepPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: _MyColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          trailing: onTap == null
              ? null
              : const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _CultureGuideThumbnail extends StatelessWidget {
  const _CultureGuideThumbnail({required this.guide});

  final MyCultureGuidePreview guide;

  @override
  Widget build(BuildContext context) {
    final imageUrl = guide.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _thumbnailPlaceholder();
    }

    final token = SupabaseAuthSession.accessToken;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
          errorBuilder: (context, error, stackTrace) => _thumbnailPlaceholder(),
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _MyColors.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_outlined, color: _MyColors.purple),
    );
  }
}

class _EmptySheetMessage extends StatelessWidget {
  const _EmptySheetMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _MyColors.lavender.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _MyColors.muted,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: _MyColors.lavender,
      side: BorderSide(color: _MyColors.purple.withValues(alpha: 0.20)),
      labelStyle: const TextStyle(
        color: _MyColors.deepPurple,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Nori'),
            TextSpan(
              text: 'Go',
              style: TextStyle(color: _MyColors.limeDark),
            ),
          ],
        ),
        style: TextStyle(
          color: _MyColors.deepPurple,
          fontSize: 38,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _HeaderFallback extends StatelessWidget {
  const _HeaderFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7F1FF), Color(0xFFE8F7FF)],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 24),
          child: Icon(
            Icons.account_balance_rounded,
            color: _MyColors.purple,
            size: 96,
          ),
        ),
      ),
    );
  }
}

class _AssetIconFallback extends StatelessWidget {
  const _AssetIconFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _MyColors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: _MyColors.purple, size: 42),
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
}

class _MenuItemData {
  const _MenuItemData({
    required this.action,
    required this.icon,
    required this.label,
    required this.color,
  });

  final _MyMenuAction action;
  final IconData icon;
  final String label;
  final Color color;
}

enum _MyMenuAction {
  itineraries,
  savedPlaces,
  translationHistory,
  cultureGuides,
  waitTimeHistory,
  interests,
  languageNotifications,
  privacyData,
  helpCenter,
}

class _MyColors {
  const _MyColors._();

  static const white = Color(0xFFFFFFFF);
  static const deepPurple = Color(0xFF1D0B5F);
  static const purple = Color(0xFF6425F5);
  static const lime = Color(0xFFB6EA00);
  static const limeDark = Color(0xFF8CCB00);
  static const green = Color(0xFF25B84A);
  static const blue = Color(0xFF1389F5);
  static const orange = Color(0xFFFF9F00);
  static const lavender = Color(0xFFF3EDFF);
  static const muted = Color(0xFF68708A);
  static const navMuted = Color(0xFF7A8195);
  static const border = Color(0xFFE8EAF2);
  static const shadow = Color(0xFF4E3A76);
}

String _formatNumber(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    final positionFromEnd = raw.length - index;
    buffer.write(raw[index]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
