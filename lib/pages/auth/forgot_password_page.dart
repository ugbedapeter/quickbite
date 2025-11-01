import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite/theme/app_colors.dart';
import 'package:quickbite/widgets/custom_button.dart';
import 'package:quickbite/widgets/custom_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFocusNode = FocusNode();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 50,
            left: 15,
            child: GestureDetector(
              onTap: () {
                context.pop();
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back),
              ),
            ),
          ),
          Positioned(
            top: -70,
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
            top: -70,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 90),
              child: Column(
                children: [
                  Text(
                    'Forgot Password',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Enter your email address to reset your password below.',
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
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    hintText: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: AppColors.primaryBlue,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 25),
                  CustomButton(
                    height: 50,
                    width: double.infinity,
                    onPressed: () {
                      // TODO: Implement login logic
                    },
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Go back to ",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/signin'),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryBlue,
                      decorationThickness: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -450,
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
            bottom: -450,
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
