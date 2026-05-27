import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:norigo/app/router.dart';

const _defaultLogoAsset = 'assets/images/splash/norigo_logo_full.png';
const _defaultHeaderAsset = 'assets/images/auth/login_header_bg.png';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.logoAsset = _defaultLogoAsset,
    this.headerAsset = _defaultHeaderAsset,
  });

  final String logoAsset;
  final String headerAsset;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _selectedTab = _AuthTab.login;
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectTab(_AuthTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_selectedTab == _AuthTab.signUp) {
      _showSnackBar('Sign up flow will be added soon.');
      return;
    }

    if (AppRouter.routes.containsKey(AppRoutes.tripBasics)) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.tripBasics);
      return;
    }

    _showSnackBar(
      'Login flow is ready. Trip basics route is not connected yet.',
    );
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
        systemNavigationBarColor: _AuthColors.white,
      ),
      child: Scaffold(
        backgroundColor: _AuthColors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final pageWidth = math.min(width, 520.0);
              final scale = (pageWidth / 430.0).clamp(0.86, 1.06);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height),
                  child: Center(
                    child: SizedBox(
                      width: pageWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          22 * scale,
                          28 * scale,
                          22 * scale,
                          24 * scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LoginHeader(
                              logoAsset: widget.logoAsset,
                              headerAsset: widget.headerAsset,
                              scale: scale,
                            ),
                            SizedBox(height: 18 * scale),
                            _AuthFormCard(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              selectedTab: _selectedTab,
                              obscurePassword: _obscurePassword,
                              scale: scale,
                              onTabChanged: _selectTab,
                              onTogglePassword: _togglePasswordVisibility,
                              onSubmit: _submit,
                              onForgotPassword: () {
                                _showSnackBar(
                                  'Password reset will be connected later.',
                                );
                              },
                              onOutlineTap: () {
                                _selectTab(
                                  _selectedTab == _AuthTab.login
                                      ? _AuthTab.signUp
                                      : _AuthTab.login,
                                );
                              },
                              onGoogleTap: () {
                                _showSnackBar(
                                  'Google login will be connected later.',
                                );
                              },
                              onAppleTap: () {
                                _showSnackBar(
                                  'Apple login will be connected later.',
                                );
                              },
                            ),
                            SizedBox(height: 18 * scale),
                            _BottomInfoCard(scale: scale),
                          ],
                        ),
                      ),
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

enum _AuthTab { login, signUp }

class _AuthColors {
  const _AuthColors._();

  static const white = Color(0xFFFFFFFF);
  static const purple = Color(0xFF6A00FF);
  static const deepPurple = Color(0xFF24104F);
  static const lime = Color(0xFFCCFF00);
  static const blue = Color(0xFF007BFF);
  static const lightLavender = Color(0xFFF3EDFF);
  static const borderGray = Color(0xFFE5E1EE);
  static const mutedText = Color(0xFF5D567A);
  static const placeholder = Color(0xFF9690A9);
  static const shadow = Color(0xFF7B69A5);
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({
    required this.logoAsset,
    required this.headerAsset,
    required this.scale,
  });

  final String logoAsset;
  final String headerAsset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 38 * scale,
            right: -22 * scale,
            width: 292 * scale,
            height: 210 * scale,
            child: Opacity(
              opacity: 0.82,
              child: Image.asset(
                headerAsset,
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) {
                  return const _HeaderFallback();
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _BrandLogo(asset: logoAsset, scale: scale),
          ),
          Positioned(
            left: 0,
            right: 120 * scale,
            bottom: 22 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WelcomeTitle(),
                SizedBox(height: 14 * scale),
                Text(
                  'Crowd-free routes and\ncultural help in Korea.',
                  style: TextStyle(
                    color: _AuthColors.mutedText,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.asset, required this.scale});

  final String asset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176 * scale,
      height: 68 * scale,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (_, _, _) => const _LogoFallback(),
      ),
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
              style: TextStyle(color: _AuthColors.lime),
            ),
          ],
        ),
        style: TextStyle(
          color: _AuthColors.deepPurple,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Welcome to\nNori'),
            TextSpan(
              text: 'Go',
              style: TextStyle(color: _AuthColors.lime),
            ),
          ],
        ),
        style: TextStyle(
          color: _AuthColors.deepPurple,
          fontSize: 52,
          fontWeight: FontWeight.w900,
          height: 1.12,
        ),
      ),
    );
  }
}

