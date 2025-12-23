import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';
import '../../../widgets/primary_button.dart';

class BantuanMasukanScreen extends StatefulWidget {
  const BantuanMasukanScreen({super.key});

  @override
  State<BantuanMasukanScreen> createState() => _BantuanMasukanScreenState();
}

class _BantuanMasukanScreenState extends State<BantuanMasukanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Feedback form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Text(
          'Bantuan & Masukan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Tutorial'),
            Tab(text: 'Kontak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildTutorialTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final faqs = _getFAQData();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan yang Sering Diajukan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          ...faqs.map((faq) => _buildFAQItem(faq)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CurvedContainer(
        backgroundColor: Colors.white,
        curveRadius: 12,
        padding: const EdgeInsets.all(16),
        child: ExpansionTile(
          title: Text(
            faq['question']!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                faq['answer']!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: ColorPalette.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialTab() {
    final tutorials = _getTutorialData();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panduan Penggunaan EcoTrack',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          ...tutorials.map((tutorial) => _buildTutorialItem(tutorial)),
        ],
      ),
    );
  }

  Widget _buildTutorialItem(Map<String, dynamic> tutorial) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CurvedContainer(
        backgroundColor: Colors.white,
        curveRadius: 12,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    tutorial['icon'] as IconData,
                    color: ColorPalette.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tutorial['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tutorial['description'] as String,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: ColorPalette.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            
            // Steps
            ...(tutorial['steps'] as List<String>).asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: ColorPalette.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: ColorPalette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information
          _buildContactInfo(),
          const SizedBox(height: 20),
          
          // Feedback Form
          _buildFeedbackForm(),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hubungi Kami',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildContactItem(
            Icons.email,
            'Email',
            'support@ecotrack.id',
            () => _launchEmail('support@ecotrack.id'),
          ),
          
          const SizedBox(height: 12),
          
          _buildContactItem(
            Icons.phone,
            'Telepon',
            '+62 21 1234 5678',
            () => _launchPhone('+6221123456789'),
          ),
          
          const SizedBox(height: 12),
          
          _buildContactItem(
            Icons.language,
            'Website',
            'www.ecotrack.id',
            () => _launchWebsite('https://www.ecotrack.id'),
          ),
          
          const SizedBox(height: 12),
          
          _buildContactItem(
            Icons.location_on,
            'Alamat',
            'Jakarta, Indonesia',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: ColorPalette.primaryColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: ColorPalette.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: onTap != null ? ColorPalette.primaryColor : ColorPalette.textPrimary,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kirim Masukan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Category
            _buildCategorySelector(),
            const SizedBox(height: 16),
            
            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Subject
            _buildTextField(
              controller: _subjectController,
              label: 'Subjek',
              icon: Icons.subject,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Subjek tidak boleh kosong';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Message
            _buildTextField(
              controller: _messageController,
              label: 'Pesan',
              icon: Icons.message,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pesan tidak boleh kosong';
                }
                if (value.trim().length < 10) {
                  return 'Pesan minimal 10 karakter';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Send Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                text: _isSending ? 'Mengirim...' : 'Kirim Masukan',
                onPressed: _isSending ? null : _sendFeedback,
                isLoading: _isSending,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = {
      'general': 'Umum',
      'bug': 'Laporan Bug',
      'feature': 'Saran Fitur',
      'support': 'Bantuan Teknis',
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          children: categories.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            return FilterChip(
              selected: isSelected,
              label: Text(
                entry.value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : ColorPalette.primaryColor,
                ),
              ),
              selectedColor: ColorPalette.primaryColor,
              backgroundColor: Colors.white,
              side: const BorderSide(color: ColorPalette.primaryColor),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = entry.key;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: ColorPalette.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: ColorPalette.textSecondary,
        ),
        prefixIcon: Icon(icon, color: ColorPalette.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() {
        _isSending = true;
      });

      // Simulate sending feedback (replace with actual API call)
      await Future.delayed(const Duration(seconds: 2));
      
      _showSnackBar('Terima kasih! Feedback Anda telah dikirim.');
      
      // Clear form
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedCategory = 'general';
      });
      
    } catch (e) {
      _showSnackBar('Gagal mengirim feedback: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : ColorPalette.primaryColor,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=EcoTrack Support');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Tidak dapat membuka aplikasi email', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Tidak dapat membuka aplikasi telepon', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Tidak dapat membuka website', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  List<Map<String, String>> _getFAQData() {
    return [
      {
        'question': 'Apa itu Carbon Offset?',
        'answer': 'Carbon offset adalah cara untuk mengkompensasi emisi karbon yang dihasilkan dengan mendukung proyek-proyek yang mengurangi atau menyerap CO₂ dari atmosfer, seperti penanaman pohon atau energi terbarukan.'
      },
      {
        'question': 'Bagaimana cara menghitung emisi karbon saya?',
        'answer': 'Aplikasi EcoTrack menghitung emisi berdasarkan jenis kendaraan, jarak tempuh, dan jenis bahan bakar yang Anda gunakan. Setiap perjalanan akan dihitung secara otomatis menggunakan faktor emisi standar.'
      },
      {
        'question': 'Apakah donasi saya benar-benar membantu lingkungan?',
        'answer': 'Ya! Semua komunitas yang terdaftar di EcoTrack telah diverifikasi dan memiliki proyek nyata untuk mengurangi emisi karbon. Anda dapat melihat laporan dampak dari setiap komunitas.'
      },
      {
        'question': 'Bagaimana cara memilih komunitas untuk donasi?',
        'answer': 'Anda dapat memilih komunitas berdasarkan lokasi, jenis proyek (reboisasi, energi terbarukan, dll), dan harga per kg CO₂. Setiap komunitas memiliki deskripsi lengkap tentang proyek mereka.'
      },
      {
        'question': 'Apakah data perjalanan saya aman?',
        'answer': 'Ya, semua data Anda dienkripsi dan disimpan dengan aman. Kami tidak membagikan data pribadi Anda kepada pihak ketiga tanpa persetujuan Anda.'
      },
      {
        'question': 'Bagaimana cara mengubah profil saya?',
        'answer': 'Buka menu Profil, lalu pilih "Edit Profil". Anda dapat mengubah nama dan email Anda. Perubahan akan disimpan secara otomatis setelah Anda menekan tombol simpan.'
      },
    ];
  }

  List<Map<String, dynamic>> _getTutorialData() {
    return [
      {
        'title': 'Memulai dengan EcoTrack',
        'description': 'Panduan lengkap untuk memulai perjalanan eco-friendly Anda',
        'icon': Icons.play_circle_outline,
        'steps': [
          'Daftar akun dengan email Anda',
          'Verifikasi email untuk mengaktifkan akun',
          'Lengkapi profil Anda di menu Profile',
          'Mulai tracking perjalanan pertama Anda',
          'Lihat hasil emisi di dashboard'
        ]
      },
      {
        'title': 'Cara Tracking Perjalanan',
        'description': 'Pelajari cara melacak emisi karbon dari perjalanan Anda',
        'icon': Icons.directions_car,
        'steps': [
          'Buka menu "Tracking" di halaman utama',
          'Pilih jenis kendaraan yang Anda gunakan',
          'Pilih jenis bahan bakar kendaraan',
          'Masukkan jarak perjalanan dalam kilometer',
          'Aplikasi akan menghitung emisi CO₂ secara otomatis',
          'Simpan data perjalanan ke riwayat'
        ]
      },
      {
        'title': 'Melakukan Carbon Offset',
        'description': 'Kompensasi emisi karbon Anda dengan berdonasi',
        'icon': Icons.volunteer_activism,
        'steps': [
          'Buka menu "Komunitas" untuk melihat pilihan',
          'Pilih komunitas yang ingin Anda dukung',
          'Masukkan jumlah CO₂ yang ingin di-offset',
          'Pilih metode pembayaran yang tersedia',
          'Selesaikan pembayaran melalui gateway',
          'Donasi berhasil akan mengurangi emisi belum offset'
        ]
      },
      {
        'title': 'Memahami Statistik',
        'description': 'Pelajari cara membaca data dan progress Anda',
        'icon': Icons.bar_chart,
        'steps': [
          'Buka menu "Statistik" di profil Anda',
          'Lihat total emisi yang sudah dan belum di-offset',
          'Pantau progress donasi dan kontribusi Anda',
          'Lihat dampak lingkungan dari aksi Anda',
          'Raih achievement berdasarkan aktivitas Anda'
        ]
      }
    ];
  }
}