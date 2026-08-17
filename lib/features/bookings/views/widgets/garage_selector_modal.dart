import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/map_launcher_util.dart';
import '../../models/garage_location_model.dart';

class GarageSelectorModal extends StatelessWidget {
  final List<GarageLocation> garages;
  final GarageLocation? selectedGarage;
  final Function(GarageLocation)? onGarageSelected;

  const GarageSelectorModal({
    super.key,
    required this.garages,
    this.selectedGarage,
    this.onGarageSelected,
  });

  static Future<GarageLocation?> show(
    BuildContext context, {
    List<GarageLocation>? garages,
    GarageLocation? selectedGarage,
    Function(GarageLocation)? onGarageSelected,
  }) {
    final list = garages ?? GarageLocation.defaultGarages;

    return showModalBottomSheet<GarageLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GarageSelectorModal(
          garages: list,
          selectedGarage: selectedGarage,
          onGarageSelected: onGarageSelected,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1D1813), // Dark luxury theme matching Figma bottom sheet
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF5A4D3E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Garage Branch',
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFAF5ED),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose a workshop location for directions or booking',
                    style: GoogleFonts.montserrat(
                      fontSize: 11.5,
                      color: const Color(0xFFC5B7A1),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFC5B7A1), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // List of Garages
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: garages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final garage = garages[index];
                final isSelected = selectedGarage?.id == garage.id;

                return GestureDetector(
                  onTap: () {
                    if (onGarageSelected != null) {
                      onGarageSelected!(garage);
                    }
                    MapLauncherUtil.openGoogleMapsDirections(garage);
                    Navigator.pop(context, garage);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E261F)
                          : const Color(0xFF26201A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFC4913F)
                            : const Color(0xFF3E3328),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Gold Icon Badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1813),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFC4913F).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFC4913F),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Branch Name & Address
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      garage.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFAF5ED),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (garage.isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC4913F)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'MAIN',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFC4913F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                garage.address,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11.5,
                                  color: const Color(0xFFC5B7A1),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                garage.phone,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: const Color(0xFF8C8273),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Direct Action Button: Get Directions to this specific branch!
                        OutlinedButton.icon(
                          onPressed: () {
                            MapLauncherUtil.openGoogleMapsDirections(garage);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            side: const BorderSide(
                              color: Color(0xFFC4913F),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            foregroundColor: const Color(0xFFC4913F),
                          ),
                          icon: const Icon(
                            Icons.directions_outlined,
                            size: 14,
                            color: Color(0xFFC4913F),
                          ),
                          label: Text(
                            'MAP',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC4913F),
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

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
