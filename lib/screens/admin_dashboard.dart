import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedFilter = 'All'; // All, Pending, Assigned තෝරන්න

  // Team එක Assign කරලා Point එක දෙන Function එක
  Future<void> _assignTeam(
    BuildContext context,
    String reportId,
    String reportUserId,
    String teamName,
  ) async {
    try {
      // 1. Report එක Update කරනවා (Team එකත් එක්කම)
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': 'Assigned', 'assignedTeam': teamName});

      // 2. Report එක දැම්ම User ට Point එක දෙනවා
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reportUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        int currentPoints = data['points'] ?? 0;
        int newPoints = currentPoints + 1;
        String newLevel = 'Bronze';

        if (newPoints >= 1000) {
          newLevel = 'Platinum';
        } else if (newPoints >= 500) {
          newLevel = 'Gold';
        } else if (newPoints >= 100) {
          newLevel = 'Silver';
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(reportUserId)
            .update({'points': newPoints, 'level': newLevel});
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team Assigned & Point Awarded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Team තෝරන Popup (Dialog) එක පෙන්වන Function එක
  void _showAssignDialog(
    BuildContext context,
    String reportId,
    String reportUserId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Assign Collection Team',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                'Team Alpha (Truck 1)',
                'Team Beta (Truck 2)',
                'Team Gamma (Truck 3)',
              ].map((team) {
                return ListTile(
                  leading: const Icon(
                    Icons.local_shipping,
                    color: Colors.green,
                  ),
                  title: Text(team),
                  onTap: () {
                    Navigator.pop(context); // Dialog එක වහනවා
                    _assignTeam(
                      context,
                      reportId,
                      reportUserId,
                      team,
                    ); // Team එක Assign කරනවා
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Report Management',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Filters ටික (All, Pending, Assigned) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: ['All', 'Pending', 'Assigned'].map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // --- Reports List එක ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(
                    child: Text(
                      'No reports found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );

                // User තෝරපු Filter එකට අනුව Data වෙන් කරනවා
                var reports = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (_selectedFilter == 'All') return true;
                  return data['status'] == _selectedFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    var document = reports[index];
                    var report = document.data() as Map<String, dynamic>;
                    String status = report['status'] ?? 'Pending';
                    String assignedTeam = report['assignedTeam'] ?? '';
                    String? base64String = report['imageBase64'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey.shade200,
                                    child:
                                        base64String != null &&
                                            base64String.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(base64String),
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.image,
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
                                        report['title'] ?? 'Report',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
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
                                              report['location'] ?? 'Unknown',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 'Pending'
                                              ? Colors.orange.shade50
                                              : Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          status == 'Assigned'
                                              ? 'Assigned: $assignedTeam'
                                              : status,
                                          style: TextStyle(
                                            color: status == 'Pending'
                                                ? Colors.orange.shade800
                                                : Colors.green.shade800,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Button එක
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'Pending'
                                      ? Colors.green
                                      : Colors.grey.shade100,
                                  foregroundColor: status == 'Pending'
                                      ? Colors.white
                                      : Colors.green,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: Icon(
                                  status == 'Pending'
                                      ? Icons.group_add
                                      : Icons.check_circle,
                                ),
                                label: Text(
                                  status == 'Pending'
                                      ? 'Assign Team'
                                      : 'Track Progress',
                                ),
                                onPressed: status == 'Pending'
                                    ? () => _showAssignDialog(
                                        context,
                                        document.id,
                                        report['userId'],
                                      )
                                    : null, // Assigned නම් button එක ඔබන්න බෑ
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
