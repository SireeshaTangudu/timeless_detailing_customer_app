import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_shimmer_loading.dart';

class ChakraLoadingIndicator extends StatelessWidget {
  const ChakraLoadingIndicator({
    super.key,
    this.size = 36,
    this.color,
    this.useCenter = true,
    this.showDisk = false,
  });

  final double size;
  final Color? color;
  final bool useCenter;
  final bool showDisk;

  @override
  Widget build(BuildContext context) {
    return const CustomShimmerContainer(
      width: 120,
      height: 24,
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
  }
}

typedef FourRotatingDotsLoader = ChakraLoadingIndicator;

/// Page loading container rendering inline Shimmer skeleton instead of dark backdrop overlay
class FullPageLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Widget? shimmerReplacement;

  const FullPageLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.shimmerReplacement,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return shimmerReplacement ?? const ShimmerListLoader();
    }
    return child;
  }
}
