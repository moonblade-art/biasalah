import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../navigations/navigations.dart';

import '../../../models/trip_tracking_model.dart' as trip_model;
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/page_transition.dart';
import '../donation/donation_screen.dart';

class TrackingResultScreen extends StatelessWidget {
  final trip_model.TripTracking trip;

  const TrackingResultScreen({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // CUSTOM CURVED HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 18),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hasil Tracking",
                    style: GoogleFonts.poppins(
                      fontSize: 22, 
                      fontWeight: FontWeight.w600, 
                      color: Colors.white
                    ),
                  ),
                ],
              ),
            ),
            // BODY CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 50,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Center(
                      child: Text(
                        'Perjalanan Berhasil Dicatat!',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Trip Summary Card
                    CurvedContainer(
                      backgroundColor: Colors.white,
                      curveRadius: 16,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Perjalanan',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildSummaryRow('Jenis Kendaraan', trip.vehicleType),
                          _buildSummaryRow('Kapasitas Mesin', '${trip.engineCC} CC'),
                          _buildSummaryRow('Jarak Tempuh', trip.formattedDistance),
                          _buildSummaryRow('Tanggal', '${trip.tripDate.day}/${trip.tripDate.month}/${trip.tripDate.year}'),
                          
                          if (trip.startLocation != null)
                            _buildSummaryRow('Lokasi Awal', trip.startLocation!),
                          
                          if (trip.endLocation != null)
                            _buildSummaryRow('Lokasi Tujuan', trip.endLocation!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Emission Result Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: trip.emissionKg == 0.0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: trip.emissionKg == 0.0 ? Colors.green.shade200 : Colors.red.shade200
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            trip.emissionKg == 0.0 ? Icons.eco : Icons.co2,
                            size: 40,
                            color: trip.emissionKg == 0.0 ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            trip.emissionKg == 0.0 ? 'Emisi Karbon' : 'Emisi Karbon Dihasilkan',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trip.formattedEmission,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: trip.emissionKg == 0.0 ? Colors.green.shade600 : Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trip.emissionKg == 0.0 
                                ? 'Selamat! Perjalanan ini ramah lingkungan tanpa emisi karbon'
                                : 'Perjalanan ini menghasilkan emisi karbon yang perlu di-offset',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: ColorPalette.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carbon Offset Info Card (only show if there are emissions)
                    if (trip.emissionKg > 0.0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ColorPalette.third.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ColorPalette.third.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.eco,
                              size: 32,
                              color: ColorPalette.third,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Offset Emisi Karbon Anda',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bantu lingkungan dengan melakukan donasi carbon offset untuk menetralisir emisi dari perjalanan ini.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: ColorPalette.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.eco,
                              size: 32,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Perjalanan Ramah Lingkungan!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Terima kasih telah memilih transportasi yang ramah lingkungan. Anda telah berkontribusi untuk mengurangi emisi karbon!',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: ColorPalette.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),

                    // Action Buttons
                    Column(
                      children: [
                        // Only show donation button if there are emissions to offset
                        if (trip.emissionKg > 0.0) ...[
                        PrimaryButton(
                          text: 'Donasi Carbon Offset',
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Navigations(initialPage: 3),
                              ),
                            );
                          },
                        ),

                          const SizedBox(height: 12),
                        ],
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);

                            // Setelah kembali ke root, navigasikan ke main navigation
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Navigations(initialPage: 2),
                              ),
                            );
                          },
                          child: Text(
                            'Kembali ke Beranda',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: ColorPalette.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Additional Info
                    if (trip.notes != null) ...[
                      CurvedContainer(
                        backgroundColor: Colors.white,
                        curveRadius: 16,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trip.notes!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: ColorPalette.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: ColorPalette.textSecondary,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}