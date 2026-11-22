# Tripsy — Beranda (Flutter)

Port halaman beranda Tripsy dari HTML + Tailwind ke Flutter, dipecah ke
beberapa file. Tanpa paket tambahan (tidak memakai google_fonts atau
url_launcher), jadi aman dari error native assets `objective_c`.

## Dimasukkan ke proyek yang sudah ada

1. Hapus isi `lib/` proyek Anda, lalu salin seluruh folder `lib/` dari zip ini.
2. Di `pubspec.yaml` proyek Anda, **hapus** `google_fonts` dan `url_launcher`
   jika ada, lalu (opsional, untuk gambar) tambahkan:
   ```yaml
   flutter:
     assets:
       - assets/images/
   ```
3. Hapus `test/widget_test.dart` jika ada (merujuk ke `MyApp`).
4. Jalankan:
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

## Aset gambar (opsional)

Salin ke `assets/images/` dengan nama yang sama seperti di web:
`tripsy-logo.png`, `hero-travel.jpg`, `dest-bali.jpg`, `dest-raja-ampat.jpg`,
`dest-yogyakarta.jpg`, `dest-labuan-bajo.jpg`. Tanpa file ini, aplikasi tetap
jalan dengan placeholder.

## Catatan

- Warna ada di `lib/theme.dart` (`AppColors`); nilai `primary` adalah
  perkiraan, samakan dengan tema web Anda.
- Font serif memakai Georgia / Times New Roman (diatur di `serif()` pada
  `lib/theme.dart`).
- Kartu destinasi menyalin tautan Google Maps ke clipboard saat diketuk.
- Rute `/explore`, `/itinerary`, `/auth` masih halaman sementara.

## Struktur

```
lib/
  main.dart
  theme.dart
  pages/    home_page.dart, placeholder_page.dart
  widgets/  navbar, hero_section, destinations_section,
            features_section, footer, app_container, asset_photo,
            tripsy_logo, responsive_grid
```
