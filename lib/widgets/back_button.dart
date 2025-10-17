import 'package:flutter/material.dart';
import '../widgets/page_transition.dart';

class BackButtonWidget extends StatelessWidget {
  final Widget? previousPage; // halaman tujuan saat kembali
  final Color color;

  const BackButtonWidget({
    super.key,
    this.previousPage,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color),
          onPressed: () {
            if (previousPage != null) {
              // Jika ada halaman tujuan, gunakan animasi balik
              Navigator.of(context).pushReplacement(
                PageTransitionWidget.createRoute(previousPage!),
              );
            } else {
              // Jika tidak ada, lakukan pop biasa
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
