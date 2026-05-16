import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/constants/app_constants.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/nori_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'emma@example.com');
  final _passwordController = TextEditingController(text: 'norigo-demo');
  final _supabaseConfig = const SupabaseConfig();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continueWithEmail() {
    Navigator.of(context).pushNamed(AppRoutes.tripBasics);
  }

  void _showPlaceholder(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider login will connect after OAuth is configured.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: NoriGoColors.sea,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.explore, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      AppConstants.tagline,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Avoid crowds + understand culture in one app.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Plan calm Korean routes, dodge hidden waitlists, and scan cultural context in real time.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            NoriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 18),
                  NoriButton(
                    label: 'Log in or sign up',
                    icon: Icons.login,
                    onPressed: _continueWithEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPlaceholder('Google'),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Google'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPlaceholder('Apple'),
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            NoriCard(
              color: NoriGoColors.sky,
              borderColor: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storage_outlined, color: NoriGoColors.sea),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _supabaseConfig.statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
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
