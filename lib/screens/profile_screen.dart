import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/doacao.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../widgets/donation_card.dart';
import '../widgets/change_password_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  Usuario? _usuario;
  List<Doacao> _doacoes = [];

  final _nomeController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      _usuario = await UsuarioService.instance.getMe();

      try {
        _doacoes = await UsuarioService.instance.getMyDonations();
      } catch (e) {
        debugPrint('Sem doações ou erro ao buscar: $e');
        _doacoes = [];
      }

      _nomeController.text = _usuario!.nome;
      _whatsappController.text = _usuario!.whatsapp ?? '';
      _ruaController.text = _usuario!.endereco?.rua ?? '';
      _numeroController.text = _usuario!.endereco?.numero ?? '';
      _bairroController.text = _usuario!.endereco?.bairro ?? '';
      _cidadeController.text = _usuario!.endereco?.cidade ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarPerfil() async {
    setState(() => _isSaving = true);
    try {
      final dados = {
        'nome': _nomeController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'endereco': {
          'rua': _ruaController.text.trim(),
          'numero': _numeroController.text.trim(),
          'bairro': _bairroController.text.trim(),
          'cidade': _cidadeController.text.trim(),
        }
      };

      await UsuarioService.instance.updateMe(dados);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _abrirModalSenha() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ChangePasswordModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('DoaUTF', 
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pushNamed(context, '/home'), child: const Text('Home', style: TextStyle(color: AppColors.onSurface))),
          TextButton(onPressed: () {}, child: const Text('Mapa', style: TextStyle(color: AppColors.onSurface))),
          TextButton(onPressed: () {}, child: const Text('Doar', style: TextStyle(color: AppColors.onSurface))),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/dashboard'), 
            child: const Text('Dashboard', style: TextStyle(color: AppColors.onSurface))
          ),
          TextButton(
            onPressed: () {}, 
            child: const Text('Perfil', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
          ),
          const SizedBox(width: 20),
          const Icon(Icons.notifications_none, color: AppColors.onSurface),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 15, 
            backgroundColor: AppColors.primary,
            child: Text(
              _usuario != null ? _usuario!.nome[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _usuario == null
            ? const Center(child: Text('Erro ao carregar perfil.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configurações de Perfil', 
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                    const Text('Mantenha seus dados atualizados para facilitar a comunicação nas doações.',
                      style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 40),

                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              _usuario!.nome.isNotEmpty ? _usuario!.nome[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 40, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(_usuario!.nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(_usuario!.email, style: const TextStyle(fontSize: 16, color: AppColors.outline)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildFormSection('Dados Pessoais', [
                      TextFormField(
                        initialValue: _usuario!.email,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'E-mail (Institucional)', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _whatsappController,
                        decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    _buildFormSection('Endereço', [
                      Row(
                        children: [
                          Expanded(flex: 3, child: TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua', border: OutlineInputBorder()))),
                          const SizedBox(width: 16),
                          Expanded(flex: 1, child: TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()))),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _cidadeController, decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()))),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSaving ? null : _salvarPerfil,
                            child: _isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _abrirModalSenha,
                            child: const Text('Alterar Minha Senha', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(children: fields),
        ),
      ],
    );
  }
}