import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:norigo/app/router.dart';
import 'package:norigo/features/discover/application/discover_controller.dart';
import 'package:norigo/features/discover/data/discover_repository.dart';
import 'package:norigo/features/discover/domain/discover_category.dart';
import 'package:norigo/features/discover/domain/discover_place.dart';

const _logoAsset = 'assets/images/splash/norigo_logo_full.png';
const _headerAsset = 'assets/images/discover/discover_header_bg.png';
const _pinHelloAsset = 'assets/images/discover/discover_pin_hello.png';
const _towerAsset = 'assets/images/discover/discover_tower_bg.png';
const _avatarAsset = 'assets/images/discover/profile_avatar.png';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.controller, this.enableLiveMap = true});

  final DiscoverController? controller;
  final bool enableLiveMap;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late DiscoverController _controller;
  late bool _ownsController;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _controller.load();
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    _detachController();
    _attachController(widget.controller);
    if (_controller.places.isEmpty) _controller.load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _detachController();
    super.dispose();
  }

  void _attachController(DiscoverController? controller) {
    _ownsController = controller == null;
    _controller =
        controller ??
        DiscoverController(repository: const SupabaseDiscoverRepository());
    _controller.addListener(_handleControllerChanged);
  }

  void _detachController() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _controller.search(value),
    );
  }

  Future<void> _showAllPlaces() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _DiscoverColors.white,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                const Text(
                  'AI picks for you',
                  style: TextStyle(
                    color: _DiscoverColors.deepPurple,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ..._controller.places.map(
                  (place) => _CompactPlaceTile(
                    place: place,
                    onTap: () {
                      Navigator.of(context).pop();
                      _openPlaceSheet(place);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPlaceSheet(DiscoverPlace place) {
    final rootContext = context;
    return showModalBottomSheet<void>(
      context: rootContext,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _DiscoverColors.white,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: _PlaceDetailSheet(
              place: place,
              onSave: () async {
                final result = await _controller.savePlace(place);
                if (!rootContext.mounted || !sheetContext.mounted) return;
                final message = result.message ?? 'Place saved.';
                ScaffoldMessenger.of(rootContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
                Navigator.of(sheetContext).pop();
              },
              onAddToItinerary: () {
                ScaffoldMessenger.of(rootContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Add to itinerary coming soon.'),
                    ),
                  );
              },
            ),
          ),
        );
      },
    );
  }

  void _openPreferences() {
    if (AppRouter.routes.containsKey(AppRoutes.interestsAlerts)) {
      Navigator.of(context).pushNamed(AppRoutes.interestsAlerts);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Preferences are coming soon.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _DiscoverColors.white,
      ),
      child: ColoredBox(
        color: _DiscoverColors.white,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageWidth = math.min(constraints.maxWidth, 430.0);
              final scale = (pageWidth / 430.0).clamp(0.86, 1.0).toDouble();
              final bottomPadding = 18 * scale;

              return Center(
                child: SizedBox(
                  width: pageWidth,
                  child: RefreshIndicator(
                    color: _DiscoverColors.purple,
                    onRefresh: _controller.load,
                    child: ListView(
                      key: const ValueKey('discoverScreen'),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        20 * scale,
                        0,
                        20 * scale,
                        bottomPadding,
                      ),
                      children: [
                        _HeroHeader(scale: scale),
                        SizedBox(height: 12 * scale),
                        _SearchBar(
                          controller: _searchController,
                          scale: scale,
                          onChanged: _onSearchChanged,
                          onSubmitted: _controller.search,
                        ),
                        SizedBox(height: 14 * scale),
                        _CategoryScroller(
                          selected: _controller.category,
                          scale: scale,
                          onSelected: _controller.selectCategory,
                        ),
                        SizedBox(height: 16 * scale),
                        _DiscoverMapCard(
                          places: _controller.places,
                          selectedPlaceId: _controller.selectedPlaceId,
                          scale: scale,
                          enableLiveMap: widget.enableLiveMap,
                          onPlaceSelected: _controller.selectPlace,
                        ),
                        SizedBox(height: 18 * scale),
                        _AiPicksHeader(
                          scale: scale,
                          isLocalFallback:
                              _controller.sourceType == 'local_fallback',
                          onSeeAll: _showAllPlaces,
                        ),
                        SizedBox(height: 10 * scale),
                        if (_controller.isLoading)
                          ...List.generate(
                            3,
                            (index) => _LoadingPlaceCard(scale: scale),
                          )
                        else if (_controller.places.isEmpty)
                          _EmptyStateCard(
                            query: _controller.query,
                            scale: scale,
                          )
                        else
                          ..._controller.places
                              .take(3)
                              .map(
                                (place) => _HiddenSpotCard(
                                  place: place,
                                  scale: scale,
                                  selected:
                                      _controller.selectedPlaceId == place.id,
                                  onTap: () {
                                    _controller.selectPlace(place.id);
                                    _openPlaceSheet(place);
                                  },
                                ),
                              ),
                        if (_controller.errorMessage != null) ...[
                          SizedBox(height: 6 * scale),
                          _SourceNote(
                            message: _controller.errorMessage!,
                            scale: scale,
                          ),
                        ],
                        SizedBox(height: 10 * scale),
                        _RecommendationBanner(
                          scale: scale,
                          onPressed: _openPreferences,
                        ),
                      ],
                    ),
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

class _DiscoverColors {
  const _DiscoverColors._();

  static const white = Color(0xFFFFFFFF);
  static const deepPurple = Color(0xFF21045D);
  static const purple = Color(0xFF5717D9);
  static const lavender = Color(0xFFF0E8FF);
  static const paleLavender = Color(0xFFF8F4FF);
  static const lime = Color(0xFFB6F100);
  static const green = Color(0xFF2DAF3A);
  static const softGreen = Color(0xFFE8F8DF);
  static const blue = Color(0xFF087CFF);
  static const muted = Color(0xFF6E728A);
  static const darkMuted = Color(0xFF333553);
  static const border = Color(0xFFE8E3F2);
  static const shadow = Color(0xFF5E4D85);
  static const orange = Color(0xFFFFA11E);
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -58 * scale,
            top: 92 * scale,
            width: 340 * scale,
            height: 126 * scale,
            child: Opacity(
              opacity: 0.88,
              child: Image.asset(
                _headerAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _MockStatusBar(scale: scale),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 44 * scale,
            child: _TopBar(scale: scale),
          ),
          Positioned(
            left: 0,
            right: 112 * scale,
            bottom: 22 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover hidden spots',
                  maxLines: 2,
                  style: TextStyle(
                    color: _DiscoverColors.deepPurple,
                    fontSize: 30 * scale,
                    height: 1.04,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  'Skip the wait, go local.',
                  style: TextStyle(
                    color: _DiscoverColors.muted,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
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

class _MockStatusBar extends StatelessWidget {
  const _MockStatusBar({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34 * scale,
      child: Row(
        children: [
          SizedBox(width: 10 * scale),
          Text(
            '9:41',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.signal_cellular_alt,
            size: 21 * scale,
            color: Colors.black,
          ),
          SizedBox(width: 6 * scale),
          Icon(Icons.wifi_rounded, size: 22 * scale, color: Colors.black),
          SizedBox(width: 6 * scale),
          Icon(
            Icons.battery_full_rounded,
            size: 24 * scale,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 150 * scale,
          height: 58 * scale,
          child: Image.asset(
            _logoAsset,
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
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon.')),
                );
              },
              icon: Icon(
                Icons.notifications_none_rounded,
                color: _DiscoverColors.deepPurple,
                size: 34 * scale,
              ),
            ),
            Positioned(
              right: 11 * scale,
              top: 8 * scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _DiscoverColors.lime,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _DiscoverColors.white,
                    width: 2 * scale,
                  ),
                ),
                child: SizedBox(width: 12 * scale, height: 12 * scale),
              ),
            ),
          ],
        ),
        SizedBox(width: 10 * scale),
        ClipOval(
          child: Image.asset(
            _avatarAsset,
            width: 50 * scale,
            height: 50 * scale,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 50 * scale,
              height: 50 * scale,
              color: _DiscoverColors.lavender,
              alignment: Alignment.center,
              child: Text(
                'EK',
                style: TextStyle(
                  color: _DiscoverColors.deepPurple,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
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
              style: TextStyle(color: _DiscoverColors.lime),
            ),
          ],
        ),
        style: TextStyle(
          color: _DiscoverColors.deepPurple,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.scale,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final double scale;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58 * scale,
      decoration: BoxDecoration(
        color: _DiscoverColors.white,
        borderRadius: BorderRadius.circular(30 * scale),
        border: Border.all(color: _DiscoverColors.border),
        boxShadow: [
          BoxShadow(
            color: _DiscoverColors.shadow.withValues(alpha: 0.13),
            blurRadius: 18 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: TextField(
        key: const ValueKey('discoverSearchField'),
        controller: controller,
        cursorColor: _DiscoverColors.purple,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search destinations, food, cafes, culture questions',
          hintStyle: TextStyle(
            color: _DiscoverColors.muted,
            fontSize: 15.5 * scale,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _DiscoverColors.purple,
            size: 30 * scale,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.only(top: 15 * scale),
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({
    required this.selected,
    required this.scale,
    required this.onSelected,
  });

  final DiscoverCategory selected;
  final double scale;
  final ValueChanged<DiscoverCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: DiscoverCategory.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8 * scale),
        itemBuilder: (context, index) {
          final category = DiscoverCategory.values[index];
          return _CategoryChip(
            category: category,
            selected: selected == category,
            scale: scale,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final DiscoverCategory category;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selected && category == DiscoverCategory.quietCafe
        ? 'Quiet cafe\nactive'
        : category.label;

    return InkWell(
      borderRadius: BorderRadius.circular(8 * scale),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: _chipWidth(category, selected) * scale,
        height: 56 * scale,
        padding: EdgeInsets.symmetric(horizontal: 13 * scale),
        decoration: BoxDecoration(
          color: selected ? _DiscoverColors.lavender : _DiscoverColors.white,
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(
            color: selected ? _DiscoverColors.lavender : _DiscoverColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: _DiscoverColors.shadow.withValues(alpha: 0.10),
              blurRadius: 12 * scale,
              offset: Offset(0, 5 * scale),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(category),
              color: selected
                  ? _DiscoverColors.purple
                  : _DiscoverColors.darkMuted,
              size: 25 * scale,
            ),
            SizedBox(width: 9 * scale),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? _DiscoverColors.purple
                      : _DiscoverColors.darkMuted,
                  fontSize: 14.5 * scale,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _chipWidth(DiscoverCategory category, bool selected) {
    if (selected && category == DiscoverCategory.quietCafe) return 116;
    return switch (category) {
      DiscoverCategory.quietCafe => 108,
      DiscoverCategory.dessert => 88,
      DiscoverCategory.localFood => 116,
      DiscoverCategory.photoSpot => 116,
      DiscoverCategory.culture => 100,
    };
  }
}

IconData _categoryIcon(DiscoverCategory category) {
  return switch (category) {
    DiscoverCategory.quietCafe => Icons.local_cafe_outlined,
    DiscoverCategory.dessert => Icons.cake_outlined,
    DiscoverCategory.localFood => Icons.restaurant_menu_rounded,
    DiscoverCategory.photoSpot => Icons.camera_alt_outlined,
    DiscoverCategory.culture => Icons.account_balance_outlined,
  };
}

class _DiscoverMapCard extends StatefulWidget {
  const _DiscoverMapCard({
    required this.places,
    required this.selectedPlaceId,
    required this.scale,
    required this.enableLiveMap,
    required this.onPlaceSelected,
  });

  final List<DiscoverPlace> places;
  final String? selectedPlaceId;
  final double scale;
  final bool enableLiveMap;
  final ValueChanged<String> onPlaceSelected;

  @override
  State<_DiscoverMapCard> createState() => _DiscoverMapCardState();
}

class _DiscoverMapCardState extends State<_DiscoverMapCard> {
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return Container(
      height: 154 * scale,
      decoration: BoxDecoration(
        color: _DiscoverColors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: _DiscoverColors.border),
        boxShadow: [
          BoxShadow(
            color: _DiscoverColors.shadow.withValues(alpha: 0.12),
            blurRadius: 15 * scale,
            offset: Offset(0, 7 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8 * scale),
        child: Stack(
          children: [
            Positioned.fill(
              child: _showMap && widget.enableLiveMap
                  ? _FlutterMapLayer(
                      places: widget.places,
                      selectedPlaceId: widget.selectedPlaceId,
                      onPlaceSelected: widget.onPlaceSelected,
                    )
                  : const _LocalMapLayer(),
            ),
            if (_showMap && widget.enableLiveMap)
              const Positioned.fill(
                child: IgnorePointer(child: _LocalMapLayer()),
              ),
            if (!_showMap)
              _CompactMapList(
                places: widget.places,
                selectedPlaceId: widget.selectedPlaceId,
                scale: scale,
                onSelected: widget.onPlaceSelected,
              ),
            Positioned(
              right: 18 * scale,
              bottom: 14 * scale,
              child: _MapModeToggle(
                showMap: _showMap,
                scale: scale,
                onChanged: (value) => setState(() => _showMap = value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlutterMapLayer extends StatelessWidget {
  const _FlutterMapLayer({
    required this.places,
    required this.selectedPlaceId,
    required this.onPlaceSelected,
  });

  final List<DiscoverPlace> places;
  final String? selectedPlaceId;
  final ValueChanged<String> onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    final markers = places
        .map((place) {
          return Marker(
            width: 42,
            height: 50,
            point: LatLng(place.latitude, place.longitude),
            child: GestureDetector(
              onTap: () => onPlaceSelected(place.id),
              child: _MapPin(
                icon: _categoryIcon(place.category),
                color: _pinColor(place),
                selected: selectedPlaceId == place.id,
              ),
            ),
          );
        })
        .toList(growable: false);

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(37.5665, 126.9780),
        initialZoom: 12.2,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.norigo',
        ),
        MarkerLayer(markers: markers),
        const Positioned(
          left: 8,
          bottom: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                'OpenStreetMap contributors',
                style: TextStyle(fontSize: 8, color: _DiscoverColors.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalMapLayer extends StatelessWidget {
  const _LocalMapLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(),
      child: Stack(
        children: const [
          Positioned(
            left: 52,
            top: 38,
            child: _PaintedMapPin(icon: Icons.local_cafe_outlined),
          ),
          Positioned(
            left: 150,
            bottom: 26,
            child: _PaintedMapPin(icon: Icons.account_balance_outlined),
          ),
          Positioned(
            right: 96,
            top: 48,
            child: _PaintedMapPin(icon: Icons.camera_alt_outlined),
          ),
          Positioned(
            right: 176,
            top: 32,
            child: _PaintedMapPin(
              icon: Icons.restaurant_menu_rounded,
              green: true,
            ),
          ),
          Positioned(
            right: 198,
            bottom: 40,
            child: _PaintedMapPin(icon: Icons.icecream_outlined, green: true),
          ),
        ],
      ),
    );
  }
}

class _PaintedMapPin extends StatelessWidget {
  const _PaintedMapPin({required this.icon, this.green = false});

  final IconData icon;
  final bool green;

  @override
  Widget build(BuildContext context) {
    return _MapPin(
      icon: icon,
      color: green ? _DiscoverColors.green : _DiscoverColors.purple,
      selected: false,
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    required this.color,
    required this.selected,
  });

  final IconData icon;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 48.0 : 42.0;
    return SizedBox(
      width: size,
      height: size + 8,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.56,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Icon(Icons.location_on_rounded, color: color, size: size),
          Positioned(
            top: size * 0.22,
            child: Icon(icon, color: _DiscoverColors.white, size: size * 0.38),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDF1EA), Color(0xFFEFF9E9), Color(0xFFDDF5FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final blockPaint = Paint()..color = const Color(0x33B5E6A1);
    for (var i = 0; i < 9; i++) {
      final left = (i * 53.0) % size.width;
      final top = (i * 31.0) % size.height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 18, top + 12, 42, 24),
          const Radius.circular(8),
        ),
        blockPaint,
      );
    }

    final river = Paint()
      ..color = const Color(0x88A7E7F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    final riverPath = Path()
      ..moveTo(size.width * 0.55, -12)
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.34,
        size.width + 18,
        size.height * 0.20,
      );
    canvas.drawPath(riverPath, river);

    final road = Paint()
      ..color = _DiscoverColors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    for (var i = -2; i < 9; i++) {
      final y = i * size.height / 6;
      canvas.drawLine(Offset(-10, y), Offset(size.width + 20, y + 72), road);
    }
    for (var i = 0; i < 8; i++) {
      final x = i * size.width / 7;
      canvas.drawLine(Offset(x, -12), Offset(x - 76, size.height + 14), road);
    }

    final blossom = Paint()..color = const Color(0x55F8B8E5);
    for (var i = 0; i < 16; i++) {
      final dx = (i * 41.0 + 8) % size.width;
      final dy = (i * 29.0 + 18) % size.height;
      canvas.drawCircle(Offset(dx, dy), 7, blossom);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompactMapList extends StatelessWidget {
  const _CompactMapList({
    required this.places,
    required this.selectedPlaceId,
    required this.scale,
    required this.onSelected,
  });

  final List<DiscoverPlace> places;
  final String? selectedPlaceId;
  final double scale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _DiscoverColors.paleLavender,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          12 * scale,
          128 * scale,
          12 * scale,
        ),
        itemCount: places.length,
        separatorBuilder: (_, _) => SizedBox(height: 8 * scale),
        itemBuilder: (context, index) {
          final place = places[index];
          final selected = selectedPlaceId == place.id;
          return InkWell(
            onTap: () => onSelected(place.id),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 8 * scale,
              ),
              decoration: BoxDecoration(
                color: selected ? _DiscoverColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Row(
                children: [
                  Icon(
                    _categoryIcon(place.category),
                    color: _pinColor(place),
                    size: 19 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _DiscoverColors.deepPurple,
                        fontSize: 13.5 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapModeToggle extends StatelessWidget {
  const _MapModeToggle({
    required this.showMap,
    required this.scale,
    required this.onChanged,
  });

  final bool showMap;
  final double scale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 * scale,
      width: 128 * scale,
      padding: EdgeInsets.all(5 * scale),
      decoration: BoxDecoration(
        color: _DiscoverColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26 * scale),
        boxShadow: [
          BoxShadow(
            color: _DiscoverColors.shadow.withValues(alpha: 0.12),
            blurRadius: 14 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          _ToggleSegment(
            label: 'Map',
            selected: showMap,
            scale: scale,
            onTap: () => onChanged(true),
          ),
          _ToggleSegment(
            label: 'List',
            selected: !showMap,
            scale: scale,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22 * scale),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _DiscoverColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(22 * scale),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? _DiscoverColors.white
                  : _DiscoverColors.darkMuted,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _AiPicksHeader extends StatelessWidget {
  const _AiPicksHeader({
    required this.scale,
    required this.isLocalFallback,
    required this.onSeeAll,
  });

  final double scale;
  final bool isLocalFallback;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'AI picks for you',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _DiscoverColors.deepPurple,
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: _DiscoverColors.purple,
                    size: 18 * scale,
                  ),
                ],
              ),
              SizedBox(height: 6 * scale),
              Text(
                isLocalFallback
                    ? 'Based on local data and low-crowd insights'
                    : 'Based on KTO and low-crowd insights',
                style: TextStyle(
                  color: _DiscoverColors.muted,
                  fontSize: 13.5 * scale,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: _DiscoverColors.purple,
            padding: EdgeInsets.symmetric(horizontal: 4 * scale),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 24 * scale),
            ],
          ),
        ),
      ],
    );
  }
}

class _HiddenSpotCard extends StatelessWidget {
  const _HiddenSpotCard({
    required this.place,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  final DiscoverPlace place;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(8 * scale),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 124 * scale,
          decoration: BoxDecoration(
            color: _DiscoverColors.white,
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(
              color: selected
                  ? _DiscoverColors.lavender
                  : _DiscoverColors.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _DiscoverColors.shadow.withValues(alpha: 0.10),
                blurRadius: 13 * scale,
                offset: Offset(0, 6 * scale),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(8 * scale),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8 * scale),
                  child: _PlaceImage(
                    place: place,
                    width: 126 * scale,
                    height: 108 * scale,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    5 * scale,
                    9 * scale,
                    8 * scale,
                    8 * scale,
                  ),
                  child: _PlaceCopy(place: place, scale: scale),
                ),
              ),
              _PlaceMetrics(place: place, scale: scale),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  const _PlaceImage({
    required this.place,
    required this.width,
    required this.height,
  });

  final DiscoverPlace place;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.imageUrl;
    final localImageAsset = place.localImageAsset;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _LocalImageFallback(
          asset: localImageAsset,
          width: width,
          height: height,
        ),
      );
    }
    return _LocalImageFallback(
      asset: localImageAsset,
      width: width,
      height: height,
    );
  }
}

class _LocalImageFallback extends StatelessWidget {
  const _LocalImageFallback({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String? asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final assetPath = asset;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _GradientImageFallback(width: width, height: height),
      );
    }
    return _GradientImageFallback(width: width, height: height);
  }
}

class _GradientImageFallback extends StatelessWidget {
  const _GradientImageFallback({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F8DF), Color(0xFFF4EDFF)],
        ),
      ),
      child: const Icon(
        Icons.landscape_outlined,
        color: _DiscoverColors.purple,
      ),
    );
  }
}

class _PlaceCopy extends StatelessWidget {
  const _PlaceCopy({required this.place, required this.scale});

  final DiscoverPlace place;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _DiscoverColors.deepPurple,
            fontSize: 16 * scale,
            height: 1.04,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          place.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _DiscoverColors.darkMuted,
            fontSize: 12.8 * scale,
            height: 1.15,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5 * scale),
        Row(
          children: [
            Icon(
              Icons.directions_walk_rounded,
              size: 16 * scale,
              color: _DiscoverColors.darkMuted,
            ),
            SizedBox(width: 4 * scale),
            Text(
              '${place.walkingMinutes} min',
              style: TextStyle(
                color: _DiscoverColors.darkMuted,
                fontSize: 12.5 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        _TagRow(tags: place.tags.take(3).toList(growable: false), scale: scale),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags, required this.scale});

  final List<String> tags;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tags.length,
        separatorBuilder: (_, _) => SizedBox(width: 6 * scale),
        itemBuilder: (context, index) {
          final tag = tags[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * scale),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tagBackground(tag),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _tagColor(tag),
                fontSize: 10.5 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceMetrics extends StatelessWidget {
  const _PlaceMetrics({required this.place, required this.scale});

  final DiscoverPlace place;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final highLocalRatio = place.localVisitRatio >= 72;
    return SizedBox(
      width: 119 * scale,
      child: Row(
        children: [
          Container(
            width: 1,
            height: 78 * scale,
            color: _DiscoverColors.border,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                9 * scale,
                9 * scale,
                9 * scale,
                7 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (highLocalRatio)
                    _MetricLine(
                      icon: Icons.groups_2_outlined,
                      label: 'High local ratio',
                      color: _DiscoverColors.green,
                      scale: scale,
                    )
                  else ...[
                    Text(
                      'Diversity score',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _DiscoverColors.darkMuted,
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1 * scale),
                    Text(
                      '${place.diversityScore}%',
                      style: TextStyle(
                        color: _DiscoverColors.green,
                        fontSize: 20 * scale,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  SizedBox(height: 7 * scale),
                  Container(height: 1, color: _DiscoverColors.border),
                  SizedBox(height: 6 * scale),
                  _MetricLine(
                    icon: Icons.groups_2_outlined,
                    label: place.crowdLevel,
                    color: _DiscoverColors.green,
                    scale: scale,
                  ),
                  SizedBox(height: 5 * scale),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Local visit ratio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _DiscoverColors.darkMuted,
                            fontSize: 10.5 * scale,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        '${place.localVisitRatio}%',
                        style: TextStyle(
                          color: _DiscoverColors.green,
                          fontSize: 17 * scale,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: _DiscoverColors.orange,
                        size: 18 * scale,
                      ),
                      SizedBox(width: 3 * scale),
                      Flexible(
                        child: Text(
                          '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _DiscoverColors.muted,
                            fontSize: 12.2 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.icon,
    required this.label,
    required this.color,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16 * scale, color: color),
        SizedBox(width: 5 * scale),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5 * scale,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPlaceCard extends StatelessWidget {
  const _LoadingPlaceCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110 * scale,
      margin: EdgeInsets.only(bottom: 10 * scale),
      decoration: BoxDecoration(
        color: _DiscoverColors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: _DiscoverColors.border),
      ),
      child: Center(
        child: SizedBox(
          width: 22 * scale,
          height: 22 * scale,
          child: const CircularProgressIndicator(
            strokeWidth: 2.4,
            color: _DiscoverColors.purple,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.query, required this.scale});

  final String query;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: _DiscoverColors.paleLavender,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: _DiscoverColors.border),
      ),
      child: Text(
        query.isEmpty
            ? 'No hidden spots available yet.'
            : 'No hidden spots matched "$query".',
        style: TextStyle(
          color: _DiscoverColors.deepPurple,
          fontSize: 14 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.message, required this.scale});

  final String message;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: _DiscoverColors.muted,
        fontSize: 11.5 * scale,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RecommendationBanner extends StatelessWidget {
  const _RecommendationBanner({required this.scale, required this.onPressed});

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116 * scale,
      decoration: BoxDecoration(
        color: _DiscoverColors.paleLavender,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: _DiscoverColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8 * scale),
        child: Stack(
          children: [
            Positioned(
              right: -78 * scale,
              bottom: -46 * scale,
              width: 244 * scale,
              height: 138 * scale,
              child: Opacity(
                opacity: 0.42,
                child: Image.asset(
                  _towerAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                16 * scale,
                12 * scale,
                14 * scale,
              ),
              child: Row(
                children: [
                  Image.asset(
                    _pinHelloAsset,
                    width: 68 * scale,
                    height: 68 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.pin_drop_rounded,
                      color: _DiscoverColors.lime,
                      size: 52 * scale,
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Personalized recommendations',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _DiscoverColors.purple,
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          "Tell us what you like and we'll find more hidden gems for you.",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _DiscoverColors.darkMuted,
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w600,
                            height: 1.22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  SizedBox(
                    height: 46 * scale,
                    width: 136 * scale,
                    child: OutlinedButton(
                      onPressed: onPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _DiscoverColors.purple,
                        side: const BorderSide(color: _DiscoverColors.purple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24 * scale),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 11 * scale),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Tell us your preferences',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.6 * scale,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20 * scale),
                        ],
                      ),
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

class _CompactPlaceTile extends StatelessWidget {
  const _CompactPlaceTile({required this.place, required this.onTap});

  final DiscoverPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _PlaceImage(place: place, width: 58, height: 58),
      ),
      title: Text(
        place.name,
        style: const TextStyle(
          color: _DiscoverColors.deepPurple,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text('${place.walkingMinutes} min · ${place.crowdLevel}'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _PlaceDetailSheet extends StatelessWidget {
  const _PlaceDetailSheet({
    required this.place,
    required this.onSave,
    required this.onAddToItinerary,
  });

  final DiscoverPlace place;
  final VoidCallback onSave;
  final VoidCallback onAddToItinerary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _PlaceImage(place: place, width: double.infinity, height: 190),
        ),
        const SizedBox(height: 18),
        Text(
          place.name,
          style: const TextStyle(
            color: _DiscoverColors.deepPurple,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          place.description,
          style: const TextStyle(
            color: _DiscoverColors.darkMuted,
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: place.tags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  backgroundColor: _tagBackground(tag),
                  labelStyle: TextStyle(
                    color: _tagColor(tag),
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide.none,
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        _DetailMetricGrid(place: place),
        const SizedBox(height: 14),
        Text(
          place.sourceBadge,
          style: const TextStyle(
            color: _DiscoverColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onSave,
          icon: Icon(
            place.isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
          ),
          label: Text(place.isSaved ? 'Saved place' : 'Save place'),
          style: FilledButton.styleFrom(
            backgroundColor: _DiscoverColors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAddToItinerary,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Add to itinerary'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _DiscoverColors.purple,
            side: const BorderSide(color: _DiscoverColors.purple),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

class _DetailMetricGrid extends StatelessWidget {
  const _DetailMetricGrid({required this.place});

  final DiscoverPlace place;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Diversity score', '${place.diversityScore}%'),
      ('Local visit ratio', '${place.localVisitRatio}%'),
      ('Crowd level', place.crowdLevel),
      ('Rating', '${place.rating.toStringAsFixed(1)} (${place.reviewCount})'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: metrics
          .map((metric) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _DiscoverColors.paleLavender,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    metric.$1,
                    style: const TextStyle(
                      color: _DiscoverColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metric.$2,
                    style: const TextStyle(
                      color: _DiscoverColors.deepPurple,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

Color _pinColor(DiscoverPlace place) {
  return switch (place.category) {
    DiscoverCategory.localFood => _DiscoverColors.green,
    DiscoverCategory.dessert => _DiscoverColors.green,
    _ => _DiscoverColors.purple,
  };
}

Color _tagBackground(String tag) {
  final normalized = tag.toLowerCase();
  if (normalized.contains('quiet')) return _DiscoverColors.softGreen;
  if (normalized.contains('sweet')) return const Color(0xFFFFE6F0);
  if (normalized.contains('photo')) return const Color(0xFFDFF0FF);
  return _DiscoverColors.lavender;
}

Color _tagColor(String tag) {
  final normalized = tag.toLowerCase();
  if (normalized.contains('quiet')) return _DiscoverColors.green;
  if (normalized.contains('sweet')) return const Color(0xFFE43E7D);
  if (normalized.contains('photo')) return _DiscoverColors.blue;
  return _DiscoverColors.purple;
}
