import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import 'gradient_text.dart';

class CleanRideLogo extends StatelessWidget {
  const CleanRideLogo({
    super.key,
    this.fontSize = 28,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GradientText(
          'CLEAN',
          gradient: AppTheme.primaryGradient,
          style: GoogleFonts.bebasNeue(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          'RIDE',
          style: GoogleFonts.bebasNeue(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
