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
  String? selectedSize;

  late final List<String> fuels;
  late final List<String> ccOptions;
  late final List<String> sizeOptions;

  String get vehicleType => widget.vehicleType.toLowerCase();

  bool get shouldShowEngineOrSize {
    if (vehicleType == 'sepeda') return false;
    if (vehicleType == 'angkutan') return true;
    return true;
  }

  bool get isInputComplete {
    if (selectedFuel == null) return false;
    if (vehicleType == 'sepeda') return true;
    if (vehicleType == 'angkutan') return selectedSize != null;
    return selectedCC != null;
  }

  @override
  void initState() {
    super.initState();

    if (vehicleType == 'sepeda') {
      fuels = ['Listrik'];
      ccOptions = [];
      sizeOptions = [];
    } else if (vehicleType == 'angkutan') {
      fuels = ['Solar', 'Listrik'];
      ccOptions = [];
      sizeOptions = ['Kecil', 'Sedang', 'Besar'];
    } else if (vehicleType == 'motor') {
      fuels = ['Pertalite', 'Pertamax', 'Listrik'];
      ccOptions = ['110', '125', '150', '250'];
      sizeOptions = [];
    } else if (vehicleType == 'mobil') {
      fuels = ['Pertalite', 'Pertamax', 'Solar', 'Listrik'];
      ccOptions = ['1000', '1500', '2000', '2500', '3000'];
      sizeOptions = [];
    } else if (vehicleType == 'truk') {
      fuels = ['Solar'];
      ccOptions = ['2500', '3000', '4000', '6000'];
      sizeOptions = [];
    } else {
      fuels = ['Pertalite', 'Pertamax'];
      ccOptions = ['125', '150'];
      sizeOptions = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: _calculateInitialSize(),
            minChildSize: 0.25,
            maxChildSize: 0.85,
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
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 15),
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

                      Text(
                        "Pilih Jenis Bahan Bakar",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: fuels.map((fuel) {
                          final bool isSelected = selectedFuel == fuel;
                          return SizedBox(
                            width: 105,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? ColorPalette.primaryColor
                                    : Colors.grey[200],
                                elevation: isSelected ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? ColorPalette.primaryColor
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedFuel = fuel;
                                  if (vehicleType != 'angkutan') {
                                    selectedCC = null;
                                  } else {
                                    selectedSize = null;
                                  }
                                });
                              },
                              child: Text(
                                fuel,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (shouldShowEngineOrSize) ...[
                        const SizedBox(height: 24),
                        Text(
                          vehicleType == 'angkutan'
                              ? "Ukuran Kendaraan"
                              : "Kapasitas Mesin (cc)",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: (vehicleType == 'angkutan' ? sizeOptions : ccOptions).map((option) {
                            final bool isSelected = vehicleType == 'angkutan'
                                ? selectedSize == option
                                : selectedCC == option;
                            return SizedBox(
                              width: 105,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? ColorPalette.primaryColor
                                      : Colors.grey[200],
                                  elevation: isSelected ? 2 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? ColorPalette.primaryColor
                                          : Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (vehicleType == 'angkutan') {
                                      selectedSize = option;
                                    } else {
                                      selectedCC = option;
                                    }
                                  });
                                },
                                child: Text(
                                  vehicleType == 'angkutan' ? option : "$option cc",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 30),

                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInputComplete
                                ? ColorPalette.primaryColor
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 14,
                            ),
                          ),
                          onPressed: isInputComplete
                              ? () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    PageTransitionWidget.createRoute(
                                      TrackingScreen(
                                        vehicleType: widget.vehicleType,
                                        fuelType: selectedFuel!,
                                        cc: selectedCC,
                                        size: selectedSize,
                                      ),
                                    ),
                                  );
                                }
                              : null,
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

  double _calculateInitialSize() {
    if (vehicleType == 'sepeda') return 0.4;
    if (vehicleType == 'truk') return 0.45;
    if (vehicleType == 'angkutan') return 0.5;
    return 0.55;
  }
}