import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../models/user_model.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';
import '../../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserProfileService _profileService = UserProfileService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final ImagePicker _imagePicker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _errorMessage = 'User tidak terautentikasi';
          _isLoading = false;
        });
        return;
      }

      final profile = await _profileService.getProfile(user.id);
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.fullName;
          _emailController.text = profile.email;
          // _phoneController.text = profile.phone ?? ''; // Removed
          // _addressController.text = profile.address ?? ''; // Removed
          _currentImageUrl = profile.profilePictureUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Profil tidak ditemukan';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show bottom sheet to choose between camera and gallery
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.camera_alt, size: 32, color: ColorPalette.primaryColor),
                              const SizedBox(height: 8),
                              Text(
                                'Kamera',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.photo_library, size: 32, color: ColorPalette.primaryColor),
                              const SizedBox(height: 8),
                              Text(
                                'Galeri',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );
        
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      // Handle MissingPluginException gracefully
      if (e.toString().contains('MissingPluginException')) {
        _showSnackBar('Fitur upload foto belum tersedia di platform ini', isError: true);
      } else {
        _showSnackBar('Gagal memilih gambar: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User tidak terautentikasi');
      }

      // 1. Update Basic Profile (Name/Email/Image)
      // Upload image if selected
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        try {
          imageUrl = await _profileService.uploadProfilePicture(user.id, _selectedImage!);
        } catch (e) {
          _showSnackBar('Gagal mengupload gambar: ${e.toString()}', isError: true);
          setState(() => _isSaving = false);
          return;
        }
      }

      // Perform Profile Update
      final updatedProfile = await _profileService.updateProfile(
        userId: user.id,
        fullName: _nameController.text.trim() != _userProfile!.fullName 
            ? _nameController.text.trim() 
            : null,
        email: _emailController.text.trim() != _userProfile!.email 
            ? _emailController.text.trim() 
            : null,
        // Removed phone/address update
        profilePictureUrl: imageUrl != _currentImageUrl ? imageUrl : null,
      );

      // 2. Handle Password Change
      if (_newPasswordController.text.isNotEmpty) {
        // Validation: Current Password must be provided
        if (_currentPasswordController.text.isEmpty) {
          throw Exception('Kata sandi saat ini wajib diisi');
        }

        // Re-authenticate to verify current password
        try {
          // Attempt sign in to verify credentials
          await _authService.signIn(
            email: user.email!, // Use current email
            password: _currentPasswordController.text,
          );
          
          // If successful, update to new password
          await _authService.updatePassword(_newPasswordController.text);
          
          _showSnackBar('Password berhasil diubah');
        } catch (e) {
          throw Exception('Kata sandi saat ini salah atau gagal memverifikasi');
        }
      }

      setState(() {
        _userProfile = updatedProfile;
        _isSaving = false;
        // Reset password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      _showSnackBar('Profil berhasil diperbarui');

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error saving profile: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal: ${e.toString().replaceAll('Exception:', '')}";
          _isSaving = false;
        });
        _showSnackBar(e.toString().replaceAll('Exception:', ''), isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            _buildProfilePictureSection(),

            const SizedBox(height: 40),

            // Form Fields
            CurvedContainer(
              backgroundColor: Colors.white,
              curveRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Pribadi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name Field
                  _buildFormField(
                    label: 'Nama Lengkap',
                    controller: _nameController,
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama lengkap tidak boleh kosong';
                      }
                      if (value.trim().length < 2) {
                        return 'Nama lengkap minimal 2 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Email Field
                  _buildFormField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  Text(
                    'Ubah Kata Sandi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Password
                  _buildPasswordField(
                    label: 'Kata Sandi Saat Ini',
                    controller: _currentPasswordController,
                    isObscure: _isObscureCurrent,
                    onToggleObscure: () {
                      setState(() {
                        _isObscureCurrent = !_isObscureCurrent;
                      });
                    },
                    validator: (value) {
                       if (_newPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
                        return 'Kata sandi saat ini diperlukan untuk mengubah password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // New Password
                  _buildPasswordField(
                    label: 'Kata Sandi Baru',
                    controller: _newPasswordController,
                    isObscure: _isObscureNew,
                    onToggleObscure: () {
                      setState(() {
                        _isObscureNew = !_isObscureNew;
                      });
                    },
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length < 8) return 'Minimal 8 karakter';
                        if (!value.contains(RegExp(r'[A-Z]'))) return 'Harus ada huruf besar (A-Z)';
                        if (!value.contains(RegExp(r'[a-z]'))) return 'Harus ada huruf kecil (a-z)';
                        if (!value.contains(RegExp(r'[0-9]'))) return 'Harus ada angka (0-9)';
                        if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return 'Harus ada simbol (!@#\$%^&*)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Syarat: Min 8 karakter, 1 Huruf Besar, 1 Huruf Kecil, 1 Angka, 1 Simbol',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password
                  _buildPasswordField(
                    label: 'Konfirmasi Kata Sandi Baru',
                    controller: _confirmPasswordController,
                    isObscure: _isObscureConfirm,
                    onToggleObscure: () {
                      setState(() {
                        _isObscureConfirm = !_isObscureConfirm;
                      });
                    },
                    validator: (value) {
                      if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Account Info (Read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Informasi Akun',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bergabung: ${_userProfile?.createdAt != null ? _formatDate(_userProfile!.createdAt!) : "Tidak diketahui"}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_userProfile?.updatedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Terakhir diperbarui: ${_formatDate(_userProfile!.updatedAt!)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Save Button
            PrimaryButton(
              text: 'Simpan Perubahan',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: ColorPalette.primaryColor, width: 3),
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _currentImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _currentImageUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Edit Informasi Profil',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Perbarui informasi profil Anda di bawah ini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ColorPalette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 60,
      color: ColorPalette.primaryColor.withOpacity(0.5),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ColorPalette.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorPalette.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: ColorPalette.primaryColor),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggleObscure,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorPalette.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}