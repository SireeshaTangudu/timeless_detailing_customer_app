import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';

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
    Widget loader;
    if (color != null) {
      loader = LoadingAnimationWidget.fourRotatingDots(
        color: color!,
        size: size,
      );
    } else {
      loader = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppTheme.primary, Color(0xFFE5B86B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: LoadingAnimationWidget.fourRotatingDots(
          color: Colors.white,
          size: size,
        ),
      );
    }

    if (showDisk) {
      loader = Container(
        width: size * 2.2,
        height: size * 2.2,
        decoration: BoxDecoration(
          color: const Color(0xFF1D1813).withValues(alpha: 0.88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: loader),
      );
    }

    return Container(
      color: Colors.transparent,
      child: useCenter ? Center(child: loader) : loader,
    );
  }
}

typedef FourRotatingDotsLoader = ChakraLoadingIndicator;

/// Full page loading overlay matching Figma design with full-screen transparent dark backdrop & centered circular disk
class FullPageLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const FullPageLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: ChakraLoadingIndicator(
                    size: 38,
                    showDisk: true,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
