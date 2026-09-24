import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .signInWithUsernameOrEmail(
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (!success && mounted) {
      final authState = ref.read(authProvider);
      if (authState.errorMessage != null) {
        AppToast.show(context, authState.errorMessage!, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Full-screen background image ──
            Image.asset(
              'assets/bg.png',
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
            ),

            // ── Dark gradient overlay ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xDD0F172A),
                    Color(0xBB0F172A),
                    Color(0x880F172A),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // ── Scrollable content ──
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Logo ──
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),

                        // ── App Name ──
                        Text(
                          'ئایتی سەنتەر',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            fontWeight: FontWeight.w700,
                            fontSize: 34,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 12),
                            ],
                          ),
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(height: 6),

                        Text(
                          'سیستەمی بەڕێوەبردنی حیساباتی دوکانی مۆبایل',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 250.ms),

                        const SizedBox(height: 36),

                        // ── Glass Card ──
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xCC0F172A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'چوونە ژوورەوە',
                                      style: TextStyle(
                                        fontFamily: 'NRT',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 26),

                                // ── Username Field ──
                                _GlassInput(
                                  controller: _usernameController,
                                  focusNode: _usernameFocus,
                                  label: 'ناوی بەکارهێنەر',
                                  hint: 'نمونە: admin',
                                  icon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_passwordFocus);
                                  },
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'تکایە ناوی بەکارهێنەر بنووسە';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ── Password Field ──
                                _GlassInput(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  label: 'وشەی نهێنی',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!authState.isLoading) _handleSignIn();
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'تکایە وشەی نهێنی بنووسە';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                // ── Sign In Button ──
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: authState.isLoading
                                        ? null
                                        : _handleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      shadowColor: AppTheme.primaryColor
                                          .withValues(alpha: 0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: authState.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'چوونە ژوورەوە',
                                            style: TextStyle(
                                              fontFamily: 'NRT',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().slideY(
                          begin: 0.08,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const _GlassInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    required this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rabar',
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Rabar',
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Rabar',
              color: Colors.white30,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            errorStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
