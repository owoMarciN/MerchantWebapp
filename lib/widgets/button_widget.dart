import 'package:flutter/material.dart';

class TextButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;
  final Color? backgroundColor;
  final double fontSize;
  final double borderRadius;
  final String? fontFamily;

  const TextButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.lightBlue,
    this.fontSize = 14.0,
    this.borderRadius = 12.0,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor, // Background color
        foregroundColor: textColor ?? Theme.of(context).primaryColor, // Splash/text color
        
        // Shadow/Elevation
        elevation: 4, 
        
        // Rounding and Border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: textColor ?? Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        
        // Padding
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}