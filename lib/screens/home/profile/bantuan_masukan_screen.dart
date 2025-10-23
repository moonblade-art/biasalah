import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BantuanMasukanScreen extends StatelessWidget {
  const BantuanMasukanScreen({super.key});

  // Fungsi untuk membuka WhatsApp
  _launchWhatsApp() async {
    const String phoneNumber = '6282161028238'; // Sesuai kan nomor wa nya
    const String message = 'P Mabar';
    final String url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Tidak dapat membuka WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bantuan & Masukan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Tentang Aplikasi
            _buildSectionHeader('Tentang EcoTrack'),
            _buildInfoCard(
              'EcoTrack adalah aplikasi mobile inovatif yang membantu Anda menghitung jejak karbon kendaraan dan emisi transportasi secara real-time. Dengan fitur tracking yang akurat dan sistem offset karbon melalui donasi, kami berkomitmen meningkatkan kesadaran lingkungan pengguna dalam mengurangi dampak perubahan iklim.',
            ),

            // Fitur Utama
            _buildSectionHeader('Fitur Utama'),
            _buildFeatureItem(
              Icons.track_changes,
              'Tracking Real-time',
              'Lacak perjalanan dan hitung emisi karbon secara real-time dengan akurasi tinggi',
            ),
            _buildFeatureItem(
              Icons.forest,
              'Offset Karbon',
              'Lakukan donasi untuk menyeimbangkan jejak karbon Anda melalui program penanaman pohon',
            ),
            _buildFeatureItem(
              Icons.history,
              'Riwayat Perjalanan & Donasi',
              'Akses lengkap riwayat perjalanan karbon dan donasi yang telah dilakukan',
            ),
            _buildFeatureItem(
              Icons.dashboard,
              'Dashboard Analytics',
              'Pantau statistik karbon dan perkembangan pengurangan emisi Anda',
            ),
            _buildFeatureItem(
              Icons.person,
              'Profile Management',
              'Kelola profil dan preferensi akun Anda',
            ),

            // Subfitur Riwayat
            _buildSectionHeader('Fitur Riwayat'),
            _buildInfoCard(
              'Fitur Riwayat memungkinkan Anda melihat detail lengkap dari semua aktivitas:\n\n• Riwayat Perjalanan - Detail jarak, emisi karbon, dan rute perjalanan\n• Riwayat Donasi - Catatan donasi offset karbon dan dampak lingkungan\n• Detail Analytics - Analisis tren pengurangan emisi over time',
            ),

            // Masalah & Solusi
            _buildSectionHeader('Masalah Umum & Solusi'),
            _buildProblemSolutionCard(
              'Tracking tidak akurat atau tidak berfungsi',
              'Pastikan GPS perangkat aktif, beri izin lokasi untuk aplikasi, dan pastikan sinyal internet stabil. Restart aplikasi jika diperlukan.',
            ),
            _buildProblemSolutionCard(
              'Donasi gagal diproses',
              'Periksa koneksi internet, pastikan metode pembayaran valid, dan coba lagi dalam beberapa menit. Jika masih gagal, hubungi support.',
            ),
            _buildProblemSolutionCard(
              'Aplikasi crash atau lambat',
              'Update aplikasi ke versi terbaru, hapus cache di pengaturan perangkat, atau restart perangkat Anda.',
            ),
            _buildProblemSolutionCard(
              'Data tidak tersinkronisasi',
              'Pastikan terkoneksi internet stabil. Login ulang dapat membantu menyinkronkan data terbaru.',
            ),
            _buildProblemSolutionCard(
              'Lupa password atau masalah login',
              'Gunakan fitur "Lupa Password" di halaman login atau hubungi support untuk reset akun.',
            ),
            _buildProblemSolutionCard(
              'Riwayat tidak muncul atau tidak lengkap',
              'Pastikan koneksi internet stabil dan tunggu beberapa saat untuk sinkronisasi data. Jika masalah berlanjut, hubungi support.',
            ),

            const SizedBox(height: 20),

            // Hubungi Kami
            Center(
              child: Column(
                children: [
                  _buildSectionHeaderCenter('Butuh Bantuan Lebih Lanjut?'),
                  _buildContactCard(),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget untuk header section rata kiri
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  // Widget untuk header section di tengah
  Widget _buildSectionHeaderCenter(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  // Widget untuk kartu informasi
  Widget _buildInfoCard(String content) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  // Widget untuk item fitur
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    );
  }

  // Widget untuk kartu masalah & solusi
  Widget _buildProblemSolutionCard(String problem, String solution) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    problem,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solution,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk kartu kontak
  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: const Color(0xFFE8F5E8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.support_agent,
                size: 50,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tim Support EcoTrack',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kami siap membantu menyelesaikan masalah Anda dengan cepat dan ramah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hubungi kami melalui WhatsApp untuk bantuan cepat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat, size: 20),
                label: const Text(
                  'Hubungi via WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _launchWhatsApp,
              ),
              const SizedBox(height: 16),
              const Text(
                'Senin – Jumat, 09:00 – 17:00 WIB',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}