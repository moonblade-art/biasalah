import 'package:flutter/foundation.dart';

class PaymentConfig {
  // Environment configuration
  static const bool isProduction = kReleaseMode; // Automatically true for release builds
  static bool get isDevelopment => !isProduction;

  static const String sandboxUrl = 'https://app.sandbox.midtrans.com';
  static const String productionUrl = 'https://app.midtrans.com';
  
  // Get current environment URL
  static String get midtransUrl => isDevelopment ? sandboxUrl : productionUrl;
  
  // Payment settings
  static const int paymentExpiryHours = 24;
  static const double minimumDonation = 1000.0;
  static const double maximumDonation = 10000000.0;
  
  // Callback URLs
  static const String successCallback = 'ecotrack://donation/success';
  static const String failureCallback = 'ecotrack://donation/failure';
  static const String pendingCallback = 'ecotrack://donation/pending';
}