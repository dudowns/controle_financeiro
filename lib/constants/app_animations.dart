import 'package:flutter/material.dart';

class AppAnimations {
  // Animações de entrada
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: duration,
      child: child,
    );
  }

  static Widget slideInFromBottom({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
    );
  }

  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: duration,
      curve: Curves.elasticOut,
      child: child,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }
}
