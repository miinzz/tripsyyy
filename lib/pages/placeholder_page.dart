import 'package:flutter/material.dart';

/// Halaman sementara untuk rute /explore, /itinerary, dan /auth.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Halaman $title belum dibuat')),
    );
  }
}
