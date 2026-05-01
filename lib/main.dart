import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/features/auth/presentation/screens/login_screen.dart';
import 'package:the_holics/features/auth/presentation/screens/signup_screen.dart';
import 'package:the_holics/features/auth/presentation/screens/password_reset_screen.dart';
import 'package:the_holics/features/home/presentation/screens/home_screen.dart';
import 'package:the_holics/features/body_holics/presentation/screens/body_holics_screen.dart';
import 'package:the_holics/features/body_holics/presentation/screens/body_holics_workouts_screen.dart';
import 'package:the_holics/features/body_holics/presentation/screens/body_holics_nutrition_screen.dart';
import 'package:the_holics/features/skin_holics/presentation/screens/skin_holics_gallery_screen.dart';
import 'package:the_holics/features/skin_holics/presentation/screens/skin_holics_screen.dart';
import 'package:the_holics/features/profile/presentation/screens/profile_screen.dart';
import 'package:the_holics/features/admin/presentation/screens/admin_dashboard.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  try {
    await dotenv.load(fileName: '.env');

    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDBzbehZg4zV-EXBcm6KFbeA9lYKdmkuH0',
          appId: '1:590639006018:web:6fb1147c04e0874b0988db',
          messagingSenderId: '590639006018',
          projectId: 'thee-holics',
          storageBucket: 'thee-holics.firebasestorage.app',
          authDomain: 'thee-holics.firebaseapp.com',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if ((supabaseUrl ?? '').isNotEmpty && (supabaseAnonKey ?? '').isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl!,
        anonKey: supabaseAnonKey!,
      );
    }
  } catch (e, st) {
    initError = e.toString();
    debugPrint('App initialization failed: $e');
    debugPrint(st.toString());
  }

  runApp(
    ProviderScope(
      child: MyApp(initError: initError),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final String? initError;

  const MyApp({super.key, this.initError});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _goRouter;

  @override
  void initState() {
    super.initState();

    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final sessionService = SessionService();

    _goRouter = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
      redirect: (context, state) async {
        final user = authService.currentUser;
        final location = state.matchedLocation;
        final selectedPanel = await sessionService.getSelectedPanel();
        final googlePhonePending = await sessionService.isGooglePhonePending();
        final isPublicRoute =
            location == AppRoutes.splash ||
            location == AppRoutes.login ||
            location == AppRoutes.signup ||
            location == AppRoutes.passwordReset;

        if (googlePhonePending) {
          if (location == AppRoutes.login) {
            return null;
          }
          return AppRoutes.login;
        }

        if (user == null) {
          if (location == AppRoutes.splash) {
            return AppRoutes.login;
          }
          if (!isPublicRoute) {
            return AppRoutes.login;
          }
          return null;
        }

        String role = 'member';
        try {
          final appUser = await firestoreService.getUser(user.uid);
          role = appUser?.role.toLowerCase() ?? 'member';
        } catch (_) {
          role = 'member';
        }
        final isAdmin = role == 'admin';
        final effectivePanel = selectedPanel ?? (isAdmin ? SessionService.panelAdmin : SessionService.panelMember);

        if (isPublicRoute) {
          if (effectivePanel == SessionService.panelAdmin && isAdmin) {
            return AppRoutes.admin;
          }
          return AppRoutes.home;
        }

        if (location.startsWith(AppRoutes.admin) &&
            (effectivePanel != SessionService.panelAdmin || !isAdmin)) {
          return AppRoutes.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: AppRoutes.passwordReset,
          builder: (context, state) => const PasswordResetScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.bodyHolics,
          builder: (context, state) => const BodyHolicsScreen(),
        ),
        GoRoute(
          path: AppRoutes.bodyHolicsWorkouts,
          builder: (context, state) => const BodyHolicsWorkoutsScreen(),
        ),
        GoRoute(
          path: AppRoutes.bodyHolicsNutrition,
          builder: (context, state) => const BodyHolicsNutritionScreen(),
        ),
        GoRoute(
          path: AppRoutes.skinHolics,
          builder: (context, state) => const SkinHolicsScreen(),
        ),
        GoRoute(
          path: AppRoutes.skinHolicsGallery,
          builder: (context, state) => const SkinHolicsGalleryScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.admin,
          builder: (context, state) => const AdminDashboard(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initError != null) {
      return MaterialApp(
        title: 'Holics',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: _StartupErrorScreen(error: widget.initError!),
      );
    }

    return MaterialApp.router(
      title: 'Holics',
      theme: AppTheme.darkTheme,
      routerConfig: _goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final String error;

  const _StartupErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 44,
              ),
              const SizedBox(height: 12),
              const Text(
                'Startup Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center,
              color: AppTheme.bodyHolicsOrange,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'HOLICS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Body • Skin • Wellness',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.bodyHolicsOrange.withValues(alpha: 0.8),
              ),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
