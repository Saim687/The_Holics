import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/core/constants/app_constants.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/shared/widgets/holics_buttons.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/services/session_service.dart';
import 'package:the_holics/shared/models/user_model.dart' as user_model;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({bool adminLogin = false}) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    await _handleLoginWithCredentials(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      adminLogin: adminLogin,
    );
  }

  Future<void> _handleLoginWithCredentials({
    required String email,
    required String password,
    bool adminLogin = false,
  }) async {

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      await authService.signInWithEmailPassword(
        email,
        password,
      );

      // Migrate user to Firestore if they don't exist (for existing Firebase Auth users)
      final firebaseUser = authService.currentUser;
      if (firebaseUser != null) {
        final existingUser = await firestoreService.getUser(firebaseUser.uid);
        if (existingUser == null) {
          // User exists in Firebase Auth but not in Firestore - create them
          final newUser = user_model.User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
            email: firebaseUser.email ?? email,
            role: 'member',
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          );
          await firestoreService.createUser(firebaseUser.uid, newUser);
        }
      }

      // Admin login path
      if (adminLogin) {
        bool isAdminAllowed = false;
        final uid = authService.currentUser?.uid;
        if (uid != null) {
          final appUser = await firestoreService.getUser(uid);
          final role = appUser?.role.toLowerCase() ?? 'member';
          isAdminAllowed = role == 'admin';
        }

        // Reject non-admin attempts
        if (!isAdminAllowed) {
          await authService.signOut();
          setState(() {
            _isLoading = false;
            _errorMessage = 'This account is not an admin account.';
          });
          return;
        }

        // Route to admin - now safe from GoRouter redirect interference
        if (mounted) {
          await _sessionService.setSelectedPanel(SessionService.panelAdmin);
          context.go(AppRoutes.admin);
        }
      } else {
        // Member login path
        if (mounted) {
          await _sessionService.setSelectedPanel(SessionService.panelMember);
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      print('Login error: $e');
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
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAdminAccessDialog() async {
    final result = await showDialog<_AdminCredentials>(
      context: context,
      builder: (_) => const _AdminAccessDialog(),
    );

    if (result == null || !mounted) return;

    setState(() => _isAdmin = true);
    await _handleLoginWithCredentials(
      email: result.email,
      password: result.password,
      adminLogin: true,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    await _sessionService.setGooglePhonePending(true);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAdmin = false;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      await authService.signInWithGoogle();

      final firebaseUser = authService.currentUser;
      if (firebaseUser == null) {
        throw 'Google sign-in failed. Please try again.';
      }

      var appUser = await firestoreService.getUser(firebaseUser.uid);
      if (appUser == null) {
        final newUser = user_model.User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'User',
          email: firebaseUser.email ?? '',
          role: 'member',
          photoUrl: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
        await firestoreService.createUser(firebaseUser.uid, newUser);
        appUser = newUser;
      }

      final phoneNumber = await _ensurePhoneNumber(
        existingPhoneNumber: appUser.phoneNumber,
      );

      if (phoneNumber == null) {
        await authService.signOut();
        await _sessionService.setGooglePhonePending(false);
        if (mounted) {
          setState(() {
            _errorMessage = 'Phone number is required to continue with Google sign-in.';
          });
        }
        return;
      }

      if (phoneNumber != appUser.phoneNumber) {
        await firestoreService.updateUser(firebaseUser.uid, {
          'phoneNumber': phoneNumber,
        });
      }

      if (!mounted) return;
      await _sessionService.setSelectedPanel(SessionService.panelMember);
      await _sessionService.setGooglePhonePending(false);
      context.go(AppRoutes.home);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      await _sessionService.setGooglePhonePending(false);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _ensurePhoneNumber({
    required String? existingPhoneNumber,
  }) async {
    final currentPhone = existingPhoneNumber?.trim() ?? '';
    if (currentPhone.isNotEmpty) {
      return currentPhone;
    }

    if (!mounted) return null;

    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('Add your phone number'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+92 300 1234567',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Phone number is required';
                }
                if (text.length < 8) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(phoneController.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    phoneController.dispose();
    return result?.trim();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.bodyHolicsOrange.withOpacity(0.14),
                  AppTheme.darkBg,
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bodyHolicsOrange.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.skinHolichPink.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HolicsLogo(size: 76),
                        const SizedBox(height: 26),
                        Text(
                          AppStrings.welcomeBack,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.signInToAccount,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _BrandPill(
                              label: 'Body Holics',
                              isSelected: !_isAdmin,
                              color: AppTheme.bodyHolicsOrange,
                              onTap: () {},
                            ),
                            const SizedBox(width: 12),
                            _BrandPill(
                              label: 'Skin Holics',
                              isSelected: false,
                              color: AppTheme.skinHolichPink,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        HolicsTextField(
                          label: 'Email',
                          placeholder: AppStrings.emailPlaceholder,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        HolicsTextField(
                          label: 'Password',
                          placeholder: AppStrings.passwordPlaceholder,
                          controller: _passwordController,
                          obscureText: true,
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(AppRoutes.passwordReset),
                            child: Text(
                              AppStrings.forgotPassword,
                              style: const TextStyle(
                                color: AppTheme.bodyHolicsOrange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
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
                          const SizedBox(height: 14),
                        ],
                        HolicsButton(
                          label: AppStrings.signInAsMember,
                          isLoading: _isLoading,
                          onPressed: () {
                            setState(() => _isAdmin = false);
                            _handleLogin(adminLogin: false);
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(isMobile ? double.infinity : 150, 56),
                            backgroundColor: AppTheme.surfaceCard,
                            side: const BorderSide(color: AppTheme.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/logos/google_light.png',
                                      package: 'sign_in_button',
                                      height: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _showAdminAccessDialog,
                          icon: const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 16,
                          ),
                          label: const Text('Admin access'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.dontHaveAccount,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.signup),
                              child: Text(
                                AppStrings.contactUs,
                                style: const TextStyle(
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _BrandPill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AdminCredentials {
  final String email;
  final String password;

  const _AdminCredentials({
    required this.email,
    required this.password,
  });
}

class _AdminAccessDialog extends StatefulWidget {
  const _AdminAccessDialog();

  @override
  State<_AdminAccessDialog> createState() => _AdminAccessDialogState();
}

class _AdminAccessDialogState extends State<_AdminAccessDialog> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    Navigator.of(context).pop(
      _AdminCredentials(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      title: const Text(
        'Admin Access',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Admin Email',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.errorRed,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

