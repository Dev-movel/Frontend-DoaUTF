import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/editorial_input.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/gradient_button.dart';
import '../auth/services/auth_service.dart';
import 'verify_email_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  final _dataController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  String? _toIsoDate(String ddmmyyyy) {
    if (ddmmyyyy.length != 10) return null;
    final parts = ddmmyyyy.split('/');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final isoDate = _toIsoDate(_dataController.text);

      if (isoDate == null) {
        setState(() {
          _errorMessage = 'Data inválida.';
          _loading = false;
        });
        return;
      }

      await AuthService.instance.register(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        dataNascimento: isoDate,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(context).size.height * 0.95,
            ),
            child: _buildModal(context),
          ),
        ),
      ),
    );
  }

  Widget _buildModal(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          isWide
              ? IntrinsicHeight(
                  child: Row(
                    children: [
                      _buildSidePanel(),
                      Expanded(child: _buildForm()),
                    ],
                  ),
                )
              : _buildForm(),

          Positioned(
            top: 12,
            right: 12,
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
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return SizedBox(
      width: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF0D631B),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _LeafPatternPainter(),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DoaUTF',
                  style: AppTextStyles.sideTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Semeando consciência,\ncolhendo um futuro sustentável.',
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crie sua conta',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 6),
              Text(
                'Comece sua jornada no DoaUTF.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 28),

              const _FieldLabel('NOME COMPLETO'),
              const SizedBox(height: 8),
              EditorialInput(
                controller: _nomeController,
                hint: 'Maria Silva',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe seu nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const _FieldLabel('DATA DE NASCIMENTO'),
              const SizedBox(height: 8),
              DatePickerField(
                controller: _dataController,
                validator: (value) {
                  if (value == null || value.length != 10) {
                    return 'Informe uma data válida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const _FieldLabel('E-MAIL INSTITUCIONAL'),
              const SizedBox(height: 8),
              EditorialInput(
                controller: _emailController,
                hint: 'usuario@alunos.utfpr.edu.br',
                icon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe seu e-mail.';
                  }
                  if (!value.contains('@')) {
                    return 'E-mail inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('SENHA'),
                        const SizedBox(height: 8),
                        EditorialInput(
                          controller: _senhaController,
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Mínimo 6 caracteres.';
                            }
                            return null;
                          },
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('CONFIRMAR'),
                        const SizedBox(height: 8),
                        EditorialInput(
                          controller: _confirmacaoController,
                          hint: '••••••••',
                          icon: Icons.verified_user_outlined,
                          obscure: _obscureConfirm,
                          validator: (value) {
                            if (value != _senhaController.text) {
                              return 'Senhas não coincidem.';
                            }
                            return null;
                          },
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
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),

              GradientButton(
                label: _loading ? 'Aguarde...' : 'Criar Conta',
                onPressed: _loading ? () {} : _submit,
              ),

              const SizedBox(height: 18),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Já possui conta? ',
                      style: AppTextStyles.body,
                      children: [
                        TextSpan(
                          text: 'Entrar',
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label,
    );
  }
}

class _LeafPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.5,
        size.width * 0.4,
        size.height,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}