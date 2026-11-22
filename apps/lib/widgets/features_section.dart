import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_container.dart';
import 'responsive_grid.dart';

class _Feature {
  const _Feature(this.title, this.description);

  final String title;
  final String description;
}

const _features = <_Feature>[
  _Feature('Personal Picks', 'Temukan tempat wisata sesuai minat.'),
  _Feature(
    'Smart Itenerary',
    'Susun rencana perjalanan sesuai preferensi dan waktu.',
  ),
  _Feature(
    'Travel Sync',
    'Bagikan rencana perjalanan dengan teman atau keluarga.',
  ),
];

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMd = Responsive.isMd(context);
    final columns = Responsive.isLg(context)
        ? 3
        : Responsive.isSm(context)
            ? 2
            : 1;

    return Container(
      width: double.infinity,
      color: AppColors.mutedHalf30,
      padding: const EdgeInsets.symmetric(vertical: 96),
      child: AppContainer(
        child: Column(
          children: [
            Text(
              'FITUR',
              style: const TextStyle(
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua yang Kamu Butuhkan',
              textAlign: TextAlign.center,
              style: serif(
                size: isMd ? 48 : 30,
                weight: FontWeight.w800,
                height: isMd ? 1.0 : 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 576),
              child: const Text(
                'Tripsy hadir untuk membuat perjalanan lebih mudah direncanakan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.56,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: 64),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
              child: ResponsiveGrid(
                columns: columns,
                gap: 20,
                children: [
                  for (final f in _features) _FeatureCard(feature: f),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 18,
              height: 1.56,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.43,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
