import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _lastSavedPoints = -1;
  String _userArea = "Maharagama Zone"; // මුලින්ම තියෙන Area එක
  int _currentIndex = 0; // Bottom Nav Bar එකේ දැනට ඉන්න Tab එක

  @override
  void initState() {
    super.initState();
    _loadData(); // App එක ලෝඩ් වෙද්දිම සේව් වෙලා තියෙන Data ගන්නවා
  }

  // Points සහ Area එක ෆෝන් එකෙන් ලෝඩ් කරන Function එක
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSavedPoints = prefs.getInt('last_points') ?? 0;
      _userArea = prefs.getString('user_area') ?? "Maharagama Zone";
    });
  }

  // Points අලුත් කරන Function එක
  Future<void> _updateLastPoints(int newPoints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_points', newPoints);
    _lastSavedPoints = newPoints;
  }

  // Area එක මාරු කරන Function එක
  Future<void> _changeArea(String newArea) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_area', newArea);
    setState(() {
      _userArea = newArea;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Area updated to $newArea!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Area එක තෝරන Dialog එක පෙන්වන Function එක
  void _showChangeAreaDialog() {
    List<String> areas = [
      'Colombo Zone',
      'Maharagama Zone',
      'Homagama Zone',
      'Kaduwela Zone',
      'Dehiwala Zone',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Your Area',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: areas.map((area) {
            return ListTile(
              leading: Icon(
                Icons.location_city,
                color: _userArea == area ? Colors.green : Colors.grey,
              ),
              title: Text(
                area,
                style: TextStyle(
                  fontWeight: _userArea == area
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: _userArea == area
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _changeArea(area);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // +1 Point Popup එක
  void _showRewardPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade700,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.monetization_on,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'REWARD EARNED',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '+1 Point',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Great job! The waste report is approved.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Collect Point >',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimPoint(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {'isRewardClaimed': true},
    );
    if (mounted) _showRewardPopup(context);
  }

  void _showNotificationsSheet(
    BuildContext context,
    List<QueryDocumentSnapshot> unreadNotifications,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (unreadNotifications.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No new notifications',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Rewards 🎁',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: unreadNotifications.length,
                  itemBuilder: (context, index) {
                    var doc = unreadNotifications[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, color: Colors.amber),
                      ),
                      title: const Text(
                        'Report Approved!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Your report at ${data['location'] ?? 'a location'} was assigned.',
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _claimPoint(doc.id);
                        },
                        child: const Text('Claim Point'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Silver':
        return Colors.blueGrey;
      case 'Gold':
        return Colors.amber.shade700;
      case 'Platinum':
        return Colors.deepPurple;
      default:
        return Colors.brown.shade400;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Silver':
        return Icons.workspace_premium;
      case 'Gold':
        return Icons.emoji_events;
      case 'Platinum':
        return Icons.diamond;
      default:
        return Icons.star_border;
    }
  }

  void _showRewardsInfo(BuildContext context, int currentPoints) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Rewards Journey',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You currently have $currentPoints Points',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildRewardCard(
              title: 'Platinum Level',
              points: '1000 Points',
              subtitle: '50% OFF Dinner at Cinnamon Grand Colombo',
              icon: Icons.diamond,
              color: Colors.deepPurple,
              isUnlocked: currentPoints >= 1000,
            ),
            _buildRewardCard(
              title: 'Gold Level',
              points: '500 Points',
              subtitle: 'Priority Report Verification & VIP Status',
              icon: Icons.emoji_events,
              color: Colors.amber.shade700,
              isUnlocked: currentPoints >= 500,
            ),
            _buildRewardCard(
              title: 'Silver Level',
              points: '100 Points',
              subtitle: 'Free Premium Reusable Bag & 10% Eco-Shop Discount',
              icon: Icons.workspace_premium,
              color: Colors.blueGrey,
              isUnlocked: currentPoints >= 100,
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Got it! Keep Reporting',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard({
    required String title,
    required String points,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withOpacity(0.1) : Colors.grey.shade100,
        border: Border.all(
          color: isUnlocked ? color : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? color : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? color : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      points,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (isUnlocked) const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildNextCollectionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_city, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'My Area: $_userArea',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showChangeAreaDialog,
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Garbage Collection',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tomorrow, 08:00 AM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.recycling,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Plastic & Paper',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.green,
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder set for tomorrow morning!'),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================
  // TAB 2: අලුතින් හදපු Profile Settings Tab එක
  // ==============================================
  Widget _buildProfileTab(
    String email,
    int points,
    String level,
    Color levelColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Picture එක
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: levelColor, width: 3),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            email,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$level Member • $points Points',
              style: TextStyle(
                color: levelColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Settings Options ටික
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  title: const Text('My Area'),
                  subtitle: Text(
                    _userArea,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: _showChangeAreaDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: Colors.orange),
                  ),
                  title: const Text('Report History'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () =>
                      setState(() => _currentIndex = 0), // Home එකට යනවා
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reports')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, reportsSnapshot) {
            if (!userSnapshot.hasData || !reportsSnapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            int points = userData['points'] ?? 0;
            String level = userData['level'] ?? 'Bronze';
            Color levelColor = _getLevelColor(level);

            var myReports = reportsSnapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['userId'] == currentUser?.uid;
            }).toList();

            var unreadNotifications = myReports.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Assigned' &&
                  data['isRewardClaimed'] != true;
            }).toList();

            return Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(
                title: const Text(
                  'Smart Waste',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.green,
                elevation: 0,
                actions: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _showNotificationsSheet(
                          context,
                          unreadNotifications,
                        ),
                      ),
                      if (unreadNotifications.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${unreadNotifications.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Bottom Nav Bar එකේ තෝරන Tab එක අනුව පෙන්වන Screen එක වෙනස් වෙනවා
              body: _currentIndex == 0
                  ? Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showRewardsInfo(context, points),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  levelColor,
                                  levelColor.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: levelColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getLevelIcon(level),
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$level Level',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Tap to view rewards 🎁',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'Points',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '$points',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildNextCollectionCard(),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'My Recent Reports',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: myReports.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'You have no reports yet.',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: myReports.length,
                                  itemBuilder: (context, index) {
                                    var report =
                                        myReports[index].data()
                                            as Map<String, dynamic>;
                                    String? base64String =
                                        report['imageBase64'];

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                width: 70,
                                                height: 70,
                                                color: Colors.grey.shade200,
                                                child:
                                                    base64String != null &&
                                                        base64String.isNotEmpty
                                                    ? Image.memory(
                                                        base64Decode(
                                                          base64String,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    report['title'] ??
                                                        'No Title',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          report['location'] ??
                                                              'Unknown',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          report['status'] ==
                                                              'Pending'
                                                          ? Colors
                                                                .orange
                                                                .shade50
                                                          : Colors
                                                                .green
                                                                .shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      report['status'] ??
                                                          'Pending',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            report['status'] ==
                                                                'Pending'
                                                            ? Colors
                                                                  .orange
                                                                  .shade800
                                                            : Colors
                                                                  .green
                                                                  .shade800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    )
                  : _buildProfileTab(
                      currentUser?.email ?? '',
                      points,
                      level,
                      levelColor,
                    ),

              // මැදින් තියෙන ලොකු "New Report" Button එක
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.green,
                elevation: 4,
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              // Bottom Navigation Bar එක
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8.0,
                color: Colors.white,
                elevation: 10,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MaterialButton(
                        minWidth: 40,
                        onPressed: () => setState(() => _currentIndex = 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              color: _currentIndex == 0
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            Text(
                              'Home',
                              style: TextStyle(
                                color: _currentIndex == 0
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 12,
                                fontWeight: _currentIndex == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // මැද බොත්තමට ඉඩ තියනවා
                      MaterialButton(
                        minWidth: 40,
                        onPressed: () => setState(() => _currentIndex = 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              color: _currentIndex == 1
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            Text(
                              'Profile',
                              style: TextStyle(
                                color: _currentIndex == 1
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 12,
                                fontWeight: _currentIndex == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
