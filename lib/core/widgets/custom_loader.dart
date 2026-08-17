import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChakraLoadingIndicator extends StatelessWidget {
  const ChakraLoadingIndicator({
    super.key,
    this.size = 36,
    this.color,
    this.useCenter = true,
  });

  final double size;
  final Color? color;
  final bool useCenter;

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
          colors: [Color(0xFFED5A00), Color(0xFFFFD180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: LoadingAnimationWidget.fourRotatingDots(
          color: Colors.white,
          size: size,
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: useCenter ? Center(child: loader) : loader,
    );
  }
}

typedef FourRotatingDotsLoader = ChakraLoadingIndicator;
