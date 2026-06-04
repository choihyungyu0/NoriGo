import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/core/location/current_location_service.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
import 'package:norigo/features/onboarding/application/onboarding_preferences_store.dart';
import 'package:norigo/features/onboarding/application/user_consent_store.dart';
import 'package:norigo/features/onboarding/data/user_consent_repository.dart';
import 'package:norigo/features/onboarding/domain/user_consent.dart';

class DataLocationConsentScreen extends StatefulWidget {
  const DataLocationConsentScreen({
    super.key,
    this.repository = const SupabaseUserConsentRepository(),
    this.locationService,
    this.onComplete,
  });

  final UserConsentRepository repository;
  final CurrentLocationService? locationService;
  final VoidCallback? onComplete;

  @override
  State<DataLocationConsentScreen> createState() =>
      _DataLocationConsentScreenState();
}

class _DataLocationConsentScreenState extends State<DataLocationConsentScreen> {
  late final CurrentLocationService _locationService;
  UserConsent _consent = const UserConsent();
  var _savingData = false;
  var _requestingLocation = false;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? CurrentLocationService();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final consent = await UserConsentStore.loadLocal();
    if (mounted) setState(() => _consent = consent);
  }

  Future<void> _agreeDataConsent() async {
    await _saveConsent(
      _consent.copyWith(
        dataConsent: true,
        dataConsentAcceptedAt: DateTime.now().toUtc(),
      ),
      savingData: true,
    );
  }

  Future<void> _skipDataConsent() async {
    await _saveConsent(_consent.copyWith(dataConsent: false), savingData: true);
  }

  Future<void> _allowLocation() async {
    setState(() => _requestingLocation = true);
    final result = await _locationService.getCurrentLocation(
      requestPermission: true,
    );
    final location = result.location;
    final next = location == null
        ? _consent.copyWith(
            locationConsent: false,
            locationPermissionStatus: result.permissionStatus ?? 'denied',
            clearLatestLocation: true,
          )
        : _consent.copyWith(
            locationConsent: true,
            locationConsentAcceptedAt: DateTime.now().toUtc(),
            locationPermissionStatus: result.permissionStatus ?? 'granted',
            latestLocation: location,
          );

    await UserConsentStore.saveLocal(next);
    await widget.repository.saveConsent(next);
    if (!mounted) return;
    setState(() {
      _consent = next;
      _requestingLocation = false;
    });
    final message = location == null
        ? '${context.l10n.locationPermissionDenied}. '
              '${context.l10n.usingBaseLocationInstead}.'
        : context.l10n.consentSaved;
    _showSnackBar(message);
  }

  Future<void> _skipLocation() async {
    final next = _consent.copyWith(
      locationConsent: false,
      locationPermissionStatus: 'not_now',
      clearLatestLocation: true,
    );
    await _saveConsent(next, requestingLocation: true);
  }

  Future<void> _saveConsent(
    UserConsent consent, {
    bool savingData = false,
    bool requestingLocation = false,
  }) async {
    setState(() {
      _savingData = savingData;
      _requestingLocation = requestingLocation;
    });
    await UserConsentStore.saveLocal(consent);
    final result = await widget.repository.saveConsent(consent);
    if (!mounted) return;
    setState(() {
      _consent = consent;
      _savingData = false;
      _requestingLocation = false;
    });
    _showSnackBar(result.message ?? context.l10n.consentSaved);
  }

  void _continue() {
    final onComplete = widget.onComplete;
    if (onComplete != null) {
      onComplete();
      return;
    }

    final routeArguments =
        ModalRoute.of(context)?.settings.arguments ??
        OnboardingPreferencesStore.itineraryRequest();
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.itineraryPlanner,
        (route) => false,
        arguments: routeArguments,
      );
    } on FlutterError {
      _showSnackBar(context.l10n.setupCompletePending);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final scale = (width / 430.0).clamp(0.90, 1.0).toDouble();
              return Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      22 * scale,
                      22 * scale,
                      22 * scale,
                      106 * scale,
                    ),
                    children: [
                      Text(
                        l10n.dataLocationConsent,
                        style: TextStyle(
                          color: const Color(0xFF21045D),
                          fontSize: 32 * scale,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                      ),
                      SizedBox(height: 22 * scale),
                      _ConsentSection(
                        icon: Icons.tune_rounded,
                        title: l10n.dataUseConsent,
                        body: l10n.dataUseConsentBody,
                        status: _consent.dataConsent ? l10n.selected : null,
                        primaryLabel: l10n.agree,
                        secondaryLabel: l10n.skipForNow,
                        primaryKey: const ValueKey('agreeDataConsentButton'),
                        secondaryKey: const ValueKey('skipDataConsentButton'),
                        loading: _savingData,
                        onPrimary: _agreeDataConsent,
                        onSecondary: _skipDataConsent,
                      ),
                      SizedBox(height: 14 * scale),
                      _ConsentSection(
                        icon: Icons.my_location_rounded,
                        title: l10n.locationUseConsent,
                        body: l10n.locationUseConsentBody,
                        status: _consent.locationConsent
                            ? l10n.useMyLocation
                            : _consent.locationPermissionStatus,
                        primaryLabel: l10n.allowLocation,
                        secondaryLabel: l10n.notNow,
                        primaryKey: const ValueKey('allowLocationButton'),
                        secondaryKey: const ValueKey('skipLocationButton'),
                        loading: _requestingLocation,
                        onPrimary: _allowLocation,
                        onSecondary: _skipLocation,
                      ),
                    ],
                  ),
                  Positioned(
                    left: 22 * scale,
                    right: 22 * scale,
                    bottom: 16 * scale,
                    child: SizedBox(
                      height: 54 * scale,
                      child: FilledButton(
                        key: const ValueKey('continueConsentButton'),
                        onPressed: _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5717D9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8 * scale),
                          ),
                        ),
                        child: Text(
                          l10n.consentContinue,
                          style: TextStyle(
                            fontSize: 17 * scale,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryKey,
    required this.secondaryKey,
    required this.loading,
    required this.onPrimary,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? status;
  final String primaryLabel;
  final String secondaryLabel;
  final Key primaryKey;
  final Key secondaryKey;
  final bool loading;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final disabled = loading;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E3F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8DF),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(icon, color: const Color(0xFF5717D9)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF21045D),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          status!,
                          style: const TextStyle(
                            color: Color(0xFF2DAF3A),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF333553),
                fontSize: 15,
                height: 1.38,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: primaryKey,
                    onPressed: disabled ? null : onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5717D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(primaryLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: secondaryKey,
                    onPressed: disabled ? null : onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5717D9),
                      side: const BorderSide(color: Color(0xFF5717D9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(secondaryLabel),
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
