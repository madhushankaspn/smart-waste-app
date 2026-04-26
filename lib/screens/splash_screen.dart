import 'package:flutter/material.dart';
import 'dart:async';
import 'language_screen.dart'; // ඔයාගේ Language Screen එකේ ෆයිල් නම

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // තත්පර 3 කින් ඉබේම Language Screen එකට යනවා
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LanguageScreen()), // ඔයාගේ language page එකේ class නම
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ෆොටෝ එකේ තියෙන ලස්සන ළා කොළ පාට
      backgroundColor: const Color(0xFF1DD15D), 
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // සුදු පාට Logo Box එක
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded, // ෆොටෝ එකට සමාන Icon එක
                    size: 70,
                    color: Color(0xFF1DD15D),
                  ),
                ),
                const SizedBox(height: 30),
                
                // App නම
                const Text(
                  'Smart Waste',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Tagline එක
                Text(
                  'Clean Cities. Smart Future.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // යටින් තියෙන ECO-SYSTEM READY කොටස
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'ECO-SYSTEM READY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}