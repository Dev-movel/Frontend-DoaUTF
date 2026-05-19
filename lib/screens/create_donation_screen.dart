import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/doacao_form.dart';
import '../services/doacao_service.dart';
import '../theme/app_colors.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/create_donation/details_step.dart';
import '../widgets/create_donation/logistics_step.dart';
import '../widgets/create_donation/photos_step.dart';
import '../widgets/create_donation/shared/gradient_btn.dart';
import '../widgets/create_donation/step_indicator.dart';

const _kBg      = Color(0xFFFAFAF5);
const _kDivider = Color(0x4DBFCABA);
const _kInputBg = Color(0xFFE3E3DE);
const _kGreenLime = Color(0xFFA3F69C);

const _kMaxImageBytes = 5 * 1024 * 1024;

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  int  _step      = 0;
  bool _isLoading = false;

  List<CategoriaItem> _categorias  = [];
  bool                _loadingCats = true;
  String?             _catsError;

  final _formKey   = GlobalKey<FormState>();
  final _form      = DoacaoForm();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  final _picker = ImagePicker();

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
      if (mounted) {
        setState(() { _categorias = cats; _loadingCats = false; });
      }
    } catch (e) {
      if (mounted) setState(() {
        _catsError   = e.toString().replaceFirst('Exception: ', '');
        _loadingCats = false;
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

  bool _validateDetails() {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return false;
    if (_form.categoriaId == null) {
      _showError('Selecione uma categoria.');
      return false;
    }
    return true;
  }

  bool _validatePhotos() {
    if (_form.fotos.isEmpty) {
      _showError('Adicione pelo menos uma foto.');
      return false;
    }
    return true;
  }

  bool _validateLogistics() {
    if (_form.localRetirada.isEmpty) {
      _showError('Selecione um local de retirada ou ponto de encontro.');
      return false;
    }
    return true;
  }

  void _nextStep() {
    final valid = switch (_step) {
      0 => _validateDetails(),
      1 => _validatePhotos(),
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

  // ── API ────────────────────────────────────────────────────────────────────

  void _syncControllers() {
    _form.titulo    = _titleCtrl.text.trim();
    _form.descricao = _descCtrl.text.trim();
  }

  Future<void> _publish() async {
    _syncControllers();
    if (!_validateLogistics()) return;
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
        appBar: MainAppBar(
          activeRoute: '/doar',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.onSurface),
            onPressed: () {
              if (_step > 0) {
                setState(() => _step--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publicar Doação',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cada item doado é um passo em direção a um futuro circular.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: DonationStepIndicator(currentStep: _step),
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
                    child: _buildStepCard(child: _buildStep()),
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

  Widget _buildStep() => switch (_step) {
    0 => DetailsStep(
        categorias: _categorias,
        loadingCats: _loadingCats,
        catsError: _catsError,
        formKey: _formKey,
        titleCtrl: _titleCtrl,
        descCtrl: _descCtrl,
        selectedCategoriaId: _form.categoriaId,
        selectedConservation: _form.estadoConservacao,
        onRetry: () => setState(() {
          _loadingCats = true;
          _catsError = null;
          _loadCategorias();
        }),
        onCategorySelected: (id) => setState(() => _form.categoriaId = id),
        onConservationChanged: (s) =>
            setState(() => _form.estadoConservacao = s),
      ),
    1 => PhotosStep(
        fotos: _form.fotos,
        onAddPhoto: _showImageSourceSheet,
        onRemovePhoto: (i) => setState(() => _form.fotos.removeAt(i)),
      ),
    2 => LogisticsStep(
        tipoLogistica: _form.tipoLogistica,
        localRetirada: _form.localRetirada,
        onTipoChanged: (tipo) => setState(() {
          _form.tipoLogistica = tipo;
          _form.localRetirada = '';
        }),
        onLocalSelected: (local) =>
            setState(() => _form.localRetirada = local),
      ),
    _ => const SizedBox(),
  };

  Widget _buildStepCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

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
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Voltar',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: GradientBtn(
                      label: _step == 0
                          ? 'Próximo: Fotos'
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GradientBtn(
                      label: 'Publicar Doação',
                      enabled: _isPublishEnabled,
                      onPressed: _publish,
                    ),
                  ),
                ]),
    );
  }
}
