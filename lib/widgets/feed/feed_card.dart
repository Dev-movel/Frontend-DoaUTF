import 'package:flutter/material.dart';
import '../../models/feed_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../mapa/modal_mapa_local.dart';
import '../../services/denuncia_service.dart'; 

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback? onAcceptDirect;
  final VoidCallback? onOpenAgendamento;
  final VoidCallback? onReport;

  const FeedCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onAcceptDirect,
    this.onOpenAgendamento,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            _Imagem(
              fotoUrl: item.fotoUrl, 
              status: item.status,
              itemId: item.id,
              onReport: onReport,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _CategoriaChip(categoria: item.categoria),
                    const SizedBox(height: 8),
                    _TituloELocalizacao(item: item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Imagem extends StatelessWidget {
  final String? fotoUrl;
  final String status;
  final dynamic itemId;
  final VoidCallback? onReport;

  const _Imagem({
    required this.fotoUrl, 
    required this.status, 
    required this.itemId,
    this.onReport,
  });

  void _mostrarModalDenunciaInterno(BuildContext context) {
    String motivoSelecionado = 'Item inadequado ou ofensivo';
    final TextEditingController descricaoController = TextEditingController();

    final List<String> motivos = [
      'Item inadequado ou ofensivo',
      'Fraude, golpe ou anúncio falso',
      'Item proibido por lei',
      'Categoria errada ou spam',
      'Outro motivo',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Denunciar Post'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione o motivo principal:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: motivoSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: motivos.map((String motivo) {
                        return DropdownMenuItem<String>(
                          value: motivo,
                          child: Text(motivo, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (novoMotivo) {
                        setDialogState(() {
                          motivoSelecionado = novoMotivo!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detalhes adicionais (opcional)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final motivo = motivoSelecionado;
                    final descricao = descricaoController.text;

                    Navigator.pop(context);

                    if (onReport != null) {
                      onReport!();
                    } else {
                      try {
                        await DenunciaService.instance.enviarDenuncia(
                          itemId: itemId.toString(),
                          motivo: motivo,
                          descricao: descricao,
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Denúncia registrada! O administrador irá analisar.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao enviar denúncia: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Enviar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool indisponivel = status.toLowerCase() != 'disponivel';

    return Stack(
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.containerHigh,
            image: fotoUrl != null
                ? DecorationImage(
                    image: NetworkImage(fotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: fotoUrl == null
              ? const Icon(
                  Icons.image_not_supported_outlined,
                  size: 60,
                  color: AppColors.outline,
                )
              : null,
        ),
        
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            radius: 18,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.report_outlined, size: 20, color: Colors.white),
              tooltip: 'Denunciar esta publicação',
              onPressed: () => _mostrarModalDenunciaInterno(context),
            ),
          ),
        ),

        if (indisponivel)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final String categoria;
  const _CategoriaChip({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primaryContainer.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Text(
        categoria,
        style: AppTextStyles.subtitle.copyWith(
          color: AppColors.primaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TituloELocalizacao extends StatelessWidget {
  final FeedItem item;
  const _TituloELocalizacao({required this.item});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.titulo,
            style: AppTextStyles.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => ModalMapaLocal.mostrar(
                  context,
                  localizacao: item.localizacao,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 13,
                      color: AppColors.primaryContainer,
                    ),
                    SizedBox(width: 2),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => ModalMapaLocal.mostrar(
                    context,
                    localizacao: item.localizacao,
                  ),
                  child: Text(
                    item.localizacao,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primaryContainer,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                ' • ${item.tempoAtras}',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}