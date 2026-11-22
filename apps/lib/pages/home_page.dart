import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/destinations_section.dart';
import '../widgets/features_section.dart';
import '../widgets/footer.dart';
import '../widgets/hero_section.dart';
import '../widgets/navbar.dart';

/// Halaman beranda: navbar tetap (fixed) di atas, konten bisa di-scroll.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                HeroSection(),
                DestinationsSection(),
                FeaturesSection(),
                SiteFooter(),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: SiteNavbar()),
        ],
      ),
    );
  }
}
