import 'package:flutter/material.dart';
import '../auth/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';

class ChangePasswordModal extends StatefulWidget {
  const ChangePasswordModal({Key? key}) : super(key: key);

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureAtual = true;
  bool _obscureNova = true;
  bool _obscureConfirmar = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.changePassword(
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso!'), 
          backgroundColor: AppColors.profileGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')), 
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Alterar Senha',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _senhaAtualController,
                obscureText: _obscureAtual,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureAtual ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureAtual = !_obscureAtual),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Informe sua senha atual' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _novaSenhaController,
                obscureText: _obscureNova,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  helperText: 'Mínimo 8 caracteres, com 3 regras (Maiúscula, Minúscula, Número, Símbolo)',
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNova ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNova = !_obscureNova),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'A nova senha é obrigatória';
                  final erroSenha = Validators.validatePassword(value);
                  if (erroSenha != null) return erroSenha;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmarSenhaController,
                obscureText: _obscureConfirmar,
                decoration: InputDecoration(
                  labelText: 'Confirmar nova senha',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmar ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirme a nova senha';
                  if (value != _novaSenhaController.text) return 'As senhas não coincidem';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.profileGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Salvar Nova Senha', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}