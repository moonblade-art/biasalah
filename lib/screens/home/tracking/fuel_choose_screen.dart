import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utils/color_palette.dart';
import '/widgets/page_transition.dart';
import 'tracking_screen.dart';

class FuelChooseSheet extends StatefulWidget {
  final String vehicleType;
  const FuelChooseSheet({super.key, required this.vehicleType});

  @override
  State<FuelChooseSheet> createState() => _FuelChooseSheetState();
}

class _FuelChooseSheetState extends State<FuelChooseSheet> {
  String? selectedFuel;
  String? selectedCC;

  late final List<String> fuels;
  late final List<String> ccOptions;

  @override
  void initState() {
    super.initState();

    // 🔹 Tentukan pilihan berdasarkan jenis kendaraan
    switch (widget.vehicleType.toLowerCase()) {
      case 'motor':
        fuels = ['Pertalite', 'Pertamax', 'Listrik'];
        ccOptions = ['110', '125', '150', '250'];
        break;
      case 'mobil':
        fuels = ['Pertalite', 'Pertamax', 'Solar', 'Listrik'];
        ccOptions = ['1000', '1500', '2000', '2500', '3000'];
        break;
      case 'truk':
        fuels = ['Solar'];
        ccOptions = ['2500', '3000', '4000', '6000'];
        break;
      default:
        fuels = ['Pertalite', 'Pertamax'];
        ccOptions = ['125', '150'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // klik luar sheet = tutup
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {}, // cegah sheet tertutup pas klik isi
          child: DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Handle Bar ---
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      Text(
                        "Detail ${widget.vehicleType}",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- Fuel Selection ---
                      Text(
                        "Pilih Jenis Bahan Bakar",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: fuels.map((fuel) {
                          final bool isSelected = selectedFuel == fuel;
                          return SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? ColorPalette.primaryColor
                                    : Colors.grey[200],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? ColorPalette.primaryColor
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                setState(() => selectedFuel = fuel);
                              },
                              child: Text(
                                fuel,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // --- CC Selection ---
                      Text(
                        "Kapasitas Mesin (cc)",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ccOptions.map((cc) {
                          final bool isSelected = selectedCC == cc;
                          return SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? ColorPalette.primaryColor
                                    : Colors.grey[200],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? ColorPalette.primaryColor
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                setState(() => selectedCC = cc);
                              },
                              child: Text(
                                "$cc cc",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      // --- Start Journey Button ---
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedFuel == null ||
                                    selectedCC == null)
                                ? Colors.grey
                                : ColorPalette.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 14,
                            ),
                          ),
                          onPressed: (selectedFuel == null || selectedCC == null)
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    PageTransitionWidget.createRoute(
                                      const TrackingScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            "Mulai Perjalanan",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
