import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (blood/medical theme)
  static const Color primary = Color(0xFFDC143C); // Crimson red
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFFF6B6B);

  // Accent colors
  static const Color accent = Color(0xFF6366F1); // Indigo
  static const Color accentLight = Color(0xFF818CF8);

  // Status colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Blood group colors
  static const Color bloodAPositive = Color(0xFFEF4444);
  static const Color bloodANegative = Color(0xFFF87171);
  static const Color bloodBPositive = Color(0xFF3B82F6);
  static const Color bloodBNegative = Color(0xFF60A5FA);
  static const Color bloodOPositive = Color(0xFF10B981);
  static const Color bloodONegative = Color(0xFF34D399);
  static const Color bloodABPositive = Color(0xFF8B5CF6);
  static const Color bloodABNegative = Color(0xFFA78BFA);

  // Urgency colors
  static const Color urgencyCritical = Color(0xFFDC2626);
  static const Color urgencyHigh = Color(0xFFF59E0B);
  static const Color urgencyMedium = Color(0xFF3B82F6);

  // Neutral colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // Get blood group color
  static Color getBloodGroupColor(String bloodGroup) {
    switch (bloodGroup) {
      case 'A+':
        return bloodAPositive;
      case 'A-':
        return bloodANegative;
      case 'B+':
        return bloodBPositive;
      case 'B-':
        return bloodBNegative;
      case 'O+':
        return bloodOPositive;
      case 'O-':
        return bloodONegative;
      case 'AB+':
        return bloodABPositive;
      case 'AB-':
        return bloodABNegative;
      default:
        return primary;
    }
  }

  // Get urgency color
  static Color getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return urgencyCritical;
      case 'high':
        return urgencyHigh;
      case 'medium':
        return urgencyMedium;
      default:
        return info;
    }
  }
}
