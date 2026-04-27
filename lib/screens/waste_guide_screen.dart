import 'package:flutter/material.dart';

class WasteGuideScreen extends StatelessWidget {
  const WasteGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Waste Sorting Guide',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3D1F), Color(0xFF1DD15D)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.recycling, color: Colors.white, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Why Sort Waste?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Proper waste sorting helps to recycle materials efficiently, reduce landfill waste, and protect our beautiful environment.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How to sort your waste',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildGuideCard(
              title: 'Plastics (Yellow Bin)',
              description:
                  'Clean plastic bottles, containers, and bags. Make sure to crush bottles to save space.',
              icon: Icons.local_drink,
              color: Colors.amber,
            ),
            _buildGuideCard(
              title: 'Paper & Cardboard (Blue Bin)',
              description:
                  'Newspapers, magazines, and flattened cardboard boxes. Keep them dry!',
              icon: Icons.description,
              color: Colors.blue,
            ),
            _buildGuideCard(
              title: 'Glass (Red Bin)',
              description:
                  'Glass bottles and jars. Please rinse them first. Do not put broken mirrors or bulbs here.',
              icon: Icons.wine_bar,
              color: Colors.redAccent,
            ),
            _buildGuideCard(
              title: 'Organic (Green Bin)',
              description:
                  'Food scraps, fruit peels, and garden waste. Perfect for making compost!',
              icon: Icons.eco,
              color: Colors.green,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
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
