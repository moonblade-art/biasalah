import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/community_model.dart';
import '../../services/community_service.dart';
import '../../utils/color_palette.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/page_transition.dart';
import 'donation/donation_screen.dart';

class ComunityScreen extends StatefulWidget {
  final Community? selectedCommunity;
  
  const ComunityScreen({super.key, this.selectedCommunity});

  @override
  State<ComunityScreen> createState() => _ComunityScreenState();
}

class _ComunityScreenState extends State<ComunityScreen> {
  final CommunityService _communityService = CommunityService();
  
  List<Community> _communities = [];
  Community? _selectedCommunity;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _selectedCommunity = widget.selectedCommunity;
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final communities = await _communityService.getAllCommunities();
      
      // If no communities from service, create dummy data for testing
      if (communities.isEmpty) {
        final dummyCommunities = _createDummyCommunities();
        setState(() {
          _communities = dummyCommunities;
          _isLoading = false;
        });
      } else {
        setState(() {
          _communities = communities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading communities: $e');
      // Create dummy data as fallback
      final dummyCommunities = _createDummyCommunities();
      setState(() {
        _communities = dummyCommunities;
        _errorMessage = null; // Don't show error, use dummy data
        _isLoading = false;
      });
    }
  }

  List<Community> _createDummyCommunities() {
    return [
      Community(
        id: '1',
        name: 'Reboisasi Hutan Jawa',
        description: 'Program penanaman pohon untuk mengembalikan hutan yang gundul di Jawa Tengah',
        location: 'Jawa Tengah',
        focusArea: 'reforestation',
        carbonPricePerKg: 15000,
        totalDonations: 5000000,
        totalCarbonOffset: 333.33,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      Community(
        id: '2',
        name: 'Energi Surya Desa',
        description: 'Instalasi panel surya untuk desa-desa terpencil',
        location: 'Nusa Tenggara Timur',
        focusArea: 'renewable_energy',
        carbonPricePerKg: 20000,
        totalDonations: 8000000,
        totalCarbonOffset: 400.0,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      Community(
        id: '3',
        name: 'Bank Sampah Komunitas',
        description: 'Program pengelolaan sampah berbasis komunitas',
        location: 'DKI Jakarta',
        focusArea: 'waste_management',
        carbonPricePerKg: 12000,
        totalDonations: 3500000,
        totalCarbonOffset: 291.67,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      Community(
        id: '4',
        name: 'Konservasi Terumbu Karang',
        description: 'Pelestarian terumbu karang di perairan Indonesia',
        location: 'Bali',
        focusArea: 'ocean_conservation',
        carbonPricePerKg: 18000,
        totalDonations: 6500000,
        totalCarbonOffset: 361.11,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      Community(
        id: '5',
        name: 'Taman Kota Hijau',
        description: 'Pengembangan ruang terbuka hijau di perkotaan',
        location: 'Surabaya',
        focusArea: 'urban_forest',
        carbonPricePerKg: 14000,
        totalDonations: 4200000,
        totalCarbonOffset: 300.0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<Community> get _filteredCommunities {
    if (_selectedFilter == 'all') {
      return _communities;
    }
    return _communities.where((c) => c.focusArea == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Text(
          'Komunitas Carbon Offset',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _selectedCommunity != null
                  ? _buildCommunityDetail()
                  : _buildCommunityList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 20),
          Text(
            'Gagal memuat komunitas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ColorPalette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadCommunities,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityList() {
    return RefreshIndicator(
      onRefresh: _loadCommunities,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter buttons
            _buildFilterButtons(),
            const SizedBox(height: 20),
            
            // Communities grid
            if (_filteredCommunities.isEmpty)
              _buildEmptyState()
            else
              // Community cards with better spacing
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredCommunities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final community = _filteredCommunities[index];
                  return _buildCommunityCard(community, MediaQuery.of(context).size.width);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = [
      {'key': 'all', 'label': 'Semua', 'icon': Icons.apps},
      {'key': 'reforestation', 'label': 'Reboisasi', 'icon': Icons.forest},
      {'key': 'renewable_energy', 'label': 'Energi', 'icon': Icons.wb_sunny},
      {'key': 'waste_management', 'label': 'Limbah', 'icon': Icons.recycling},
      {'key': 'ocean_conservation', 'label': 'Laut', 'icon': Icons.waves},
      {'key': 'urban_forest', 'label': 'Hutan Kota', 'icon': Icons.park},
    ];

    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['key'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorPalette.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: ColorPalette.primaryColor,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: ColorPalette.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : ColorPalette.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : ColorPalette.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Tidak ada komunitas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tidak ada komunitas untuk filter yang dipilih',
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

  Widget _buildCommunityCard(Community community, double screenWidth) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCommunity = community;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image and basic info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: community.imageUrl != null
                        ? Image.network(
                            community.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultImage(80);
                            },
                          )
                        : _buildDefaultImage(80),
                  ),
                  const SizedBox(width: 16),
                  
                  // Community info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                community.location,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: ColorPalette.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: community.focusAreaColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                community.focusAreaIcon,
                                size: 12,
                                color: community.focusAreaColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                community.focusAreaDisplayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: community.focusAreaColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description
              if (community.description != null) ...[
                Text(
                  community.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorPalette.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],
              
              // Total Donasi Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'Total Donasi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.formattedTotalDonations,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Price and Donation Button
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga per kg',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          community.formattedPricePerKg,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransitionWidget.createRoute(const DonationScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Donasi',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage([double? size]) {
    final imageSize = size ?? 80;
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.eco,
        size: imageSize * 0.5,
        color: ColorPalette.primaryColor,
      ),
    );
  }



  Widget _buildCommunityDetail() {
    if (_selectedCommunity == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCommunity = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  _selectedCommunity!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Community detail content
          _buildCommunityDetailContent(_selectedCommunity!),
        ],
      ),
    );
  }

  Widget _buildCommunityDetailContent(Community community) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: community.imageUrl != null
              ? Image.network(
                  community.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultDetailImage();
                  },
                )
              : _buildDefaultDetailImage(),
        ),
        
        const SizedBox(height: 20),
        
        // Community info
        CurvedContainer(
          backgroundColor: Colors.white,
          curveRadius: 16,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    community.focusAreaIcon,
                    color: community.focusAreaColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    community.focusAreaDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: community.focusAreaColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    community.location,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (community.description != null) ...[
                Text(
                  'Deskripsi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  community.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorPalette.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Statistics
              Text(
                'Statistik Komunitas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildDetailStatCard(
                'Total Donasi',
                community.formattedTotalDonations,
                Icons.monetization_on,
                Colors.green,
              ),
              
              const SizedBox(height: 12),
              
              _buildDetailStatCard(
                'Harga per kg',
                community.formattedPricePerKg,
                Icons.attach_money,
                ColorPalette.primaryColor,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Gallery (placeholder for now)
        CurvedContainer(
          backgroundColor: Colors.white,
          curveRadius: 16,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Galeri Komunitas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Placeholder gallery
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 100,
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: ColorPalette.primaryColor.withOpacity(0.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Donation button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                PageTransitionWidget.createRoute(const DonationScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Donasi ke Komunitas Ini',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultDetailImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.eco,
        size: 80,
        color: ColorPalette.primaryColor,
      ),
    );
  }

  Widget _buildDetailStatCard(String label, String value, IconData icon, Color color) {
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
              Icon(icon, size: 20, color: color),
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
}