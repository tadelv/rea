import 'package:flutter/material.dart';


class ThemeColors {
  const ThemeColors();
  static const Map<String, Color> statesColors = {
    "flush": Color.fromARGB(100, 83, 43, 50),
    "pre_infuse": Color.fromARGB(100, 29, 81, 50),
    "pour": Color.fromARGB(100, 48, 138, 50),
    "heat_water_heater": Color.fromARGB(100, 198, 23, 40),
  };

  static const Color pressureColor =
      Color.fromARGB(255, 166, 250, 29); //Color(0xFFFFFFFF);
  static const Color tempColor = Color.fromARGB(255, 250, 45, 45);
  static const Color tempColor2 = Color.fromARGB(255, 255, 153, 0);
  static const Color flowColor = Color.fromARGB(255, 58, 157, 244);
  static const Color weightColor = Color.fromARGB(255, 131, 109, 105);
}
