import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centralized animation utilities for Timeless Detailing customer app.
class AppAnimations {
  /// Default animation duration for micro-interactions
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 400);
  static const Duration slowDuration = Duration(milliseconds: 600);

  /// Default curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.elasticOut;
}

/// A wrapper widget that gives tactile scale feedback on tap down / up.
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;
  final Alignment alignment;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 140),
    this.alignment = Alignment.center,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        alignment: widget.alignment,
        child: widget.child,
      ),
    );
  }
}

/// Entrance animation widget that fades and slides content into view.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.slideOffset = const Offset(0.0, 0.1),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .slide(
          begin: slideOffset,
          end: Offset.zero,
          duration: duration,
          curve: curve,
        );
  }
}

/// Custom Page Route Builder providing luxury fade and subtle slide transitions.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.04, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Repeating ambient pulse animation for active badges or indicators.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseGlow({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.minScale = 0.96,
    this.maxScale = 1.04,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
