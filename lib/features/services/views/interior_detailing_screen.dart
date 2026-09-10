import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_interactive_detail_screen.dart';

import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';

import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

class InteriorDetailingScreen extends StatefulWidget {
  final DetailService? service;
  const InteriorDetailingScreen({super.key, this.service});

  @override
  State<InteriorDetailingScreen> createState() => _InteriorDetailingScreenState();
}

class _InteriorDetailingScreenState extends State<InteriorDetailingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ServicesController>(context, listen: false);
      final hasInterior = controller.services.any(
        (s) =>
            s.category.toLowerCase().contains('interior') ||
            s.name.toLowerCase().contains('interior') ||
            s.mobileCategoryId == 4,
      );
      if (!hasInterior) {
        controller.loadServices(categoryId: 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.service != null) {
      return ServiceInteractiveDetailScreen(service: widget.service!);
    }

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
