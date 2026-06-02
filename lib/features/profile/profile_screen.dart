import 'package:flutter/material.dart';
import 'package:norigo/features/my/presentation/my_page_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyPageScreen(showBottomNavigation: false);
  }
}
