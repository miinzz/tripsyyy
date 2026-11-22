import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_container.dart';
import 'tripsy_logo.dart';

/// Navbar tetap di atas (fixed). Link tengah dan tombol auth hanya muncul
/// di layar md ke atas (>= 768), sama seperti `hidden md:flex` pada web.
class SiteNavbar extends StatelessWidget {
  const SiteNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMd = Responsive.isMd(context);

    return AppContainer(
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Brand(),
            if (isMd)
              const Row(
                children: [
                  NavLink(label: 'Beranda', route: '/', active: true),
                  SizedBox(width: 20),
                  NavLink(label: 'Jelajahi', route: '/explore'),
                  SizedBox(width: 20),
                  NavLink(label: 'Itinerary', route: '/itinerary'),
                ],
              ),
            if (isMd)
              const Row(
                children: [
                  NavLink(label: 'Masuk', route: '/auth'),
                  SizedBox(width: 8),
                  NavLink(
                    label: 'Daftar',
                    route: '/auth',
                    arguments: {'mode': 'signup'},
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TripsyLogo(size: 32),
            SizedBox(width: 8),
            Text(
              'Tripsy',
              style: TextStyle(
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link navigasi teks sederhana.
class NavLink extends StatelessWidget {
  const NavLink({
    super.key,
    required this.label,
    required this.route,
    this.active = false,
    this.arguments,
  });

  final String label;
  final String route;
  final bool active;
  final Object? arguments;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final nav = Navigator.of(context);
          if (route == '/') {
            nav.pushNamedAndRemoveUntil('/', (r) => false);
          } else {
            nav.pushNamed(route, arguments: arguments);
          }
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: active ? AppColors.primary : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}
