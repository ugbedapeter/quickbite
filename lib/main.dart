import 'package:flutter/material.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const QuickApp(),
    ),
  );
}

class QuickApp extends StatefulWidget {
  const QuickApp({super.key});

  @override
  State<QuickApp> createState() => _UnimartAppState();
}

class _UnimartAppState extends State<QuickApp> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Use post-frame callback to ensure provider is available
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Initialize auth and notifications
        await Future.wait([authProvider.loadCurrentUser()]);
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
              routerConfig: NavigationService.route,
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
