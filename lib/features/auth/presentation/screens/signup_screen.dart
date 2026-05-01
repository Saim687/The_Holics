import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/core/constants/app_constants.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/shared/widgets/holics_buttons.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/services/session_service.dart';
import 'package:the_holics/shared/models/user_model.dart' as user_model;

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  String? _errorMessage;
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      final userCredential = await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Create user document in Firestore
      final newUser = user_model.User(
        id: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: phone,
        role: 'member',
        createdAt: DateTime.now(),
        bodyHolicsRegistrationFeePaid: false,
      );
      await firestoreService.createUser(userCredential.user!.uid, newUser);
      await _sessionService.setSelectedPanel(SessionService.panelMember);

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      print('Signup error: $e');
      String errorMsg;
      if (e is FirebaseAuthException) {
        errorMsg = '[${e.code}] ${e.message ?? 'Authentication error'}';
      } else {
        final raw = e.toString().trim();
        if (raw == 'Error' || raw == 'Exception: Error') {
          errorMsg = 'Firebase web auth error. Verify Email/Password is enabled and localhost is in Authorized domains.';
        } else {
          errorMsg = '${e.runtimeType}: $raw';
        }
      }
      setState(() => _errorMessage = errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Account'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Holics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your account to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // Name field
            HolicsTextField(
              label: 'Full Name',
              placeholder: 'John Doe',
              controller: _nameController,
            ),
            const SizedBox(height: 16),

            // Email field
            HolicsTextField(
              label: 'Email',
              placeholder: AppStrings.emailPlaceholder,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone field
            HolicsTextField(
              label: 'Phone Number',
              placeholder: '+92 300 1234567',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Password field
            HolicsTextField(
              label: 'Password',
              placeholder: AppStrings.passwordPlaceholder,
              controller: _passwordController,
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Confirm password field
            HolicsTextField(
              label: 'Confirm Password',
              placeholder: AppStrings.confirmPasswordPlaceholder,
              controller: _confirmPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sign up button
            HolicsButton(
              label: 'Create Account',
              isLoading: _isLoading,
              onPressed: _handleSignup,
            ),
            const SizedBox(height: 16),

            // Back to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: AppTheme.bodyHolicsOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
