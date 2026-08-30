import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); // AdMob başlatma (şimdilik test reklamları)
  runApp(const KelimeHafizaApp());
}

class KelimeHafizaApp extends StatelessWidget {
  const KelimeHafizaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF5C518); // sarı post-it tonu, kaynak görsellerle uyumlu
    const darkBg = Color(0xFF1A1A1A);

    return MaterialApp(
      title: 'Kelime Hafıza',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF7F0),
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
