import 'package:flutter/material.dart';

/// Gambar aset (object-cover). Jika file belum ada, tampil placeholder
/// sehingga aplikasi tetap bisa dijalankan.
class AssetPhoto extends StatelessWidget {
  const AssetPhoto(this.path, {super.key, this.semanticLabel});

  final String path;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0xFF334155),
        child: Center(
          child: Icon(Icons.image_outlined, color: Color(0x4DFFFFFF), size: 48),
        ),
      ),
    );
  }
}
