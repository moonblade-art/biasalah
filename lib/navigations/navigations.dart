import 'package:emission_tracker/screens/home/tracking/vechicle_choose_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/home/home_screen.dart';
import '../screens/home/profile/profile_screen.dart';
import '../screens/home/donation/donation_screen.dart';
import '../screens/home/history/history_screen.dart';


import '../utils/color_palette.dart';

class Navigations extends StatefulWidget {
  const Navigations({super.key});

  @override
  State<Navigations> createState() => _NavigationsState();
}

class _NavigationsState extends State<Navigations> {
  int _page = 2; // 🌿 mulai dari Home

  final List<Widget> _pages = [
    const VehicleChooseScreen(),
    const HistoryScreen(),
    const HomeScreen(),
    const DonationScreen(),
    const ProfileScreen(),
  ];

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      // Simplified body without complex animations to prevent mouse tracker issues
      body: Builder(
        builder: (context) {
          try {
            return IndexedStack(
              index: _page,
              children: _pages,
            );
          } catch (e) {
            // Fallback in case of rendering errors
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
                          _page = 2; // Reset to home
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
        items: const <Widget>[
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
