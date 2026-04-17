import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../auth/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Enviar e-mail de recuperação

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackbar('Digite seu e-mail.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('Enviando recuperação para: $email');
      await AuthService.instance.forgotPassword(email: email);

      if (!mounted) return;
      debugPrint('E-mail de recuperação enviado com sucesso!');
      setState(() => _emailSent = true);
      _showSnackbar('E-mail de recuperação enviado!', isError: false);
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      if (mounted) {
        _showSnackbar(_friendlyError(e), isError: true);
      }
    } catch (e) {
      debugPrint('Erro geral: $e');
      if (mounted) {
        _showSnackbar('Erro inesperado. Tente novamente.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helpers

  String _friendlyError(DioException e) {
    switch (e.response?.statusCode) {
      case 404:
        return 'E-mail não encontrado.';
      case 429:
        return 'Muitas tentativas. Aguarde alguns minutos.';
      default:
        return 'Não foi possível enviar. Tente novamente.';
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF2D7A1F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // UI

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2D7A1F);
    const Color inputBg      = Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: const Color(0xFFEDEADF),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F5EC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco,
                            color: primaryGreen, size: 22),
                      ),
                      const SizedBox(height: 20),

                      if (_emailSent) ...[
                        // Estado: e-mail enviado
                        const Text(
                          'Verifique seu e-mail',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enviamos as instruções para ${_emailController.text.trim()}.',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black45),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(
                                    context, '/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Voltar ao login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Estado: formulário
                        const Text(
                          'Recuperar senha',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Informe seu e-mail e enviaremos as instruções.',
                          style: TextStyle(
                              fontSize: 14, color: Colors.black45),
                        ),
                        const SizedBox(height: 28),

                        // E-mail
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleForgotPassword(),
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'E-mail',
                            hintStyle:
                                const TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botão enviar
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _handleForgotPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              disabledBackgroundColor:
                                  primaryGreen.withOpacity(0.6),
                              elevation: 0,
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
                                    'Enviar instruções',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Voltar ao login
                        Center(
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Lembrou a senha? ',
                                style: TextStyle(
                                    color: Colors.black45, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Fazer login',
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
                    ],
                  ),

                  // Botão X
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}