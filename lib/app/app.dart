import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/app/theme.dart';

class NoriGoApp extends StatelessWidget {
  const NoriGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoriGo',
      debugShowCheckedModeBanner: false,
      theme: NoriGoTheme.light(),
      initialRoute: AppRoutes.splash,
      routes: AppRouter.routes,
    );
  }
}
