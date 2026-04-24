import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../auth/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;

  static const int _cooldownSeconds = 60;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  String get _otpCode =>
      _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownRemaining = _cooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownRemaining = 0);
      } else {
        if (mounted) setState(() => _cooldownRemaining--);
      }
    });
  }

  Future<void> _handleVerify() async {
    if (!_isOtpComplete) {
      _showSnackbar('Digite os 6 dígitos do código.', isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await AuthService.instance.verifyEmail(
        email: widget.email,
        codigo: _otpCode,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on DioException catch (e) {
      _showSnackbar(_friendlyVerifyError(e), isError: true);
      _clearOtp();
    } catch (_) {
      _showSnackbar('Erro inesperado. Tente novamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_cooldownRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await AuthService.instance.resendVerificationCode(email: widget.email);
      if (!mounted) return;
      _showSnackbar('Código reenviado para ${widget.email}.', isError: false);
      _startCooldown();
    } on DioException catch (e) {
      _showSnackbar(_friendlyResendError(e), isError: true);
    } catch (_) {
      _showSnackbar('Não foi possível reenviar. Tente novamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _clearOtp() {
    for (final c in _otpControllers) c.clear();
    _otpFocusNodes.first.requestFocus();
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2D7A1F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _friendlyVerifyError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return 'Código inválido. Verifique e tente novamente.';
      case 422:
        return 'Código expirado. Solicite um novo abaixo.';
      case 404:
        return 'E-mail não encontrado.';
      default:
        return 'Erro ao verificar. Tente novamente.';
    }
  }

  String _friendlyResendError(DioException e) {
    switch (e.response?.statusCode) {
      case 429:
        return 'Muitas tentativas. Aguarde antes de reenviar.';
      default:
        return 'Não foi possível reenviar. Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(36.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1C19).withValues(alpha: 0.08),
                      blurRadius: 48,
                      spreadRadius: -4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
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
                        color: Color(0xFF2D7A1F),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Verifique seu e-mail', style: AppTextStyles.headline),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.subtitle,
                        text: 'Enviamos um código de 6 dígitos para ',
                        children: [
                          TextSpan(
                            text: widget.email,
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D7A1F),
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _buildOtpBox(i)),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isVerifying || !_isOtpComplete)
                            ? null
                            : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D7A1F),
                          disabledBackgroundColor:
                              const Color(0xFF2D7A1F).withValues(alpha: 0.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Verificar conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: _buildResendButton(),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.body,
                            text: 'Conta errada? ',
                            children: [
                              TextSpan(
                                text: 'Voltar ao login',
                                style: AppTextStyles.link,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,      
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, 
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2D7A1F),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          setState(() {});
        },
        onEditingComplete: () {
          if (index == 5 && _isOtpComplete) _handleVerify();
        },
      ),
    );
  }

  Widget _buildResendButton() {
    if (_isResending) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF2D7A1F),
        ),
      );
    }

    if (_cooldownRemaining > 0) {
      return Text(
        'Reenviar código em ${_cooldownRemaining}s',
        style: AppTextStyles.body.copyWith(color: Colors.black38),
      );
    }

    return GestureDetector(
      onTap: _handleResend,
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.body,
          text: 'Não recebeu? ',
          children: [
            TextSpan(text: 'Reenviar código', style: AppTextStyles.link),
          ],
        ),
      ),
    );
  }
}