import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_container.dart';
import 'tripsy_logo.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMd = Responsive.isMd(context);

    const brandColumn = _BrandColumn();
    const productColumn = _ProductColumn();

    return Container(
      width: double.infinity,
      color: AppColors.foreground,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          AppContainer(
            child: isMd
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [brandColumn, productColumn],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      brandColumn,
                      SizedBox(height: 40),
                      productColumn,
                    ],
                  ),
          ),
          const SizedBox(height: 48),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 32),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.white10)),
            ),
            child: const Text(
              '© 2026 Tripsy.co. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.33,
                color: AppColors.white40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TripsyLogo(size: 28),
              SizedBox(width: 8),
              Text(
                'Tripsy',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.56,
                  fontWeight: FontWeight.w700,
                  color: AppColors.background,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Platform perencana perjalanan personal untuk menjelajahi Indonesia dan dunia.',
            style: TextStyle(
              fontSize: 14,
              height: 1.43,
              color: AppColors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductColumn extends StatelessWidget {
  const _ProductColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODUK',
          style: TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
        SizedBox(height: 16),
        _FooterLink(label: 'Jelajahi', route: '/explore'),
        SizedBox(height: 12),
        _FooterLink(label: 'Itinerary', route: '/itinerary'),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            height: 1.43,
            color: AppColors.white60,
          ),
        ),
      ),
    );
  }
}
