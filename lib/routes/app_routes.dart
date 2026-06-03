import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/create_donation_screen.dart';
import '../screens/tela_mapa.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/register': (_) => const SignUpScreen(),
        '/doar': (_) => const CreateDonationScreen(),
        '/mapa': (_) => const TelaDoMapa(), 
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';

    // Rota de Reset Password (via Link/URL)
    if (name.startsWith('/reset-password')) {
      final uri = Uri.parse(name);
      final token = uri.queryParameters['token'] ?? '';

      return _createModalRoute(ResetPasswordScreen(token: token), settings);
    }

    // Rota de Forgot Password (clique no login)
    if (name == '/forgot-password') {
      return _createModalRoute(const ForgotPasswordScreen(), settings);
    }

    return null;
  }

  // Função auxiliar para criar o efeito de Modal sobreposto
  static Route _createModalRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      opaque: false, // Essencial para ver a tela anterior ao fundo
      barrierDismissible: true,
      barrierColor: Colors.black54, // Cor do "dim" (escurecimento)
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}