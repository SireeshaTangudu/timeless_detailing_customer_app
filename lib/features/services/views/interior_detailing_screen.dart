import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_interactive_detail_screen.dart';

import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';

class InteriorDetailingScreen extends StatelessWidget {
  const InteriorDetailingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ServicesController>(context);
    final matches = controller.services.where(
      (s) =>
          s.category.toLowerCase().contains('interior') ||
          s.name.toLowerCase().contains('interior') ||
          s.mobileCategoryId == 4,
    );

    if (matches.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: FourRotatingDotsLoader(),
      );
    }

    return ServiceInteractiveDetailScreen(service: matches.first);
  }
}
