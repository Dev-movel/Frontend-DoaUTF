import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/home/home_navbar.dart';
import '../widgets/home/hero_section.dart';
import '../widgets/home/impact_section.dart';
import '../widgets/home/how_it_works_section.dart';
import '../widgets/home/community_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HomeNavbar(),
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