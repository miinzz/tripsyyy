import 'package:flutter/material.dart';

import '../theme.dart';

class TripsyLogo extends StatelessWidget {
  const TripsyLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/tripsy-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Logo Tripsy',
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.location_on, size: size, color: AppColors.primary),
    );
  }
}
