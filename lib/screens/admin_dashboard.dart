import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Admin Approve කරන Function එක
  Future<void> _approveReport(
    BuildContext context,
    String reportId,
    String reportUserId,
  ) async {
    try {
      // 1. Report එකේ status එක 'Approved' කරනවා
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': 'Approved'});

      // 2. Report එක දාපු User ට Point එක දෙනවා
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
            content: Text('Report Approved & Point Awarded!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87, // Admin එක අඳුරගන්න කළු පාටක් දුන්නා
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
      // ඔක්කොම Reports ගන්නවා (Pending ඒවා උඩින් එන්න)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reports available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var document = snapshot.data!.docs[index];
              var report = document.data() as Map<String, dynamic>;
              String reportId = document.id; // Document ID එක ගන්නවා
              String reportUserId = report['userId'] ?? '';
              String status = report['status'] ?? 'Pending';
              String? base64String = report['imageBase64'];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child:
                                  base64String != null &&
                                      base64String.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(base64String),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  report['location'] ?? 'Unknown Location',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'By: ${report['userEmail'] ?? 'Unknown User'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Pending'
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Pending නම් විතරක් Approve Button එක පෙන්වනවා
                      if (status == 'Pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () =>
                                _approveReport(context, reportId, reportUserId),
                            child: const Text(
                              'Approve & Give Point',
                              style: TextStyle(color: Colors.white),
                            ),
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
    );
  }
}
