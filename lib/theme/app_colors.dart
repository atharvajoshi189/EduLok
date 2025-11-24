import 'package:flutter/material.dart';

class AppColors {
  // Primary Color: Indigo (Dark Blue)
  static const Color indigo = Color(0xFF3F51B5); // Material Indigo 500
  static const Color indigo_light = Color(0xFF5C6BC0); // Lighter shade (for gradients)
  static const Color indigo_dark = Color(0xFF303F9F); // Darker shade (for accents)

  // Secondary/Accent Color: Teal
  static const Color teal = Color(0xFF009688); // Material Teal 500
  static const Color teal_light = Color(0xFF4DB6AC); // Lighter shade (for gradients)
  static const Color teal_dark = Color(0xFF00796B); // Darker shade (for buttons)

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA); // Light Greyish background
  static const Color text_dark = Color(0xFF212529);

  static Color? get card_background => null;
}