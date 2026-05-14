import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import 'shared/form_widgets.dart';

const _kSurface   = Color(0xFFF4F4EF);
const _kGreenLime = Color(0xFFA3F69C);
const _kDashedBd  = Color(0xFFBFCABA);

class PhotosStep extends StatelessWidget {
  final List<XFile> fotos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  const PhotosStep({
    super.key,
    required this.fotos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Enviar Fotos',
          subtitle:
              'Adicione até 5 fotos. Imagens de alta qualidade aumentam o interesse.',
        ),
        const SizedBox(height: 20),
        if (fotos.isEmpty)
          _DropZone(onTap: onAddPhoto)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: fotos.length + (fotos.length < 5 ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == fotos.length) {
                return _AddMoreBtn(onTap: onAddPhoto);
              }
              return _PhotoThumbnail(
                xfile: fotos[i],
                onRemove: () => onRemovePhoto(i),
              );
            },
          ),
        const SizedBox(height: 10),
        Text(
          '${fotos.length}/5 fotos adicionadas',
          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline),
        ),
      ],
    );
  }
}

class _DropZone extends StatelessWidget {
  final VoidCallback onTap;
  const _DropZone({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _DashedBox(
        borderColor: _kDashedBd,
        bgColor: Colors.white,
        height: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: _kGreenLime, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera_outlined,
                  color: Color(0xFF002204), size: 24),
            ),
            const SizedBox(height: 16),
            Text('Câmera ou Galeria',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
}

class _AddMoreBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMoreBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _DashedBox(
        borderColor: _kDashedBd.withValues(alpha: 0.5),
        bgColor: _kSurface,
        height: double.infinity,
        child: const Icon(Icons.add, size: 22, color: AppColors.outline),
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
    required this.child,
    required this.borderColor,
    required this.bgColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: borderColor, bg: bgColor),
      child: SizedBox(
        height: height,
        width: double.infinity,
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
    const gap = 4.0;
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
          child: FutureBuilder<Uint8List>(
            future: xfile.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
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
