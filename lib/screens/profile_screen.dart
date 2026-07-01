import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/doacao.dart';
import '../models/resgate.dart';
import '../services/usuario_service.dart';
import '../services/premios_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/change_password_modal.dart';
import '../widgets/donation_card.dart';
import '../widgets/main_app_bar.dart';

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
  List<Resgate> _resgates = [];
  int _saldo = 0;

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

      try {
        final resultados = await Future.wait([
          PremiosService.instance.buscarSaldo(),
          PremiosService.instance.buscarResgates(),
        ]);
        _saldo = resultados[0] as int;
        _resgates = resultados[1] as List<Resgate>;
      } catch (_) {}

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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/profile'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _usuario == null
            ? const Center(child: Text('Erro ao carregar perfil.'))
            : SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configurações de Perfil',
                      style: TextStyle(fontSize: isMobile ? 22 : 32, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                    Text('Mantenha seus dados atualizados para facilitar a comunicação nas doações.',
                      style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.onSurfaceVariant)),
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
                        style: const TextStyle(color: AppColors.outline),
                        decoration: InputDecoration(
                          labelText: 'E-mail (Institucional)',
                          helperText: 'Não pode ser alterado',
                          helperStyle: const TextStyle(color: AppColors.outline),
                          filled: true,
                          fillColor: AppColors.onSurface.withOpacity(0.06),
                          border: const OutlineInputBorder(),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.outlineVariant),
                          ),
                          labelStyle: const TextStyle(color: AppColors.outline),
                          suffixIcon: const Icon(Icons.lock_outline, color: AppColors.outline),
                        ),
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
                    ], isMobile: isMobile),

                    const SizedBox(height: 32),

                    _buildFormSection('Endereço', [
                      if (isMobile) ...[
                        TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua', border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextFormField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextFormField(controller: _cidadeController, decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder())),
                      ] else ...[
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
                      ],
                    ], isMobile: isMobile),

                    const SizedBox(height: 40),

                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
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
                          const SizedBox(height: 12),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _abrirModalSenha,
                            child: const Text('Alterar Minha Senha', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                          ),
                        ],
                      )
                    else
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
                    const SizedBox(height: 40),

                    // ── Pontos e histórico de resgates ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pontos e Resgates',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/premiacoes'),
                          icon: const Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.primary),
                          label: Text('Ver prêmios',
                              style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Saldo em destaque
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('$_saldo pontos',
                                        style: AppTextStyles.input.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text('disponíveis',
                                  style: AppTextStyles.label.copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                          if (_resgates.isEmpty) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: Text('Nenhum resgate realizado ainda.',
                                  style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceVariant)),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text('Histórico de resgates',
                                style: AppTextStyles.label.copyWith(
                                    fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            ..._resgates.map((r) => _ItemResgate(resgate: r)),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> fields, {bool isMobile = false}) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
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

// ── Item de histórico de resgate ──────────────────────────────────────────

class _ItemResgate extends StatelessWidget {
  final Resgate resgate;
  const _ItemResgate({required this.resgate});

  @override
  Widget build(BuildContext context) {
    final data = resgate.criadoEm.toLocal();
    final dataStr =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resgate.premioNome,
                    style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$dataStr · ${resgate.pontosGastos} pts · Código: ${resgate.codigo}',
                    style: AppTextStyles.label.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: resgate.isPendente
                  ? Colors.orange.withOpacity(0.12)
                  : Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              resgate.isPendente ? 'Pendente' : 'Retirado',
              style: AppTextStyles.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: resgate.isPendente ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}