import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/donation_model.dart';
import '../../../services/donation_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';
import '../../../widgets/page_transition.dart';
import '../donation/donation_detail_screen.dart';

class HistoryOffsetScreen extends StatefulWidget {
  const HistoryOffsetScreen({super.key});

  @override
  State<HistoryOffsetScreen> createState() => _HistoryOffsetScreenState();
}

class _HistoryOffsetScreenState extends State<HistoryOffsetScreen> {
  final DonationService _donationService = DonationService();
  
  List<Donation> _donations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final donations = await _donationService.getUserDonations(limit: 50);
      
      setState(() {
        _donations = donations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Donation> get _filteredDonations {
    switch (_selectedFilter) {
      case 'success':
        return _donations.where((d) => d.isSuccessful).toList();
      case 'pending':
        return _donations.where((d) => d.isPending).toList();
      case 'failed':
        return _donations.where((d) => d.isFailed).toList();
      default:
        return _donations;
    }
  }



  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? _buildErrorState()
            : _buildContent();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 20),
          Text(
            'Gagal memuat riwayat',
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
            onPressed: _loadDonations,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadDonations,
      child: _filteredDonations.isEmpty
          ? _buildEmptyStateWithFilter()
          : Column(
              children: [
                // Filter buttons at top
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildFilterButtons(),
                ),
                // Donations list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _filteredDonations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final donation = _filteredDonations[index];
                      return _buildDonationCard(donation);
                    },
                  ),
                ),
              ],
            ),
    );
  }



  Widget _buildFilterButtons() {
    final filters = [
      {'key': 'all', 'label': 'Semua', 'count': _donations.length},
      {'key': 'success', 'label': 'Berhasil', 'count': _donations.where((d) => d.isSuccessful).length},
      {'key': 'pending', 'label': 'Pending', 'count': _donations.where((d) => d.isPending).length},
      {'key': 'failed', 'label': 'Gagal', 'count': _donations.where((d) => d.isFailed).length},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                '${filter['label']} (${filter['count']})',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : ColorPalette.primaryColor,
                ),
              ),
              selectedColor: ColorPalette.primaryColor,
              backgroundColor: Colors.white,
              side: BorderSide(color: ColorPalette.primaryColor),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateWithFilter() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'success':
        message = 'Belum ada donasi yang berhasil';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        message = 'Tidak ada donasi yang pending';
        icon = Icons.pending_outlined;
        break;
      case 'failed':
        message = 'Tidak ada donasi yang gagal';
        icon = Icons.error_outline;
        break;
      default:
        message = 'Belum ada riwayat carbon offset';
        icon = Icons.eco_outlined;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Filter buttons at top
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildFilterButtons(),
          ),
          
          // Empty state centered
          Container(
            height: MediaQuery.of(context).size.height * 0.5, // Take half screen height for centering
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Mulai donasi untuk carbon offset dan lihat riwayatnya di sini',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: ColorPalette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'success':
        message = 'Belum ada donasi yang berhasil';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        message = 'Tidak ada donasi yang pending';
        icon = Icons.pending_outlined;
        break;
      case 'failed':
        message = 'Tidak ada donasi yang gagal';
        icon = Icons.error_outline;
        break;
      default:
        message = 'Belum ada riwayat carbon offset';
        icon = Icons.eco_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mulai donasi untuk carbon offset dan lihat riwayatnya di sini',
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



  Widget _buildDonationCard(Donation donation) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransitionWidget.createRoute(
            DonationDetailScreen(donation: donation),
          ),
        );
      },
      child: CurvedContainer(
        backgroundColor: Colors.white,
        curveRadius: 12,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    donation.communityName ?? 'Komunitas',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(donation),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Location and focus area
            if (donation.communityLocation != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    donation.communityLocation!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Amount and carbon info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Jumlah Donasi',
                    donation.formattedAmount,
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'CO₂ Offset',
                    donation.formattedCarbonAmount,
                    Icons.eco,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date and payment method
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${donation.formattedDonatedDate} • ${donation.formattedDonatedTime}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  donation.paymentMethodDisplayName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            ),
            
            // Notes if available
            if (donation.notes != null && donation.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        donation.notes!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: ColorPalette.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Donation donation) {
    Color color;
    IconData icon;
    
    if (donation.isSuccessful) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (donation.isPending) {
      color = Colors.orange;
      icon = Icons.pending;
    } else {
      color = Colors.red;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            donation.paymentStatusDisplayName,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: ColorPalette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}