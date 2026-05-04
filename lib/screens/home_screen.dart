import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: const [
            _Navbar(),
            _HeroSection(),
            _ImpactSection(),
            _HowItWorks(),
            _CommunitySection(),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ─── NAVBAR ───────────────────────────────────────────────────────────────────
class _Navbar extends StatelessWidget {
  const _Navbar();

  void _openLoginModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: LoginScreen(),
      ),
    );
  }

  void _openSignupModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DoaUTF',
            style: AppTextStyles.headline.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _openLoginModal(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                ),
                child: const Text('Login'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _openSignupModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cadastrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── HERO SECTION ─────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 60,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeroText(isMobile: isMobile),
                const SizedBox(height: 50),
                _HeroImage(isMobile: isMobile),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _HeroText(isMobile: isMobile)),
                const SizedBox(width: 60),
                Expanded(child: _HeroImage(isMobile: isMobile)),
              ],
            ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final bool isMobile;
  const _HeroText({required this.isMobile});

  void _openLoginModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: LoginScreen(),
      ),
    );
  }

  void _openSignupModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Dê vida nova ao\nque você não\nprecisa mais.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: AppTextStyles.hero.copyWith(
            fontSize: isMobile ? 42 : 64,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Uma rede logística contínua para a generosidade.\n'
          'Conecte-se com colegas, recicle itens e acompanhe\n'
          'sua contribuição ambiental em tempo real.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: AppTextStyles.subtitle.copyWith(fontSize: 18, height: 1.6),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => _openSignupModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Começar Agora'),
            ),
            OutlinedButton(
              onPressed: () => _openLoginModal(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 22,
                ),
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Fazer Login',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final bool isMobile;
  const _HeroImage({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/image/home.jpg',
        height: isMobile ? 350 : 550,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ERRO IMAGEM: $error');
          return Container(
            height: isMobile ? 350 : 550,
            color: Colors.red,
            child: Center(
              child: Text(
                '$error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── IMPACT SECTION ───────────────────────────────────────────────────────────
class _ImpactSection extends StatelessWidget {
  const _ImpactSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          Text(
            'O Impacto da Generosidade Compartilhada',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Cada item que encontra um novo lar através do DoaUTF representa '
              'um passo para longe do consumo linear e um avanço para a sustentabilidade local.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 18, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HOW IT WORKS ─────────────────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Column(
        children: [
          Text(
            'Como funciona',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 42),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureCard(
                icon: Icons.upload_file_outlined,
                title: 'Postagem Fácil',
                description:
                    'Publique itens rapidamente com fotos e descrição em poucos passos.',
              ),
              _FeatureCard(
                icon: Icons.local_shipping_outlined,
                title: 'Logística Segura',
                description:
                    'Rede segura de transporte entre doadores e recebedores.',
              ),
              _FeatureCard(
                icon: Icons.eco_outlined,
                title: 'Impacto Ambiental',
                description:
                    'Acompanhe sua contribuição ambiental em tempo real.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.featureTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

// ─── COMMUNITY SECTION ────────────────────────────────────────────────────────
class _CommunitySection extends StatelessWidget {
  const _CommunitySection();

  void _openSignupModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            'Faça parte do movimento da generosidade.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sideTitle.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _openSignupModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 20,
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Criar Conta Gratuitamente'),
          ),
        ],
      ),
    );
  }
}

// ─── FOOTER ───────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 20),
          Text(
            '© 2024 DoaUTF - Tecnologia para o Bem Comum',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
