import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_interactive_detail_screen.dart';

class InteriorDetailingScreen extends StatelessWidget {
  const InteriorDetailingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServiceInteractiveDetailScreen(
      service: DetailService(
        id: '1',
        name: 'Interior Detailing',
        description:
            "Your vehicle's interior is where you spend every journey, and it deserves the same level of care as its exterior. Our Interior Detailing is a comprehensive restoration service designed to deep clean, sanitize, and rejuvenate every interior surface while preserving original materials.",
        price: 199.0,
        durationHours: 3.5,
        imageUrl: '',
        category: 'Interior',
        whatsIncluded: [
          'Carpets & Upholstery Deep Steam Cleaning',
          'Leather Conditioning & UV Protection',
          'Dashboard, Vents & Console Sanitization',
          'Door Jambs, Trim & Cup Holder Detailing',
          'Odor Elimination & Air Refreshener',
        ],
        assetImagePath: 'assets/services/interior/interior_detailing.png',
        odooProductId: 4,
      ),
    );
  }
}
