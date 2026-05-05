import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/editorial_input.dart';
import '../widgets/gradient_button.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localizacaoController = TextEditingController();

  String _estadoConservacao = 'Novo';
  String? _categoriaSelecionada;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _localizacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F7), // Fundo levemente acinzentado/verde
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  _buildDetailsSection(),
                  const SizedBox(height: 24),
                  _buildLogisticsSection(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Publicar Doação', style: AppTextStyles.headline.copyWith(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          'Cada item doado é um passo em direção a um futuro circular.',
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }

  // --- SEÇÃO DE FOTOS ---
  Widget _buildPhotoSection() {
    return _buildCard(
      title: 'Enviar Fotos',
      subtitle: 'Adicione até 5 fotos. Imagens de alta qualidade aumentam o interesse.',
      child: Row(
        children: [
          // Dropzone Placeholder
          Expanded(
            flex: 2,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant, width: 1),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.surface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text('Arraste e Solte ou Procure', style: AppTextStyles.label),
                  Text('PNG, JPG até 10MB', style: AppTextStyles.legal),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Miniatura Exemplo
          _buildPhotoThumbnail(),
          const SizedBox(width: 16),
          _buildPhotoThumbnail(isEmpty: true),
        ],
      ),
    );
  }

  // --- SEÇÃO DE DETALHES ---
  Widget _buildDetailsSection() {
    return _buildCard(
      title: 'Detalhes do Item',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('TÍTULO DA DOAÇÃO'),
          EditorialInput(
            hint: 'ex: Cadeira de Madeira Vintage',
            controller: _tituloController,
            icon: Icons.title,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('CATEGORIA'),
                    _buildDropdown(),
                    const SizedBox(height: 20),
                    _fieldLabel('ESTADO DE CONSERVAÇÃO'),
                    _buildSegmentedControl(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('DESCRIÇÃO'),
                    EditorialInput(
                      hint: 'Conte a história deste item...',
                      controller: _descricaoController,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SEÇÃO DE LOGÍSTICA ---
  Widget _buildLogisticsSection() {
    return _buildCard(
      title: 'Logística',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                _buildLogisticsOption(
                  icon: Icons.location_on_outlined,
                  title: 'Retirada Disponível',
                  desc: 'Nessa opção você terá que ir até o doador',
                  selected: true,
                ),
                const SizedBox(height: 12),
                _buildLogisticsOption(
                  icon: Icons.handshake_outlined,
                  title: 'Ponto de Encontro',
                  desc: 'Combine algum lugar na UTF!',
                  selected: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('LOCALIZAÇÃO APROXIMADA'),
                EditorialInput(
                  hint: 'Bloco E',
                  controller: _localizacaoController,
                  icon: Icons.search,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://placeholder.com/map'), // Trocar por Google Maps futuramente
                      fit: BoxFit.cover,
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

  // --- HELPERS DE UI ---

  Widget _buildCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headline.copyWith(fontSize: 20)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTextStyles.label),
    );
  }

  Widget _buildPhotoThumbnail({bool isEmpty = false}) {
    return Container(
      width: 100,
      height: 160,
      decoration: BoxDecoration(
        color: isEmpty ? Colors.transparent : Colors.grey[100],
        border: isEmpty ? Border.all(color: AppColors.outlineVariant, style: BorderStyle.none) : null, // Simplificado
        borderRadius: BorderRadius.circular(12),
      ),
      child: isEmpty 
        ? Icon(Icons.add, color: AppColors.outline)
        : const Center(child: Text('FOTO')),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Selecione uma categoria', style: AppTextStyles.body),
          value: _categoriaSelecionada,
          items: ['Móveis', 'Eletrônicos', 'Livros', 'Roupas'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (val) => setState(() => _categoriaSelecionada = val),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Row(
      children: ['Novo', 'Como Novo', 'Bom'].map((estado) {
        bool isSelected = _estadoConservacao == estado;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _estadoConservacao = estado),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  estado,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogisticsOption({required IconData icon, required String title, required String desc, required bool selected}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: selected ? AppColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.outline),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(color: selected ? AppColors.primary : null)),
                Text(desc, style: AppTextStyles.legal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {},
          child: Text('Salvar Rascunho', style: AppTextStyles.body.copyWith(color: Colors.black54)),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 200,
          child: GradientButton(
            label: 'Publicar Doação',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Lógica de envio
              }
            },
          ),
        ),
      ],
    );
  }
}