import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/utils/color_palette.dart';
import '../../../services/tracking_service.dart';
import '../../../models/trip_tracking_model.dart';
import 'history_vehicle_screen.dart'; // This is TripDetailScreen

import 'history_offset_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<TripTracking>> _tripsFuture;
  final TrackingService _trackingService = TrackingService();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshTrips();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose();
  }

  void _refreshTrips() {
    if (!_isDisposed && mounted) {
      setState(() {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          _tripsFuture = _trackingService.getUserTrips(userId: user.id);
        } else {
          _tripsFuture = Future.value([]);
        }
      });
    }
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return "${h}j ${m}m";
    return "$m menit";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "Belum ada riwayat perjalanan",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            "Mulai perjalanan untuk melihat riwayat di sini",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value, bool isEmission = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isEmission && (double.tryParse(value.split(' ')[0]) ?? 0) == 0
                ? Colors.green
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // CUSTOM HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 18),
              decoration: const BoxDecoration(
                color: ColorPalette.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Riwayat",
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),

            // TAB BAR
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: ColorPalette.primaryColor,
                labelColor: ColorPalette.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: "Perjalanan"),
                  Tab(text: "Offset Karbon"),
                ],
              ),
            ),

            // KONTEN TAB
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Riwayat Perjalanan
                  FutureBuilder<List<TripTracking>>(
                    future: _tripsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: ColorPalette.primaryColor));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      final trips = snapshot.data ?? [];
                      final isEmpty = trips.isEmpty;
                      return RefreshIndicator(
                        onRefresh: () async => _refreshTrips(),
                        child: isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),

                                itemCount: trips.length,
                                itemBuilder: (context, index) {
                                  final trip = trips[index];
                                  final title = trip.title ?? 'Perjalanan ${DateFormat('dd MMM').format(trip.tripDate)}';
                                  final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(trip.tripDate);
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TripDetailScreen(trip: trip),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            formattedDate,
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildStatItem(
                                                label: "Jarak",
                                                value: trip.formattedDistance,
                                              ),
                                              _buildStatItem(
                                                label: "Waktu",
                                                value: _formatDuration(trip.tripDurationMinutes),
                                              ),
                                              _buildStatItem(
                                                label: "Emisi",
                                                value: trip.formattedEmission,
                                                isEmission: true,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      );
                    },
                  ),

                  // Tab 2: Riwayat Offset Karbon
                  const HistoryOffsetScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}