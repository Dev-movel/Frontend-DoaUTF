import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/editorial_input.dart';
import '../widgets/gradient_button.dart';

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
  String? _errorMessage;

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
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:3000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      await dio.post('/auth/reset-password', data: {
        'token': widget.token,
        'novaSenha': _senhaController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha redefinida com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } on DioException catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(DioException e) {
    if (e.response?.statusCode == 400) return 'Token inválido ou expirado';
    return 'Erro ao redefinir senha. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Material transparente para que o fundo do modal apareça corretamente
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
              maxHeight: 600, // Um pouco menor que o cadastro pois tem menos campos
            ),
            child: _buildModal(context),
          ),
        ),
      ),
    );
  }

  Widget _buildModal(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1C19).withOpacity(0.10),
                blurRadius: 48,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: isWide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSidePanel(),
                      Expanded(child: _buildForm()),
                    ],
                  ),
                )
              : _buildForm(),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanel() {
    return SizedBox(
      width: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF0D631B)],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Segurança', style: AppTextStyles.sideTitle),
                const SizedBox(height: 8),
                Text(
                  'Proteja seu acesso para continuar sua jornada sustentável.',
                  style: AppTextStyles.sideBody,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Redefinir Senha', style: AppTextStyles.headline),
            const SizedBox(height: 4),
            Text(
              'Escolha uma nova senha forte para sua conta.',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 32),

            Text('NOVA SENHA', style: AppTextStyles.label),
            const SizedBox(height: 6),
            EditorialInput(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              controller: _senhaController,
              validator: (value) {
                if (value == null || value.length < 6) return 'Mínimo 6 caracteres.';
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.outline,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),

            Text('CONFIRMAR SENHA', style: AppTextStyles.label),
            const SizedBox(height: 6),
            EditorialInput(
              hint: '••••••••',
              icon: Icons.verified_user_outlined,
              obscure: _obscureConfirm,
              controller: _confirmacaoController,
              validator: (value) {
                if (value != _senhaController.text) return 'Senhas não coincidem.';
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.outline,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),

            GradientButton(
              label: _isLoading ? 'Processando...' : 'Atualizar Senha',
              onPressed: _isLoading ? () {} : _handleResetPassword,
            ),
            const SizedBox(height: 20),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body,
                    text: 'Lembrou a senha? ',
                    children: [
                      TextSpan(text: 'Entrar', style: AppTextStyles.link),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}