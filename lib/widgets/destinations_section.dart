import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'app_container.dart';
import 'asset_photo.dart';

class Destination {
  const Destination({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.mapsUrl,
  });

  final String category;
  final String title;
  final String subtitle;
  final String image;
  final String mapsUrl;
}

const _destinations = <Destination>[
  Destination(
    category: 'Alam',
    title: 'Ubud, Bali',
    subtitle: 'Bali, Indonesia',
    image: 'assets/images/dest-bali.jpg',
    mapsUrl: 'https://www.google.com/maps/search/?api=1&query=Ubud+Bali',
  ),
  Destination(
    category: 'Bahari',
    title: 'Raja Ampat',
    subtitle: 'Papua Barat, Indonesia',
    image: 'assets/images/dest-raja-ampat.jpg',
    mapsUrl: 'https://www.google.com/maps/search/?api=1&query=Raja+Ampat',
  ),
  Destination(
    category: 'Budaya',
    title: 'Candi Borobudur',
    subtitle: 'Yogyakarta, Indonesia',
    image: 'assets/images/dest-yogyakarta.jpg',
    mapsUrl: 'https://www.google.com/maps/search/?api=1&query=Candi+Borobudur',
  ),
  Destination(
    category: 'Petualangan',
    title: 'Labuan Bajo',
    subtitle: 'NTT, Indonesia',
    image: 'assets/images/dest-labuan-bajo.jpg',
    mapsUrl: 'https://www.google.com/maps/search/?api=1&query=Labuan+Bajo',
  ),
];

class DestinationsSection extends StatelessWidget {
  const DestinationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMd = Responsive.isMd(context);
    final columns = Responsive.isLg(context)
        ? 4
        : Responsive.isSm(context)
            ? 2
            : 1;

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 96),
      child: AppContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'POPULER',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.43,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Destinasi Favorit',
                        style: serif(
                          size: isMd ? 48 : 30,
                          weight: FontWeight.w800,
                          height: isMd ? 1.0 : 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMd)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/explore'),
                      child: const Text(
                        'Lihat semua →',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 48),
            GridView.count(
              crossAxisCount: columns,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 3 / 4,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final d in _destinations) _DestinationCard(destination: d),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatefulWidget {
  const _DestinationCard({required this.destination});

  final Destination destination;

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  bool _hover = false;

  /// Tanpa url_launcher: tautan Google Maps disalin ke clipboard.
  /// Untuk membuka langsung di browser, tambahkan paket url_launcher
  /// setelah SDK/proyek berada di path tanpa spasi.
  Future<void> _open() async {
    await Clipboard.setData(ClipboardData(text: widget.destination.mapsUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tautan Google Maps "${widget.destination.title}" disalin',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _open,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: _hover ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: AssetPhoto(d.image, semanticLabel: d.title),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.black70, AppColors.transparentBlack],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.category,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.43,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        d.title,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.56,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        d.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.43,
                          color: AppColors.white80,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
