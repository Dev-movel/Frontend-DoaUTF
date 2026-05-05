import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/auth_modal_container.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _successMessage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'ResetPasswordScreen token: ${widget.token.substring(0, 20)}...',
    );
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = false;
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:3000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'token': widget.token,
          'novaSenha': _senhaController.text,
        },
      );

      debugPrint('Reset OK: ${response.statusCode}');

      if (!mounted) return;

      setState(() => _successMessage = true);

      _showSnackbar(
        'Senha redefinida com sucesso!',
        isError: false,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e);
        });

        _showSnackbar(_friendlyError(e), isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro inesperado. Tente novamente.';
        });

        _showSnackbar('Erro inesperado. Tente novamente.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(DioException e) {
    if (e.response?.statusCode == 400) {
      return e.response?.data?['erro'] ?? 'Token inválido ou expirado.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Conexão perdida. Verifique sua internet.';
    }

    return 'Erro ao redefinir senha.';
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
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
              Icons.lock_reset_rounded,
              color: primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _successMessage ? 'Senha redefinida!' : 'Redefinir senha',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _successMessage
                ? 'Sua senha foi atualizada com sucesso.'
                : 'Digite sua nova senha para acessar sua conta.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 28),

          if (_successMessage)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ir para login',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Nova senha',
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Mínimo 6 caracteres.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmacaoController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Confirmar senha',
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != _senhaController.text) {
                        return 'Senhas não coincidem.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

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
                      onPressed:
                          _isLoading ? null : _handleResetPassword,
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
                              'Redefinir senha',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}