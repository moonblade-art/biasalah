import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/community_model.dart';
import '../../../services/community_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/page_transition.dart';
import '/navigations/navigations.dart';
import 'community_detail_screen.dart';

class ComunityScreen extends StatefulWidget {
  const ComunityScreen({super.key});

  @override
  State<ComunityScreen> createState() => _ComunityScreenState();
}

class _ComunityScreenState extends State<ComunityScreen>
    with AutomaticKeepAliveClientMixin {
  final CommunityService _communityService = CommunityService();

  List<Community> _communities = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCommunities();
    });
  }

  Future<void> _loadCommunities() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final communities = await _communityService.getAllCommunities();

      if (!mounted) return;

      if (communities.isEmpty) {
        setState(() {
          _communities = _createDummyCommunities();
          _isLoading = false;
        });
      } else {
        setState(() {
          _communities = communities;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _communities = _createDummyCommunities();
        _isLoading = false;
      });
    }
  }

  List<Community> _createDummyCommunities() {
    return [
      Community(
        id: '1',
        name: 'Reboisasi Hutan Jawa',
        description:
            'Program penanaman pohon untuk mengembalikan hutan yang gundul di Jawa Tengah',
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
    if (_selectedFilter == 'all') return _communities;
    return _communities.where((c) => c.focusArea == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IgnorePointer(
                ignoring: _isLoading,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildCommunityList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 18),
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Komunitas Carbon Offset",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
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
            _buildFilterButtons(),
            const SizedBox(height: 20),
            if (_filteredCommunities.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: _filteredCommunities
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildCommunityCard(c),
                        ))
                    .toList(),
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
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['key'];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                setState(() => _selectedFilter = f['key'] as String);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorPalette.primaryColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: ColorPalette.primaryColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(f['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : ColorPalette.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      f['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : ColorPalette.primaryColor,
                      ),
                    ),
                  ],
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
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Tidak ada komunitas',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            'Tidak ada komunitas untuk filter yang dipilih',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            PageTransitionWidget.createRoute(
              CommunityDetailScreen(community: community),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(community),
              const SizedBox(height: 16),
              if (community.description != null)
                Text(
                  community.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              const SizedBox(height: 16),
              _buildDonationCard(community),
              const SizedBox(height: 16),
              _buildBottomAction(community),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Community c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: c.imageUrl != null
              ? Image.network(
                  c.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultImage(80),
                )
              : _buildDefaultImage(80),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.location,
                      style: GoogleFonts.poppins(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.focusAreaColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.focusAreaIcon,
                        size: 12, color: c.focusAreaColor),
                    const SizedBox(width: 4),
                    Text(
                      c.focusAreaDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: c.focusAreaColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDonationCard(Community c) {
    return Container(
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
              Icon(Icons.monetization_on,
                  size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                'Total Donasi',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            c.formattedTotalDonations,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(Community c) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harga per kg',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                c.formattedPricePerKg,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => Navigations(
                    initialPage: 3, // langsung ke tab Donasi
                    community: c, // kirim data komunitas
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Donasi',
              style: GoogleFonts.poppins(
                color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.eco,
        size: size * 0.5,
        color: ColorPalette.primaryColor,
      ),
    );
  }
}
