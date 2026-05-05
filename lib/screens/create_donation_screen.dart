import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/doacao_form.dart';
import '../services/doacao_service.dart';
import '../theme/app_colors.dart';

const _kBg        = Color(0xFFFAFAF5);
const _kSurface   = Color(0xFFF4F4EF);
const _kInputBg   = Color(0xFFE3E3DE);
const _kDivider   = Color(0x4DBFCABA);
const _kGreenPill = Color(0x1A2E7D32);
const _kGreenLime = Color(0xFFA3F69C);
const _kSelBorder = Color(0x330D631B);
const _kDashedBd  = Color(0xFFBFCABA);

const _kMaxImageBytes = 5 * 1024 * 1024;

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  int  _step      = 0;
  bool _isLoading = false;

  // Categorias vindas da API
  List<CategoriaItem> _categorias    = [];
  bool                _loadingCats   = true;
  String?             _catsError;

  final _formKey      = GlobalKey<FormState>();
  final _form         = DoacaoForm();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  String _meetingSearch = '';

  final _picker = ImagePicker();

  static const _conservStates = ['Novo', 'Usado', 'Precisa de reparo'];

  static const _meetingPoints = [
    'Bloco A',
    'Bloco B',
    'Bloco C',
    'Bloco D',
    'Bloco E',
    'Bloco F',
    'Bloco G',
    'Biblioteca',
    'Centro de Convivência',
    'Aquário',
    'RU',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onFormChanged);
    _descCtrl.addListener(_onFormChanged);
    _loadCategorias();
  }

  @override
  void dispose() {
    _titleCtrl
      ..removeListener(_onFormChanged)
      ..dispose();
    _descCtrl
      ..removeListener(_onFormChanged)
      ..dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  Future<void> _loadCategorias() async {
    try {
      final cats = await DoacaoService.instance.buscarCategorias();
      if (mounted) setState(() { _categorias = cats; _loadingCats = false; });
    } catch (e) {
      if (mounted) setState(() {
        _catsError    = e.toString().replaceFirst('Exception: ', '');
        _loadingCats  = false;
      });
    }
  }

  // ── Guards ─────────────────────────────────────────────────────────────────

  bool get _isPublishEnabled =>
      _form.fotos.isNotEmpty &&
      _titleCtrl.text.trim().isNotEmpty &&
      _descCtrl.text.trim().isNotEmpty &&
      _form.categoriaId != null &&
      _form.localRetirada.isNotEmpty;

  // ── Validações ─────────────────────────────────────────────────────────────

  bool _validateStep0() {
    if (_form.fotos.isEmpty) {
      _showError('Adicione pelo menos uma foto.');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return false;
    if (_form.categoriaId == null) {
      _showError('Selecione uma categoria.');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_form.localRetirada.isEmpty) {
      _showError('Selecione um local de retirada ou ponto de encontro.');
      return false;
    }
    return true;
  }

  void _nextStep() {
    final valid = switch (_step) {
      0 => _validateStep0(),
      1 => _validateStep1(),
      _ => true,
    };
    if (valid) setState(() => _step++);
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.manrope(color: Colors.white)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.manrope(color: Colors.white)),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Fotos ──────────────────────────────────────────────────────────────────

  Future<void> _showImageSourceSheet() async {
    if (_form.fotos.length >= 5) {
      _showError('Limite de 5 fotos atingido.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _kInputBg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kGreenLime,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF002204), size: 20),
              ),
              title: Text('Câmera',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.onSurface)),
              subtitle: Text('Tire uma foto agora',
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: AppColors.outline)),
              onTap: () { Navigator.pop(context); _pickFromCamera(); },
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF5B5BD6), size: 20),
              ),
              title: Text('Galeria',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.onSurface)),
              subtitle: Text('Escolha múltiplas fotos',
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: AppColors.outline)),
              onTap: () { Navigator.pop(context); _pickFromGallery(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;
      if (await _checkSize(picked)) setState(() => _form.fotos.add(picked));
    } catch (_) {
      _showError('Não foi possível acessar a câmera.');
    }
  }

  Future<void> _pickFromGallery() async {
    final remaining = 5 - _form.fotos.length;
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      int added = 0;
      for (final xfile in picked) {
        if (added >= remaining) break;
        if (await _checkSize(xfile)) { _form.fotos.add(xfile); added++; }
      }
      if (added > 0) setState(() {});
    } catch (_) {
      _showError('Não foi possível acessar a galeria.');
    }
  }

  Future<bool> _checkSize(XFile xfile) async {
    final bytes = await xfile.length();
    if (bytes > _kMaxImageBytes) {
      _showError('A foto ultrapassa o limite de 5 MB e não foi adicionada.');
      return false;
    }
    return true;
  }

  void _removePhoto(int index) => setState(() => _form.fotos.removeAt(index));

  // ── API ────────────────────────────────────────────────────────────────────

  void _syncControllers() {
    _form.titulo    = _titleCtrl.text.trim();
    _form.descricao = _descCtrl.text.trim();
  }

  Future<void> _publish() async {
    if (!_validateStep2()) return;
    _syncControllers();
    setState(() => _isLoading = true);
    try {
      await DoacaoService.instance.publicar(_form);
      if (!mounted) return;
      _showSuccess('Doação publicada com sucesso!');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    _syncControllers();
    if (_form.titulo.isEmpty) {
      _showError('Informe o título antes de salvar o rascunho.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await DoacaoService.instance.salvarRascunho(_form);
      if (!mounted) return;
      _showSuccess('Rascunho salvo!');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
            onPressed: () {
              if (_step > 0) setState(() => _step--);
              else Navigator.pop(context);
            },
          ),
          title: Text(
            'Publicar Doação',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.onSurface, letterSpacing: -0.4,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _buildStepIndicator(),
            ),
            const Divider(height: 1, color: _kDivider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Step indicator ─────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const steps = ['Fotos', 'Detalhes', 'Logística'];
    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepPill(
            index: i, label: steps[i],
            isActive: i == _step, isDone: i < _step,
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: i < _step ? AppColors.primary : _kDivider,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStep() => switch (_step) {
    0 => _buildPhotosStep(),
    1 => _buildDetailsStep(),
    2 => _buildLogisticsStep(),
    _ => const SizedBox(),
  };

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kDivider)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5),
              ),
            )
          : _step < 2
              ? Row(children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Voltar',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: _GradientBtn(
                      label: _step == 0
                          ? 'Próximo: Detalhes'
                          : 'Próximo: Logística',
                      onPressed: _nextStep,
                    ),
                  ),
                ])
              : Row(children: [
                  TextButton(
                    onPressed: _isLoading ? null : _saveDraft,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14)),
                    child: Text(
                      'Salvar\nRascunho',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant, height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GradientBtn(
                      label: 'Publicar Doação',
                      enabled: _isPublishEnabled,
                      onPressed: _publish,
                    ),
                  ),
                ]),
    );
  }

  // ── Step 0 – Fotos ─────────────────────────────────────────────────────────

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Enviar Fotos',
          subtitle: 'Adicione até 5 fotos. Imagens de alta qualidade aumentam o interesse.',
        ),
        const SizedBox(height: 20),
        if (_form.fotos.isEmpty)
          _buildDropZone()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: _form.fotos.length + (_form.fotos.length < 5 ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _form.fotos.length) return _buildAddMoreBtn();
              return _PhotoThumbnail(
                xfile: _form.fotos[i],
                onRemove: () => _removePhoto(i),
              );
            },
          ),
        const SizedBox(height: 10),
        Text(
          '${_form.fotos.length}/5 fotos adicionadas',
          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: _DashedBox(
        borderColor: _kDashedBd, bgColor: Colors.white, height: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(
                  color: _kGreenLime, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera_outlined,
                  color: Color(0xFF002204), size: 24),
            ),
            const SizedBox(height: 16),
            Text('Câmera ou Galeria',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Text('PNG, JPG — máx. 5MB por foto',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreBtn() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: _DashedBox(
        borderColor: _kDashedBd.withValues(alpha: 0.5),
        bgColor: _kSurface,
        height: double.infinity,
        child: const Icon(Icons.add, size: 22, color: AppColors.outline),
      ),
    );
  }

  // ── Step 1 – Detalhes ──────────────────────────────────────────────────────

  Widget _buildDetailsStep() {
    // Enquanto carrega categorias, mostra indicador inline
    if (_loadingCats) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
    }

    // Se falhou, oferece retry
    if (_catsError != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_catsError!,
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: Colors.redAccent)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() { _loadingCats = true; _catsError = null; });
                  _loadCategorias();
                },
                child: Text('Tentar novamente',
                    style: GoogleFonts.manrope(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    final categoriaNome = _form.categoriaId == null
        ? null
        : _categorias
            .firstWhere((c) => c.id == _form.categoriaId,
                orElse: () => CategoriaItem(id: -1, nome: ''))
            .nome
            .nullIfEmpty;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Detalhes do Item'),
          const SizedBox(height: 20),
          const _FieldLabel('Título da Doação'),
          const SizedBox(height: 8),
          _AppTextFormField(
            controller: _titleCtrl,
            hint: 'ex: Cadeira de Madeira Vintage',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o título da doação'
                : null,
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Categoria'),
          const SizedBox(height: 8),
          _AppDropdown(
            value: categoriaNome,
            hint: 'Selecione uma categoria',
            items: _categorias.map((c) => c.nome).toList(),
            onChanged: (nome) {
              if (nome == null) return;
              final cat = _categorias.firstWhere((c) => c.nome == nome);
              setState(() => _form.categoriaId = cat.id);
            },
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Estado do Item'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _conservStates
                .map((s) => _ConservBtn(
                      label: s,
                      selected: _form.estadoConservacao == s,
                      onTap: () =>
                          setState(() => _form.estadoConservacao = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Descrição'),
          const SizedBox(height: 8),
          _AppTextFormField(
            controller: _descCtrl,
            hint: 'Conte a história deste item...',
            maxLines: 5,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Adicione uma descrição'
                : null,
          ),
        ],
      ),
    );
  }

  // ── Step 2 – Logística ─────────────────────────────────────────────────────

  Widget _buildLogisticsStep() {
    final filtered = _meetingPoints
        .where((p) =>
            p.toLowerCase().contains(_meetingSearch.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Logística'),
        const SizedBox(height: 20),
        _LogisticCard(
          icon: Icons.location_on_outlined,
          iconColor: AppColors.primary,
          title: 'Retirada Disponível',
          subtitle: 'Escolha o bloco/ponto onde o item pode ser retirado.',
          selected: _form.tipoLogistica == 'retirada',
          onTap: () => setState(() {
            _form.tipoLogistica = 'retirada';
            _form.localRetirada = '';
          }),
        ),
        const SizedBox(height: 12),
        _LogisticCard(
          icon: Icons.meeting_room_outlined,
          iconColor: AppColors.onSurfaceVariant,
          title: 'Ponto de Encontro',
          subtitle: 'Combine um local no campus da UTF!',
          selected: _form.tipoLogistica == 'encontro',
          onTap: () => setState(() {
            _form.tipoLogistica = 'encontro';
            _form.localRetirada = '';
          }),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('Local de Retirada / Ponto de Encontro'),
        const SizedBox(height: 8),
        _AppInput(
          hint: 'Buscar local...',
          prefixIcon: Icons.search,
          onChanged: (v) => setState(() => _meetingSearch = v),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text('Nenhum resultado',
                        style: GoogleFonts.manrope(
                            color: AppColors.outline, fontSize: 14)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _kDivider),
                  itemBuilder: (_, i) {
                    final pt  = filtered[i];
                    final sel = _form.localRetirada == pt;
                    return Material(
                      color: sel ? _kGreenPill : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        leading: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: sel
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                        title: Text(
                          pt,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: sel
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 16)
                            : null,
                        onTap: () =>
                            setState(() => _form.localRetirada = pt),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
} // ← fim de _CreateDonationScreenState

// ─── Extension helper ─────────────────────────────────────────────────────────

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

// ─── Widgets reutilizáveis ────────────────────────────────────────────────────

class _StepPill extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepPill({
    required this.index, required this.label,
    required this.isActive, required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isActive || isDone ? 1.0 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _kGreenPill : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isActive || isDone ? AppColors.primary : _kInputBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: GoogleFonts.manrope(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.onSurface, letterSpacing: -0.5)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: GoogleFonts.manrope(
                  fontSize: 13, color: AppColors.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.onSurface)),
    );
  }
}

class _AppTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  const _AppTextFormField({
    required this.controller, required this.hint,
    this.maxLines = 1, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.manrope(fontSize: 15, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.manrope(fontSize: 15, color: AppColors.outline),
        filled: true, fillColor: _kInputBg,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 20, vertical: maxLines > 1 ? 18 : 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle:
            GoogleFonts.manrope(fontSize: 11, color: Colors.redAccent),
      ),
    );
  }
}

class _AppInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  const _AppInput({
    this.controller, required this.hint,
    this.prefixIcon, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.manrope(fontSize: 15, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.manrope(fontSize: 15, color: AppColors.outline),
        filled: true, fillColor: _kInputBg,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.outline)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

class _AppDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _AppDropdown({
    required this.value, required this.hint,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: _kInputBg, borderRadius: BorderRadius.circular(12)),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(hint,
            style: GoogleFonts.manrope(
                fontSize: 15, color: AppColors.outline)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.outline, size: 22),
        dropdownColor: Colors.white,
        style: GoogleFonts.manrope(
            fontSize: 15, color: AppColors.onSurface),
        items: items
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ConservBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ConservBtn({
    required this.label, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : _kInputBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.onSurface)),
      ),
    );
  }
}

class _LogisticCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LogisticCard({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? Colors.white : _kInputBg,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: _kSelBorder, width: 2) : null,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: selected ? Colors.white : _kInputBg,
                borderRadius: BorderRadius.circular(6),
                border: selected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: AppColors.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBox extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color bgColor;
  final double height;

  const _DashedBox({
    required this.child, required this.borderColor,
    required this.bgColor, required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: borderColor, bg: bgColor),
      child: SizedBox(
        height: height, width: double.infinity,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final Color bg;
  const _DashedPainter({required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, Paint()..color = bg);
    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap  = 4.0;
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(
            m.extractPath(d, (d + dash).clamp(0.0, m.length)), dashPaint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PhotoThumbnail extends StatelessWidget {
  final XFile xfile;
  final VoidCallback onRemove;
  const _PhotoThumbnail({required this.xfile, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(xfile.path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientBtn extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _GradientBtn({
    required this.label, required this.onPressed, this.enabled = true,
  });

  @override
  State<_GradientBtn> createState() => _GradientBtnState();
}

class _GradientBtnState extends State<_GradientBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  )
                : null,
            color: enabled ? null : _kInputBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 18, offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(widget.label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: enabled ? Colors.white : AppColors.outline,
                  letterSpacing: -0.3)),
        ),
      ),
    );
  }
}