class _HeaderFallback extends StatelessWidget {
  const _HeaderFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _AuthColors.lightLavender,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.landscape_rounded,
        color: _AuthColors.purple,
        size: 64,
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.selectedTab,
    required this.obscurePassword,
    required this.scale,
    required this.onTabChanged,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onOutlineTap,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final _AuthTab selectedTab;
  final bool obscurePassword;
  final double scale;
  final ValueChanged<_AuthTab> onTabChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onOutlineTap;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  @override
  Widget build(BuildContext context) {
    final isLogin = selectedTab == _AuthTab.login;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: _AuthColors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _AuthColors.shadow.withValues(alpha: 0.12),
            blurRadius: 28 * scale,
            offset: Offset(0, 14 * scale),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _SegmentedAuthTabs(
              selectedTab: selectedTab,
              scale: scale,
              onChanged: onTabChanged,
            ),
            SizedBox(height: 16 * scale),
            _AuthTextField(
              key: const ValueKey('emailField'),
              controller: emailController,
              hintText: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email is required.';
                if (!email.contains('@')) return 'Enter a valid email.';
                return null;
              },
            ),
            SizedBox(height: 12 * scale),
            _AuthTextField(
              key: const ValueKey('passwordField'),
              controller: passwordController,
              hintText: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'Password is required.';
                if (password.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
              suffixIcon: IconButton(
                key: const ValueKey('togglePasswordButton'),
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: _AuthColors.purple,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
            _PrimaryAuthButton(
              key: const ValueKey('authSubmitButton'),
              text: isLogin ? 'Log in' : 'Create account',
              onTap: onSubmit,
            ),
            SizedBox(height: 12 * scale),
            _OutlineAuthButton(
              text: isLogin ? 'Create account' : 'Log in instead',
              onTap: onOutlineTap,
            ),
            SizedBox(height: 22 * scale),
            const _DividerText(),
            SizedBox(height: 14 * scale),
            _SocialLoginButton(
              key: const ValueKey('googleLoginButton'),
              text: 'Continue with Google',
              icon: const _GoogleMark(),
              onTap: onGoogleTap,
            ),
            SizedBox(height: 10 * scale),
            _SocialLoginButton(
              key: const ValueKey('appleLoginButton'),
              text: 'Continue with Apple',
              icon: const Icon(Icons.apple, color: Colors.black, size: 28),
              onTap: onAppleTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedAuthTabs extends StatelessWidget {
  const _SegmentedAuthTabs({
    required this.selectedTab,
    required this.scale,
    required this.onChanged,
  });

  final _AuthTab selectedTab;
  final double scale;
  final ValueChanged<_AuthTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 * scale,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _AuthColors.lightLavender,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _TabButton(
            key: const ValueKey('loginTab'),
            label: 'Log in',
            selected: selectedTab == _AuthTab.login,
            onTap: () => onChanged(_AuthTab.login),
          ),
          _TabButton(
            key: const ValueKey('signUpTab'),
            label: 'Sign up',
            selected: selectedTab == _AuthTab.signUp,
            onTap: () => onChanged(_AuthTab.signUp),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: selected
                ? const LinearGradient(
                    colors: [_AuthColors.purple, Color(0xFF4A12E6)],
                  )
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _AuthColors.white : _AuthColors.mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: _AuthColors.purple,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _AuthColors.placeholder,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: _AuthColors.placeholder),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _AuthColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: _inputBorder(_AuthColors.borderGray),
        enabledBorder: _inputBorder(_AuthColors.borderGray),
        focusedBorder: _inputBorder(_AuthColors.purple),
        errorBorder: _inputBorder(Colors.redAccent),
        focusedErrorBorder: _inputBorder(Colors.redAccent),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: 1.1),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [_AuthColors.purple, Color(0xFF4A12E6)],
          ),
          boxShadow: [
            BoxShadow(
              color: _AuthColors.purple.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: _AuthColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineAuthButton extends StatelessWidget {
  const _OutlineAuthButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AuthColors.purple,
          side: const BorderSide(color: _AuthColors.purple, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: _AuthColors.borderGray)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: _AuthColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: _AuthColors.borderGray)),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AuthColors.deepPurple,
          side: const BorderSide(color: _AuthColors.borderGray, width: 1.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 34, child: Center(child: icon)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: _AuthColors.blue,
        fontSize: 23,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  const _BottomInfoCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: _AuthColors.lightLavender.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _AuthColors.borderGray),
      ),
      child: Row(
        children: [
          Container(
            width: 64 * scale,
            height: 64 * scale,
            decoration: const BoxDecoration(
              color: _AuthColors.white,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: _AuthColors.purple,
                  size: 34 * scale,
                ),
                Positioned(
                  bottom: 12 * scale,
                  child: Icon(
                    Icons.groups_rounded,
                    color: _AuthColors.purple,
                    size: 28 * scale,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avoid crowds + understand culture in one app.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AuthColors.deepPurple,
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  'Smart routes, real-time insights, and local help made for travelers like you.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AuthColors.mutedText,
                    fontSize: 13.5 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: _AuthColors.purple,
            size: 32,
          ),
        ],
      ),
    );
  }
}
