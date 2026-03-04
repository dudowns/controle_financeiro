import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool hasShadow;
  final bool isRounded;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
    this.height,
    this.hasShadow = true,
    this.isRounded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            isRounded ? BorderRadius.circular(AppSizes.radiusL) : null,
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: color ?? AppColors.cardBackground,
            borderRadius:
                isRounded ? BorderRadius.circular(AppSizes.radiusL) : null,
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, -2),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
