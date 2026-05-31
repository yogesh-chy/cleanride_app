import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 50,
    this.width,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double? width;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDisabled ? null : AppTheme.glowShadow,
      ),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.primaryForegroundColor,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          disabledForegroundColor: AppTheme.primaryForegroundColor.withValues(alpha: 0.5),
          padding: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryForegroundColor),
                ),
              )
            : child,
      ),
    );
  }
}
