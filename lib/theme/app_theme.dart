import 'package:flutter/material.dart';

class AppTheme {
  // WhatsApp Colors
  static const Color tealGreen = Color(0xFF128C7E);
  static const Color tealGreenDark = Color(0xFF075E54);
  static const Color lightGreen = Color(0xFF25D366);
  static const Color blueTick = Color(0xFF34B7F1);

  static const Color backgroundLight = Color(0xFFECE5DD);
  static const Color chatBackgroundLight = Color(0xFFE5DDD5);
  static const Color outgoingChatLight = Color(0xFFE2FFC7);
  static const Color incomingChatLight = Colors.white;

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF121B22); // Main background
  static const Color appBarDark = Color(0xFF1F2C34); // Appbar background
  static const Color chatBackgroundDark = Color(0xFF0B141A);
  static const Color outgoingChatDark = Color(0xFF005C4B);
  static const Color incomingChatDark = Color(0xFF202C33);
  static const Color searchBarDark = Color(0xFF202C33);

  // Common Text Colors
  static const Color textPrimaryLight = Colors.black87;
  static const Color textSecondaryLight = Colors.black54;

  static const Color textPrimaryDark = Color(0xFFE9EDEF);
  static const Color textSecondaryDark = Color(0xFF8696A0);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: tealGreen,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: tealGreen,
        secondary: lightGreen,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: tealGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: appBarDark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: tealGreen,
        secondary: lightGreen,
        surface: appBarDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarDark,
        elevation: 0,
        iconTheme: IconThemeData(color: textSecondaryDark),
        titleTextStyle: TextStyle(
            color: textSecondaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w600),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: tealGreen,
        unselectedLabelColor: textSecondaryDark,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: tealGreen, width: 2.0),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: appBarDark,
        selectedItemColor: Colors.white,
        unselectedItemColor: textSecondaryDark,
      ),
    );
  }

  // We are keeping this for now just to not break existing screens until we refactor them
  static BoxDecoration get auroraGradient {
    return BoxDecoration(
      color: backgroundDark,
    );
  }
}
