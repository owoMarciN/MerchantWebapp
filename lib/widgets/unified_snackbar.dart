import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';

void unifiedSnackBar(BuildContext context, String msg, {bool error = false}) {
  final brandColors = Theme.of(context).extension<BrandColors>();
  final colorScheme = Theme.of(context).colorScheme;

  final Color bgColor = error
      ? Colors.redAccent.shade700
      : (brandColors?.navy ?? colorScheme.primary);

  final IconData icon =
      error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

  ScaffoldMessenger.of(context)
      .clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: Duration(seconds: error ? 4 : 2),
      dismissDirection: DismissDirection.horizontal,
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white.withValues(alpha: 0.7),
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
