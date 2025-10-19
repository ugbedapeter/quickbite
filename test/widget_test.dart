import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:quickbite/main.dart';
import 'package:quickbite/pages/splash/splash_screen.dart';
import 'package:quickbite/services/auth_provider.dart';
import 'package:quickbite/services/connectivity_provider.dart';
import 'package:quickbite/services/supabase_config.dart';
import 'package:quickbite/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  // This is a mock Supabase client. In a real-world scenario, you might use
  // a more robust mocking library like `mocktail`.
  // For this test, we just need to initialize it to prevent errors.
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Mock SharedPreferences to prevent MissingPluginException during tests.
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      // Use a mock client to prevent real network calls during tests.
      httpClient: MockHttpClient(),
    );
  });

  testWidgets('App starts and shows SplashScreen', (WidgetTester tester) async {
    // Build our app with all the necessary providers.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ],
        child: const QuickApp(),
      ),
    );

    // The app should initially show the splash screen while it's loading.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}

// A simple mock for the HTTP client to avoid network errors in tests.
class MockHttpClient extends Fake implements Client {
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // Return an empty/default response
    return StreamedResponse(Stream.value([]), 200);
  }
}
