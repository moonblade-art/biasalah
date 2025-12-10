import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/color_palette.dart';
import '../widgets/page_transition.dart';
import '../screens/home/tracking/tracking_screen.dart';
import 'package:flutter/services.dart';

class FuelChooseSheet extends StatefulWidget {
  final String vehicleType;

  const FuelChooseSheet({
    super.key,
    required this.vehicleType,
  });

  @override
  State<FuelChooseSheet> createState() => _FuelChooseSheetState();
}

class _FuelChooseSheetState extends State<FuelChooseSheet> {
  String? selectedFuelType;
  final TextEditingController _ccController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ccController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get fuelTypes {
    switch (widget.vehicleType.toLowerCase()) {
      case 'motor':
      case 'motorcycle':
        return [
          {
            'type': 'gasoline',
            'label': 'Bensin',
            'icon': Icons.local_gas_station,
            'description': 'Bensin biasa (Pertalite, Pertamax)',
          },
          {
            'type': 'electric',
            'label': 'Listrik',
            'icon': Icons.electric_bolt,
            'description': 'Motor listrik (zero emission)',
          },
        ];
      case 'mobil':
      case 'car':
        return [
          {
            'type': 'gasoline',
            'label': 'Bensin',
            'icon': Icons.local_gas_station,
            'description': 'Bensin biasa (Pertalite, Pertamax)',
          },
          {
            'type': 'diesel',
            'label': 'Solar',
            'icon': Icons.oil_barrel,
            'description': 'Solar/Diesel',
          },
          {
            'type': 'hybrid',
            'label': 'Hybrid',
            'icon': Icons.eco,
            'description': 'Bensin + Listrik',
          },
          {
            'type': 'electric',
            'label': 'Listrik',
            'icon': Icons.electric_bolt,
            'description': 'Mobil listrik (zero emission)',
          },
        ];
      default:
        return [
          {
            'type': 'gasoline',
            'label': 'Bensin',
            'icon': Icons.local_gas_station,
            'description': 'Bahan bakar bensin',
          },
          {
            'type': 'diesel',
            'label': 'Solar',
            'icon': Icons.oil_barrel,
            'description': 'Bahan bakar solar/diesel',
          },
        ];
    }
  }

  void _startTracking() {
    if (selectedFuelType == null || !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih bahan bakar dan masukkan CC kendaraan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);
    Navigator.push(
      context,
      PageTransitionWidget.createRoute(
        TrackingScreen(
          vehicleType: widget.vehicleType.toLowerCase() == 'mobil' ? 'car' : widget.vehicleType.toLowerCase(),
          fuelType: selectedFuelType!,
          cc: _ccController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Pilih Jenis Bahan Bakar',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Untuk ${widget.vehicleType}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Fuel options
          Flexible(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Fuel selection
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: fuelTypes.length,
                    itemBuilder: (context, index) {
                      final fuel = fuelTypes[index];
                      final isSelected = selectedFuelType == fuel['type'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedFuelType = fuel['type'];
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected 
                                      ? ColorPalette.primaryColor 
                                      : ColorPalette.primaryColor.withOpacity(0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected 
                                    ? ColorPalette.primaryColor.withOpacity(0.05)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? ColorPalette.primaryColor
                                          : ColorPalette.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      fuel['icon'],
                                      color: isSelected 
                                          ? Colors.white
                                          : ColorPalette.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fuel['label'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected 
                                                ? ColorPalette.primaryColor
                                                : ColorPalette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          fuel['description'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: ColorPalette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: ColorPalette.primaryColor,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // CC Input
                  if (selectedFuelType != null && selectedFuelType != 'electric') ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kapasitas Mesin (CC)',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ccController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: widget.vehicleType.toLowerCase() == 'motor' ? 'Contoh: 150' : 'Contoh: 1500',
                              suffixText: 'CC',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: ColorPalette.primaryColor),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kapasitas mesin harus diisi';
                              }
                              final cc = int.tryParse(value);
                              if (cc == null || cc <= 0) {
                                return 'Kapasitas mesin harus berupa angka positif';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedFuelType != null ? _startTracking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Mulai Tracking GPS',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}