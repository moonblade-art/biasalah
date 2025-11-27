import 'package:emission_tracker/screens/home/tracking/vechicle_choose_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/animation.dart';
import 'package:animations/animations.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/profile/profile_screen.dart';
import '../screens/home/donation/donation_screen.dart';
import '../screens/home/history/history_screen.dart';
import '../screens/home/tracking/tracking_screen.dart';

import '../utils/color_palette.dart';

class Navigations extends StatefulWidget {
  const Navigations({super.key});

  @override
  State<Navigations> createState() => _NavigationsState();
}

class _NavigationsState extends State<Navigations> {
  int _page = 2; // 🌿 mulai dari Home

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
      // 🌿 Gunakan PageTransitionSwitcher agar animasi antar halaman lebih smooth dan konsisten
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal, // 🔁 animasi geser kanan–kiri
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_page), // 🧩 kunci unik agar animasi antar halaman stabil
          child: _pages[_page],
        ),
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
          setState(() {
            _page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
