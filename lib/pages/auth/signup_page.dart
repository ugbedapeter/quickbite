// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickbite/services/auth_provider.dart';
import 'package:quickbite/theme/app_colors.dart';
import 'package:quickbite/util/offline_guard.dart';
import 'package:quickbite/widgets/custom_button.dart';
import 'package:quickbite/widgets/custom_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _userNameFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  final _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _fadeController;
  // late AnimationController _slideController;
  // late AnimationController _formController;
  late AnimationController _buttonController;
  @override
  void initState() {
    super.initState();

    // Fade controller starts at fully visible (value = 1.0) so reverse() will animate out
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );

    // Button press animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _emailController.dispose();
    _userNameFocusNode.dispose();
    _passwordController.dispose();

    // Dispose animation controllers
    _fadeController.dispose();
    _buttonController.dispose();

    super.dispose();
  }

  // Future<void> _signUp() async {
  //   // Basic form validation
  //   if (_userNameController.text.isEmpty ||
  //       _emailController.text.isEmpty ||
  //       _passwordController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please fill in all fields.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   if (_passwordController.text != _confirmPasswordController.text) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Passwords do not match.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   if (!_agreeToTerms) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please agree to the Terms and Conditions.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   // If validation passes, call the provider
  //   final authProvider = context.read<AuthProvider>();
  //   await authProvider.signUp(
  //     name: _userNameController.text.trim(),
  //     email: _emailController.text.trim(),
  //     password: _passwordController.text,
  //     context: context,
  //   );
  // }
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (!OfflineGuard.ensureOnline(
        context,
        message: 'Connect to the internet to sign up',
      )) {
        return;
      }
      // Button press animation
      _buttonController.forward().then((_) {
        _buttonController.reverse();
      });

      final authProvider = context.read<AuthProvider>();
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _userNameController.text.trim(),

        context: context,
      );

      if (authProvider.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else if (authProvider.currentUser != null && mounted) {
        // Animate out before navigation
        await _fadeController.reverse();
        context.go('/');
      }
    } else {
      // Shake animation for validation errors
      _shakeForm();
    }
  }

  void _shakeForm() {
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticIn),
    );

    animationController.addListener(() {
      setState(() {});
    });

    animationController.forward().then((_) {
      animationController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withAlpha(90),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (authProvider.error != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.error!),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    authProvider.clearError();
                  }
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 90,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Create an account to get started!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(250),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        CustomTextField(
                          controller: _userNameController,
                          focusNode: _userNameFocusNode,
                          hintText: 'Username',
                          keyboardType: TextInputType.name,
                          cursorColor: AppColors.primaryBlue,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        CustomTextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          hintText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: AppColors.primaryBlue,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        CustomTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          hintText: 'Password',
                          cursorColor: AppColors.primaryBlue,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          hintText: 'Confirm Password',
                          cursorColor: AppColors.primaryBlue,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                              activeColor: AppColors.primaryBlue,
                              checkColor: Colors.white,
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {},
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        CustomButton(
                          height: 50,
                          width: double.infinity,
                          onPressed: authProvider.isLoading ? null : _signUp,
                          child: authProvider.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'OR SIGN UP WITH',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // ... (Social login buttons can go here)
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/login'),
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -190,
            left: -50,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -190,
            left: -40,
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withAlpha(90),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
*/
