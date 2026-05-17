import 'package:flutter/material.dart';
import 'auth/services/api_client.dart';
import 'auth/services/token_storage.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_donation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_dashboard.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiClient.init(
    navigatorKey: navigatorKey,
    baseUrl: 'http://localhost:3000',
  );

  final hasSession = await TokenStorage.instance.hasTokens();

runApp(const MyApp(initialRoute: '/home'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    Key? key,
    required this.initialRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoaUTF',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: initialRoute,

      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/register': (_) => const SignUpScreen(),
        '/doar': (_) => const CreateDonationScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/admin-dashboard': (_) => const AdminDashboardScreen(),
        '/feed': (_) => const FeedScreen(),
      },

      onGenerateRoute: (RouteSettings settings) {
        // RESET PASSWORD (abre modal)
        if (settings.name?.startsWith('/reset-password') ?? false) {
          final uri = Uri.parse(settings.name ?? '');
          final token = uri.queryParameters['token'] ?? '';

          return PageRouteBuilder(
            settings: settings,
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) =>
                ResetPasswordScreen(token: token),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        }

        // FORGOT PASSWORD (abre modal)
        if (settings.name == '/forgot-password') {
          return PageRouteBuilder(
            settings: settings,
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) =>
                const ForgotPasswordScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        }

        return null;
      },
    );
  }
}
