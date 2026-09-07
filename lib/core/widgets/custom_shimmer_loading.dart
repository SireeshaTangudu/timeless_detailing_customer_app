import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// Base Skeleton Block used inside Shimmer layouts
class SkeletonBlock extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shapeBorder;

  const SkeletonBlock({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shapeBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: const Color(0xFFE2DDD5),
        shape: shapeBorder ??
            RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(10),
            ),
      ),
    );
  }
}

/// Standalone Shimmer Container wrapper
class CustomShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shapeBorder;

  const CustomShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shapeBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(milliseconds: 1200),
      interval: const Duration(milliseconds: 0),
      color: Colors.white,
      colorOpacity: 0.75,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: SkeletonBlock(
        width: width,
        height: height,
        borderRadius: borderRadius,
        shapeBorder: shapeBorder,
      ),
    );
  }
}

/// Shimmer Skeleton Loader for Card Components (Single Card Shimmer Wave)
class ShimmerCardLoader extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const ShimmerCardLoader({
    super.key,
    this.height = 145.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Shimmer(
        duration: const Duration(milliseconds: 1200),
        interval: const Duration(milliseconds: 0),
        color: Colors.white,
        colorOpacity: 0.8,
        enabled: true,
        direction: const ShimmerDirection.fromLTRB(),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EFEA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DFD5)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBlock(width: 140, height: 18),
                  SkeletonBlock(width: 75, height: 22),
                ],
              ),
              SkeletonBlock(width: 220, height: 14),
              Row(
                children: [
                  SkeletonBlock(
                    width: 36,
                    height: 36,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 110, height: 14),
                      SizedBox(height: 6),
                      SkeletonBlock(width: 80, height: 12),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer Skeleton Loader for List Views (e.g. Bookings / Invoices)
class ShimmerListLoader extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const ShimmerListLoader({
    super.key,
    this.itemCount = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) => const ShimmerCardLoader(padding: EdgeInsets.zero),
    );
  }
}

/// Shimmer Skeleton Loader for Detail Screens
class ShimmerDetailLoader extends StatelessWidget {
  const ShimmerDetailLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Shimmer(
        duration: const Duration(milliseconds: 1200),
        interval: const Duration(milliseconds: 0),
        color: Colors.white,
        colorOpacity: 0.8,
        enabled: true,
        direction: const ShimmerDirection.fromLTRB(),
        child: Column(
          children: [
            Container(
              height: 220,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EFEA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5DFD5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBlock(width: 160, height: 22),
                  SkeletonBlock(width: 120, height: 36),
                  Divider(color: Color(0xFFE5DFD5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBlock(width: 100, height: 14),
                      SkeletonBlock(width: 120, height: 14),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBlock(width: 90, height: 14),
                      SkeletonBlock(width: 110, height: 14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EFEA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5DFD5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBlock(width: 140, height: 18),
                  SkeletonBlock(width: double.infinity, height: 14),
                  SkeletonBlock(width: 200, height: 14),
                  SkeletonBlock(width: 160, height: 14),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SkeletonBlock(width: double.infinity, height: 48),
          ],
        ),
      ),
    );
  }
}
