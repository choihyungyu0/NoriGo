import 'package:flutter/material.dart';
import 'package:norigo/app/app.dart';
import 'package:norigo/core/localization/app_locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = AppLocaleController();
  await localeController.load();
  runApp(NoriGoApp(localeController: localeController));
}
