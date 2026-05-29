import 'package:flutter/material.dart';
import 'package:norigo/app/app.dart';
import 'package:norigo/core/auth/demo_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoAuthService.initializeIfConfigured();
  runApp(const NoriGoApp());
}
