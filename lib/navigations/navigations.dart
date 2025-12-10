import 'package:emission_tracker/screens/home/tracking/vechicle_choose_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/home/home_screen.dart';
import '../screens/home/profile/profile_screen.dart';
import '../screens/home/donation/donation_screen.dart';
import '../screens/home/history/history_screen.dart';

import '../models/community_model.dart';
import '../utils/color_palette.dart';

class Navigations extends StatefulWidget {
  final int initialPage;
  final Community? community;

  Navigations({
    super.key,
    this.initialPage = 2,
    this.community,
  });

  @override
  State<Navigations> createState() => _NavigationsState();
}

class _NavigationsState extends State<Navigations> {
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage; // <-- pakai nilai yang dikirim dari luar
  }

  final List<Widget> _pages = [
    VehicleChooseScreen(),
    HistoryScreen(),
    HomeScreen(),
    DonationScreen(),
    ProfileScreen(),
  ];

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,

      body: Builder(
        builder: (context) {
          try {
            return IndexedStack(
              index: _page,
              children: _pages,
            );
          } catch (e) {
            return Container(
              color: ColorPalette.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 20),
                    Text(
                      'Terjadi kesalahan rendering',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _page = 2;
                        });
                      },
                      child: const Text('Kembali ke Home'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 65,
        items: <Widget>[
          Icon(Icons.location_on, size: 30, color: Colors.white),
          Icon(Icons.history, size: 30, color: Colors.white),
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.volunteer_activism, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: ColorPalette.primaryColor,
        buttonBackgroundColor: ColorPalette.primaryColor,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubicEmphasized,
        animationDuration: const Duration(milliseconds: 700),
        onTap: (index) {
          if (mounted) {
            setState(() {
              _page = index;
            });
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
