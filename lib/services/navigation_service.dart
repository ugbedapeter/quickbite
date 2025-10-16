// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quickbite/pages/auth/after_onboard.dart';
import 'package:quickbite/pages/auth/forgot_password_page.dart';
import 'package:quickbite/pages/auth/login_page.dart';
import 'package:quickbite/pages/auth/onboarding_page.dart';
import 'package:quickbite/pages/auth/signup_page.dart';
import 'package:quickbite/pages/home/home_page.dart';
import 'package:quickbite/pages/splash/splash_screen.dart';
import 'package:quickbite/services/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationService {
  static final GoRouter route = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final currentLocation = state.matchedLocation;
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading = authProvider.isLoading;

      // 1. Handle onboarding first (highest priority)
      if (!seenOnboarding && currentLocation != '/onboarding') {
        return '/onboarding';
      }

      // 2. If we've seen onboarding, handle loading state
      if (isLoading && currentLocation != '/splash') {
        return '/splash';
      }

      // 3. Once loading is complete, handle authentication
      if (!isLoading) {
        final protectedRoutes = [
          '/profile',
          '/add-product',
          '/chats',
          '/favorites',
        ]; // Add other protected routes here
        final authRoutes = ['/login', '/signup'];

        // Redirect unauthenticated users from protected routes
        if (!isAuthenticated && protectedRoutes.contains(currentLocation)) {
          return '/login';
        }

        // Redirect authenticated users away from auth pages
        if (isAuthenticated &&
            (authRoutes.contains(currentLocation) ||
                currentLocation == '/splash')) {
          return '/';
        }

        // If not authenticated and not on an auth route, redirect to login
        if (!isAuthenticated &&
            !authRoutes.contains(currentLocation) &&
            currentLocation != '/onboarding') {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      //Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/afteronboarding',
        builder: (context, state) => const AfterOnboard(),
      ),
      //Main Layout
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _buildPageWithTransition(child: const HomePage(), state: state),
          ),
        ],
      ),
    ],
  );
}

Page<void> _buildPageWithTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Smooth fade and slide animation
      const begin = Offset(0.1, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      var fadeAnimation = Tween(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: curve));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: animation.drive(tween), child: child),
      );
    },
  );
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required Widget child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
