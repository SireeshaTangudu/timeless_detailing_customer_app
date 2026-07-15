import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_button.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_textfield.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final success = await authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authController.errorMessage ??
                  'Login failed. Please check credentials.',
              style: GoogleFonts.montserrat(
                color: AppTheme.background,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reset Password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: AppTheme.divider),
                const SizedBox(height: 12),
                Text(
                  'Enter the email associated with your portal. We will request Odoo to send a reset link.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: resetEmailController,
                  hintText: 'Enter your email',
                  labelText: 'Email Address',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Consumer<AuthController>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      text: 'SEND RESET LINK',
                      isLoading: auth.isLoading,
                      onPressed: () async {
                        if (resetFormKey.currentState!.validate()) {
                          final success = await auth.resetPassword(
                            resetEmailController.text.trim(),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context); // Close sheet

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'A reset link has been requested from Odoo.'
                                    : auth.errorMessage ??
                                          'Failed to send reset link.',
                                style: GoogleFonts.montserrat(
                                  color: success
                                      ? Colors.white
                                      : AppTheme.background,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: success
                                  ? AppTheme.success
                                  : AppTheme.primary,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient & Cars subtle silhouette representation
          Positioned.fill(
            child: Container(
              color: AppTheme.background,
              child: Opacity(
                opacity: 0.12,
                child: Image.network(
                  'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800&auto=format&fit=crop&q=80',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: -size.height * 0.25,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Brand Logo/Header
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primary,
                                      width: 1.5,
                                    ),
                                    color: AppTheme.surface,
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_outlined,
                                    size: 40,
                                    color: AppTheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter your email',
                        labelText: 'Email Address',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Enter your password',
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordSheet,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Login Button
                      Consumer<AuthController>(
                        builder: (context, auth, _) {
                          return CustomButton(
                            text: 'SIGN IN',
                            isLoading: auth.isLoading,
                            onPressed: _handleLogin,
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // SignUp Redirect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Portal notification
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
