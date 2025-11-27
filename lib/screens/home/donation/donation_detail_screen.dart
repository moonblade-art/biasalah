import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/donation_model.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';

class DonationDetailScreen extends StatelessWidget {
  final Donation donation;

  const DonationDetailScreen({
    super.key,
    required this.donation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Text(
          'Detail Donasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(),
            const SizedBox(height: 20),
            
            // Community info
            _buildCommunityInfo(),
            const SizedBox(height: 20),
            
            // Donation details
            _buildDonationDetails(),
            const SizedBox(height: 20),
            
            // Payment info
            _buildPaymentInfo(),
            
            // Notes if available
            if (donation.notes != null && donation.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNotesCard(),
            ],
            
            // Action buttons
            const SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (donation.isSuccessful) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Donasi Berhasil';
    } else if (donation.isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Menunggu Pembayaran';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Donasi Gagal';
    }

    return CurvedContainer(
      backgroundColor: statusColor.withOpacity(0.1),
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(statusIcon, size: 48, color: statusColor),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            donation.paymentStatusDisplayName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ColorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInfo() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komunitas',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            donation.communityName ?? 'Komunitas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.primaryColor,
            ),
          ),
          
          if (donation.communityLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  donation.communityLocation!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          
          if (donation.communityFocusArea != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getFocusAreaDisplayName(donation.communityFocusArea!),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorPalette.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonationDetails() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Donasi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Amount
          _buildDetailRow(
            'Jumlah Donasi',
            donation.formattedAmount,
            Icons.monetization_on,
            Colors.green,
          ),
          
          const SizedBox(height: 12),
          
          // Carbon offset
          _buildDetailRow(
            'CO₂ yang Di-offset',
            donation.formattedCarbonAmount,
            Icons.eco,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Date
          _buildDetailRow(
            'Tanggal Donasi',
            '${donation.formattedDonatedDate} ${donation.formattedDonatedTime}',
            Icons.calendar_today,
            ColorPalette.textSecondary,
          ),
          
          if (donation.paidAt != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'Tanggal Pembayaran',
              _formatDateTime(donation.paidAt!),
              Icons.payment,
              Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment method
          _buildDetailRow(
            'Metode Pembayaran',
            donation.paymentMethodDisplayName,
            Icons.payment,
            ColorPalette.textSecondary,
          ),
          
          if (donation.midtransOrderId != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'Order ID',
              donation.midtransOrderId!,
              Icons.receipt,
              ColorPalette.textSecondary,
            ),
          ],
          
          if (donation.transactionId != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'Transaction ID',
              donation.transactionId!,
              Icons.confirmation_number,
              ColorPalette.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: ColorPalette.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Catatan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              donation.notes!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: ColorPalette.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: ColorPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Pay now button for pending donations
        if (donation.isPending && donation.paymentUrl != null) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(donation.paymentUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.payment, color: Colors.white),
              label: Text(
                'Bayar Sekarang',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Share button for successful donations
        if (donation.isSuccessful) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                _shareSuccess(context);
              },
              icon: Icon(Icons.share, color: ColorPalette.primaryColor),
              label: Text(
                'Bagikan Pencapaian',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorPalette.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Back button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Kembali',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareSuccess(BuildContext context) {
    final message = '''
🌱 Saya baru saja berkontribusi untuk lingkungan!

💚 Donasi: ${donation.formattedAmount}
🌍 CO₂ Offset: ${donation.formattedCarbonAmount}
🏢 Komunitas: ${donation.communityName}

Mari bersama-sama jaga bumi kita! 🌍
#CarbonOffset #EcoTrack #SaveEarth
    ''';
    
    // Here you would implement actual sharing functionality
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur berbagi akan segera tersedia!'),
        backgroundColor: ColorPalette.primaryColor,
      ),
    );
  }

  String _getFocusAreaDisplayName(String focusArea) {
    switch (focusArea) {
      case 'reforestation':
        return 'Reboisasi';
      case 'renewable_energy':
        return 'Energi Terbarukan';
      case 'waste_management':
        return 'Pengelolaan Limbah';
      case 'ocean_conservation':
        return 'Konservasi Laut';
      case 'urban_forest':
        return 'Hutan Kota';
      default:
        return focusArea;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}