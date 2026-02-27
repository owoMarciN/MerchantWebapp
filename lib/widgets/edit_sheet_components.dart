import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';

InputDecoration customInputDecoration({
  required String label, 
  required ColorScheme colorScheme, 
  required BrandColors brandColors, 
  String? hint,
  String? prefixText,
  String? errorText}
  ) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    prefixText: prefixText,
    filled: true,
    fillColor: colorScheme.surfaceBright,
    labelStyle: const TextStyle(color: Colors.white70),
    floatingLabelStyle: const TextStyle(color: Colors.white),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colorScheme.surfaceBright),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}


Widget customImagePlaceholder(BrandColors brandColors) {
  return Container(
    color: brandColors.navy?.withValues(alpha: 0.05),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: brandColors.muted),
          const SizedBox(height: 8),
          Text('Tap to upload image', style: TextStyle(fontSize: 12, color: brandColors.muted)),
        ],
      ),
    ),
  );
}

Widget imagePlaceholder(BrandColors brandColors) {
    return Container(
      color: brandColors.navy?.withValues(alpha: 0.05),
      child: Center(
        child: Icon(Icons.fastfood_rounded, size: 40, color: brandColors.muted),
      ),
    );
  }
