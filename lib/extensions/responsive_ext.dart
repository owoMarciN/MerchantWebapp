// -----------------------------------------------------------------------------
// WEBSITE RESPONSIVENESS UTILITIES
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  /// Basic Screen Size Helpers
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile => screenWidth <= 700;
  bool get isWide => screenWidth > 700;
  bool get isUltraWide => screenWidth > 1200;

  /// High-Density Grid (e.g., Analytics Dashboard)
  /// 
  /// Returns:
  /// * > 1600px : **4 Columns**
  /// * > 1200px : **3 Columns**
  /// * > 780px  : **2 Columns**
  /// * Otherwise: **1 Column**
  int get gridCols4 {
    if (screenWidth > 1600) return 4;
    if (screenWidth > 1200) return 3;
    if (screenWidth > 780) return 2;
    return 1;
  }

  /// Standard Content Grid (e.g., Menu Items)
  /// 
  /// Returns:
  /// * > 1200px : **3 Columns**
  /// * > 600px  : **2 Columns**
  /// * Otherwise: **1 Column**
  int get gridCols421 {
    if (screenWidth > 1200) return 4;
    if (screenWidth > 600) return 2;
    return 1;
  }
}