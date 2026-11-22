import 'package:flutter/material.dart';

import '../theme.dart';
import 'asset_photo.dart';

/// Hero layar penuh: foto latar, dua lapis gradien gelap, teks di kiri bawah.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMd = Responsive.isMd(context);

    return ClipRect(
      child: Stack(
        children: [
          const Positioned.fill(
            child: AssetPhoto(
              'assets/images/hero-travel.jpg',
              semanticLabel: 'Pemandangan tebing dan pantai Indonesia',
            ),
          ),
          // bg-gradient-to-r from-black/60 via-black/30 to-transparent
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.black60,
                    AppColors.black30,
                    AppColors.transparentBlack,
                  ],
                ),
              ),
            ),
          ),
          // bg-gradient-to-t from-black/50 to-transparent
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.black50, AppColors.transparentBlack],
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, isMd ? 112 : 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jelajahi\nKeajaiban Dunia',
                          style: serif(
                            size: isMd ? 72 : 48,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'INDONESIA',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.43,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Text(
                            'Langkah pertama menuju petualangan tak terlupakan',
                            style: TextStyle(
                              fontSize: isMd ? 18 : 16,
                              height: isMd ? 1.56 : 1.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.white80,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
