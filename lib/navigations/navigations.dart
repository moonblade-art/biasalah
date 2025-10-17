import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/animation.dart';

import '../screens/home/home_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/home/donation_screen.dart';
import '../screens/home/history/history_vichile_screen.dart';
import '../screens/home/tracking_screen.dart';

import '../utils/color_palette.dart';

class Navigations extends StatefulWidget {
  const Navigations({super.key});

  @override
  State<Navigations> createState() => _NavigationsState();
}

class _NavigationsState extends State<Navigations> {
  int _page = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const TrackingScreen(),
    const HistoryVichileScreen(),
    const DonationScreen(),
    const ProfileScreen(),
  ];

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600), // 🌿 animasi halus & lambat
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: _pages[_page],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 60,
        items: const <Widget>[
          Icon(Icons.home, size: 28, color: Colors.white),
          Icon(Icons.location_on, size: 28, color: Colors.white),
          Icon(Icons.history, size: 28, color: Colors.white),
          Icon(Icons.volunteer_activism, size: 28, color: Colors.white),
          Icon(Icons.person, size: 28, color: Colors.white),
        ],
        color: ColorPalette.primaryColor, // warna utama hijau custom 🌿
        buttonBackgroundColor: ColorPalette.primaryColor,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubicEmphasized,
        animationDuration: const Duration(milliseconds: 700),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
