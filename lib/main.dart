import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:quickbite/services/auth_provider.dart';
import 'package:quickbite/services/connectivity_provider.dart';
import 'package:quickbite/services/navigation_service.dart';
import 'package:quickbite/services/supabase_config.dart';

import 'package:quickbite/theme/theme_provider.dart';
import 'package:quickbite/widgets/offline_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const QuickApp(),
    ),
  );
}

class QuickApp extends StatefulWidget {
  const QuickApp({super.key});

  @override
  State<QuickApp> createState() => _QuickAppState();
}

class _QuickAppState extends State<QuickApp> {
  bool _initialized = false;
  late final GoRouter _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Initialize router synchronously. It's safe to use context.read here.
      _router = NavigationService.createRouter(context.read<AuthProvider>());

      // Use post-frame callback for async operations to avoid build conflicts.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        try {
          // Initialize auth
          await authProvider.loadCurrentUser();
        } finally {}
      });
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final theme = themeProvider.themeData;

        return Consumer<ConnectivityProvider>(
          builder: (context, connectivity, __) {
            return MaterialApp.router(
              title: 'QuickBite',
              theme: theme,
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final content = child ?? const SizedBox.shrink();
                return Column(
                  children: [
                    OfflineBanner(isOnline: connectivity.isOnline),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (widget, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: widget,
                            ),
                          );
                        },
                        child: content,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
