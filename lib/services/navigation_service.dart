// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import 'package:quickbite/pages/auth/after_onboard.dart';
import 'package:quickbite/pages/auth/forgot_password_page.dart';
import 'package:quickbite/pages/auth/login_page.dart';
import 'package:quickbite/pages/auth/onboarding_page.dart';
import 'package:quickbite/pages/auth/signup_page.dart';
import 'package:quickbite/pages/cart/cart_page.dart';
import 'package:quickbite/pages/chat/chat_list.dart';
import 'package:quickbite/pages/home/home_page.dart';
import 'package:quickbite/pages/home/search_page.dart';
import 'package:quickbite/pages/profile/profile_page.dart';

import 'package:quickbite/pages/splash/splash_screen.dart';
import 'package:quickbite/pages/wishlist/wishlist_page.dart';
import 'package:quickbite/services/auth_provider.dart';
import 'package:quickbite/theme/app_colors.dart';

class NavigationService {
  static GoRouter createRouter(AuthProvider authProvider, bool seenOnboarding) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: seenOnboarding ? '/splash' : '/onboarding',
      redirect: (context, state) async {
        final currentLocation = state.matchedLocation;
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;

        // If the app is still loading, keep showing the splash screen.
        if (isLoading && currentLocation != '/splash') {
          return '/splash';
        }
        // Once loading is complete, handle authentication logic.
        if (!isLoading) {
          final protectedRoutes = [
            '/',
            '/profile',
            '/cart',
            '/chat',
            '/wishlist',
            '/search',
          ]; // Add other protected routes here
          final authRoutes = ['/login', '/signup', '/forgot-password'];

          // Redirect unauthenticated users from protected routes
          if (!isAuthenticated && protectedRoutes.contains(currentLocation)) {
            return '/login'; // Stay on login if already there, or redirect from protected.
          }

          // Redirect authenticated users away from auth/splash pages to the home page.
          if (isAuthenticated &&
              (authRoutes.contains(currentLocation) ||
                  currentLocation == '/splash' ||
                  currentLocation == '/onboarding')) {
            return '/';
          }

          // If loading is done, user is not authenticated, and they are on the splash screen,
          // send them to the login page.
          if (!isAuthenticated && currentLocation == '/splash') {
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
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupPage(),
        ),
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
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
        //Main Layout
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => _buildPageWithTransition(
                child: const HomePage(),
                state: state,
              ),
            ),
            GoRoute(
              path: '/wishlist',
              pageBuilder: (context, state) => _buildPageWithTransition(
                child: const WishlistPage(),
                state: state,
              ),
            ),
            GoRoute(
              path: '/cart',
              pageBuilder: (context, state) => _buildPageWithTransition(
                child: const CartPage(),
                state: state,
              ),
            ),
            GoRoute(
              path: '/chat',
              pageBuilder: (context, state) => _buildPageWithTransition(
                child: const ChatList(),
                state: state,
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => _buildPageWithTransition(
                child: const ProfilePage(),
                state: state,
              ),
            ),
          ],
        ),
      ],
    );
  }
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
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _unreadMessages = 0;
  late AnimationController _animationController;
  late AnimationController _badgeController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  void showGuestPrompt(BuildContext context) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign Up Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'You need to sign up or log in to access this feature.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    if (mounted) {
                      context.go('/signup');
                    }
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(int index) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    // Check for protected pages
    if (user == null && [1, 2, 3, 4].contains(index)) {
      showGuestPrompt(context);
      return;
    }

    // Animate the tap
    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.reverse();
      }
    });

    // Reset unread messages when navigating to chats
    if (index == 3) {
      setState(() {
        _unreadMessages = 0;
      });
      _badgeController.reverse();
    }

    setState(() {
      _currentIndex = index;
    });

    // Navigate with a slight delay for smooth animation feel
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/wishlist');
          break;
        case 2:
          context.go('/cart');
          break;
        case 3:
          context.go('/chat');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedContainer(
        height: 70,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(top: 2, right: 10, left: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final isActive = _currentIndex == index;
            return _buildNavItem(index, isActive);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isActive) {
    IconData iconData;
    String label;

    switch (index) {
      case 0:
        iconData = Icons.home_filled;
        label = 'Home';
        break;
      case 1:
        iconData = Icons.favorite;
        label = 'Favorites';
        break;
      case 2:
        iconData = Icons.shopping_bag;
        label = 'Cart';
        break;
      case 3:
        iconData = Icons.chat_rounded;
        label = 'Chats';
        break;
      case 4:
        iconData = Icons.person;
        label = 'Profile';
        break;
      default:
        iconData = Icons.circle;
        label = '';
    }

    return GestureDetector(
      onTap: () => _onTap(index),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (index == 3)
                Badge(
                  label: Text('$_unreadMessages'),
                  isLabelVisible: _unreadMessages > 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      iconData,
                      key: ValueKey('$index-$isActive'),
                      color: isActive
                          ? AppColors.primaryBlue
                          : Colors.grey[600],
                      size: isActive ? 22 : 20,
                    ),
                  ),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    iconData,
                    key: ValueKey('$index-$isActive'),
                    color: isActive ? AppColors.primaryBlue : Colors.grey[600],
                    size: isActive ? 22 : 22,
                  ),
                ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primaryBlue
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
