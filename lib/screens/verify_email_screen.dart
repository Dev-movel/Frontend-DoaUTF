import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import '../auth/services/auth_service.dart';
import '../widgets/auth_modal_container.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

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

  String get _otpCode => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == 6;

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownRemaining = _cooldownSeconds);

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_cooldownRemaining <= 1) {
          timer.cancel();
          if (mounted) {
            setState(() => _cooldownRemaining = 0);
          }
        } else {
          if (mounted) {
            setState(() => _cooldownRemaining--);
          }
        }
      },
    );
  }

  Future<void> _handleVerify() async {
    if (!_isOtpComplete) {
      _showMessage('Digite os 6 dígitos.', true);
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
      _showMessage(_friendlyVerifyError(e), true);
      _clearOtp();
    } catch (_) {
      _showMessage('Erro inesperado.', true);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_cooldownRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await AuthService.instance.resendVerificationCode(
        email: widget.email,
      );

      if (!mounted) return;

      _showMessage('Código reenviado.', false);
      _startCooldown();
    } on DioException catch (e) {
      _showMessage(_friendlyResendError(e), true);
    } catch (_) {
      _showMessage('Erro ao reenviar código.', true);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes.first.requestFocus();
  }

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  String _friendlyVerifyError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return 'Código inválido.';
      case 422:
        return 'Código expirado.';
      case 404:
        return 'Usuário não encontrado.';
      default:
        return 'Erro ao verificar.';
    }
  }

  String _friendlyResendError(DioException e) {
    if (e.response?.statusCode == 429) {
      return 'Aguarde antes de reenviar.';
    }
    return 'Erro ao reenviar.';
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
            child: Icon(
              Icons.eco,
              color: primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Verificar e-mail',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Digite o código enviado para ${widget.email}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (index) => _buildOtpBox(index, inputBg, primaryGreen),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  (_isVerifying || !_isOtpComplete) ? null : _handleVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: primaryGreen.withOpacity(0.4),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: _buildResendButton(),
          ),

          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: RichText(
                text: TextSpan(
                  text: 'Conta errada? ',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: 'Voltar ao login',
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

  Widget _buildOtpBox(
    int index,
    Color inputBg,
    Color primaryGreen,
  ) {
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
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryGreen,
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
      ),
    );
  }

  Widget _buildResendButton() {
    const Color primaryGreen = Color(0xFF2D7A1F);

    if (_isResending) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: primaryGreen,
        ),
      );
    }

    if (_cooldownRemaining > 0) {
      return Text(
        'Reenviar em ${_cooldownRemaining}s',
        style: const TextStyle(
          color: Colors.black38,
          fontSize: 14,
        ),
      );
    }

    return GestureDetector(
      onTap: _handleResend,
      child: const Text(
        'Reenviar código',
        style: TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}