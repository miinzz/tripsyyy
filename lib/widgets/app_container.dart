import 'package:flutter/material.dart';

import '../theme.dart';

/// Setara `container mx-auto px-4` pada Tailwind.
class AppContainer extends StatelessWidget {
  const AppContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.containerMaxWidth(width),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}
