import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_interactive_detail_screen.dart';

class InteriorDetailingScreen extends StatelessWidget {
  const InteriorDetailingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ServicesController>(context);
    final realService = controller.services.firstWhere(
      (s) =>
          s.category.toLowerCase().contains('interior') ||
          s.name.toLowerCase().contains('interior') ||
          s.mobileCategoryId == 4,
      orElse: () => const DetailService(
        id: '3',
        name: 'Interior Detail',
        description:
            "Your vehicle's interior is where you spend every journey, and it deserves the same level of care as its exterior. Our Interior Detail is a comprehensive restoration service designed to deep clean, sanitize, and rejuvenate every interior surface while preserving original materials.",
        price: 2800.0,
        durationHours: 3.5,
        imageUrl: '',
        category: 'Interior',
        whatsIncluded: [],
        odooProductId: 3,
      ),
    );

    return ServiceInteractiveDetailScreen(service: realService);
  }
}
