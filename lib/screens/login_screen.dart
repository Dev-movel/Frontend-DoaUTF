import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/services/auth_service.dart';
import '../widgets/auth_modal_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Preencha e-mail e senha.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Tentando login com: $email');

      await AuthService.instance.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } on DioException catch (e) {
      if (mounted) {
        _showError(_friendlyError(e));
      }
    } catch (_) {
      if (mounted) {
        _showError('Erro inesperado. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  String _friendlyError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'E-mail ou senha incorretos.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Conexão perdida. Verifique sua internet.';
    }

    return 'Erro ao conectar. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2D7A1F);
    const Color inputBg = Color(0xFFF0F0F0);

    return AuthModalContainer(
      maxWidth: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F5EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco,
              color: primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Entrar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Acesse sua conta para continuar.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 28),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'E-mail',
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Senha',
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(color: primaryGreen),
              ),
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Entrar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/register');
              },
              child: RichText(
                text: const TextSpan(
                  text: 'Não possui conta? ',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: 'Cadastre-se',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}