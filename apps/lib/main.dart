import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/placeholder_page.dart';
import 'theme.dart';

void main() => runApp(const TripsyApp());

class TripsyApp extends StatelessWidget {
  const TripsyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tripsyyy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
            .copyWith(primary: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
      ),
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/explore':
      return _page(settings, const PlaceholderPage(title: 'Jelajahi'));
    case '/itinerary':
      return _page(settings, const PlaceholderPage(title: 'Itinerary'));
    case '/auth':
      final args = settings.arguments;
      final isSignup = args is Map && args['mode'] == 'signup';
      return _page(
        settings,
        PlaceholderPage(title: isSignup ? 'Daftar' : 'Masuk'),
      );
    case '/':
    default:
      return _page(settings, const HomePage());
  }
}

MaterialPageRoute<dynamic> _page(RouteSettings settings, Widget child) {
  return MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
}
