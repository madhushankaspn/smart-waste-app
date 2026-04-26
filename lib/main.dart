import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/language_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App එක start වෙද්දිම Save කරපු language එකක් තියෙනවද බලනවා
  final prefs = await SharedPreferences.getInstance();
  final String? savedLanguage = prefs.getString('language');

  runApp(SmartWasteApp(savedLanguage: savedLanguage));
}

class SmartWasteApp extends StatelessWidget {
  final String? savedLanguage;

  const SmartWasteApp({super.key, this.savedLanguage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      // භාෂාවක් Save වෙලා තියෙනවා නම් Login එකට යනවා, නැත්නම් Language Screen එකට යනවා
      home: SplashScreen(
        nextScreen: savedLanguage == null
            ? const LanguageScreen()
            : const LoginScreen(),
      ),
    ); // <-- මෙන්න මෙතන මේ ); කෑල්ල තමයි අඩුවෙලා තිබ්බේ
  }
}
