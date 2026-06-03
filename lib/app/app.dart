import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/localization/app_locale_controller.dart';
import 'package:norigo/l10n/app_localizations.dart';

class NoriGoApp extends StatefulWidget {
  const NoriGoApp({super.key, this.localeController});

  final AppLocaleController? localeController;

  @override
  State<NoriGoApp> createState() => _NoriGoAppState();
}

class _NoriGoAppState extends State<NoriGoApp> {
  late AppLocaleController _localeController;
  late bool _ownsLocaleController;

  @override
  void initState() {
    super.initState();
    _ownsLocaleController = widget.localeController == null;
    _localeController = widget.localeController ?? AppLocaleController();
  }

  @override
  void didUpdateWidget(covariant NoriGoApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localeController == widget.localeController) return;
    if (_ownsLocaleController) _localeController.dispose();
    _ownsLocaleController = widget.localeController == null;
    _localeController = widget.localeController ?? AppLocaleController();
  }

  @override
  void dispose() {
    if (_ownsLocaleController) _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _localeController,
      child: AnimatedBuilder(
        animation: _localeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'NoriGo',
            debugShowCheckedModeBanner: false,
            theme: NoriGoTheme.light(),
            locale: _localeController.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: AppRoutes.splash,
            routes: AppRouter.routes,
          );
        },
      ),
    );
  }
}
