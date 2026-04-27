import 'package:flutter/material.dart';
import 'auth/services/api_client.dart';
import 'auth/services/token_storage.dart';
import 'theme/app_colors.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/verify_email_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  ApiClient.init(
    navigatorKey: navigatorKey,
    baseUrl: 'http://localhost:3000',
  );
 
  final hasSession = await TokenStorage.instance.hasTokens();
 
  runApp(MyApp(initialRoute: hasSession ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoaUTF',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: initialRoute,
      routes: {
        '/login':           (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home':            (_) => const HomeScreen(),
        '/register':        (_) => const SignUpScreen(),
      },
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/verify-email') {
          final email = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(email: email),
          );
        }
        if (settings.name?.startsWith('/reset-password') ?? false) {
          final uri = Uri.parse(settings.name ?? '');
          final token = uri.queryParameters['token'];
          
          if (token != null && token.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(token: token),
              settings: settings,
            );
          }
        }
        
        return null;
      },
    );
  }
}
 
// Próxima Sprint: substituir pela HomeScreen real
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenStorage.instance.clearTokens();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: const Center(child: Text('Bem-vindo!')),
    );
  }
}