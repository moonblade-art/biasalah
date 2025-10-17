import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/home/home_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/home/donation_screen.dart';
import '../screens/home/history/history_vichile_screen.dart';
import '../screens/home/tracking_screen.dart';


class Navigations extends StatelessWidget { 
  const Navigations({super.key}); 
  @override Widget build(BuildContext context) {
     return Scaffold( 
      body: Center( child: Text("Halaman Home"), ), ); } }