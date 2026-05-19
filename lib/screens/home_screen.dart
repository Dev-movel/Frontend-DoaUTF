import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/home/hero_section.dart';
import '../widgets/home/impact_section.dart';
import '../widgets/home/how_it_works_section.dart';
import '../widgets/home/community_section.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/debug/agendamento_test_fab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/home'),
      floatingActionButton: const AgendamentoTestFAB(),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(),
            ImpactSection(),
            HowItWorksSection(),
            CommunitySection(),
            HomeFooter(),
          ],
        ),
      ),
    );
  }
}
