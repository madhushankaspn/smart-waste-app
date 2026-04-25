import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedFilter = 'All';
  int _currentIndex = 0;

  // --- Team Assign කරන Function එක ---
  Future<void> _assignTeam(
    BuildContext context,
    String reportId,
    String reportUserId,
    String teamName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': 'Assigned', 'assignedTeam': teamName});

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reportUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        int currentPoints = data['points'] ?? 0;
        int newPoints = currentPoints + 1;
        String newLevel = 'Bronze';

        if (newPoints >= 1000)
          newLevel = 'Platinum';
        else if (newPoints >= 500)
          newLevel = 'Gold';
        else if (newPoints >= 100)
          newLevel = 'Silver';

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

  // --- Assign Dialog එක ---
  void _showAssignDialog(
    BuildContext context,
    String reportId,
    String reportUserId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.green,
                    ),
                  ),
                  title: Text(
                    team,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _assignTeam(context, reportId, reportUserId, team);
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  // --- Map එකේ Pin එක එබුවම පෙන්වන විස්තර කාඩ් එක ---
  void _showMapReportDetails(
    BuildContext context,
    Map<String, dynamic> report,
    String docId,
  ) {
    String status = report['status'] ?? 'Pending';
    String? base64String = report['imageBase64'];
    String assignedTeam = report['assignedTeam'] ?? '';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: base64String != null && base64String.isNotEmpty
                        ? Image.memory(
                            base64Decode(base64String),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'] ?? 'Report',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report['location'] ?? 'Unknown Location',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Pending'
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status == 'Pending'
                              ? 'Status: Pending'
                              : 'Assigned: $assignedTeam',
                          style: TextStyle(
                            color: status == 'Pending'
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (status == 'Pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showAssignDialog(context, docId, report['userId']);
                  },
                  child: const Text(
                    'Assign Collection Team',
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
    );
  }

  // ==========================================
  // TAB 1: සාමාන්‍ය Reports List එක
  // ==========================================
  Widget _buildReportsTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3D1F), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SYSTEM OVERVIEW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Manage Waste',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review, assign teams, and keep the city clean.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Assigned'].map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) =>
                        setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

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

              var reports = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                if (_selectedFilter == 'All') return true;
                return data['status'] == _selectedFilter;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  var document = reports[index];
                  var report = document.data() as Map<String, dynamic>;
                  String status = report['status'] ?? 'Pending';
                  String assignedTeam = report['assignedTeam'] ?? '';
                  String? base64String = report['imageBase64'];

                  double? lat = report['latitude'];
                  double? lng = report['longitude'];
                  LatLng? reportLocation;
                  if (lat != null && lng != null)
                    reportLocation = LatLng(lat, lng);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade100,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            report['title'] ?? 'Report',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
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
                                            status == 'Pending'
                                                ? 'Pending'
                                                : 'Assigned',
                                            style: TextStyle(
                                              color: status == 'Pending'
                                                  ? Colors.orange.shade800
                                                  : Colors.green.shade800,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report['location'] ?? 'Unknown Location',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reported by: ${report['userEmail'] ?? 'User'}',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (reportLocation != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: reportLocation,
                                    initialZoom: 15.0,
                                    interactionOptions:
                                        const InteractionOptions(
                                          flags: InteractiveFlag.none,
                                        ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.swm_app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: reportLocation,
                                          width: 30,
                                          height: 30,
                                          child: const Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          if (status == 'Pending')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => _showAssignDialog(
                                  context,
                                  document.id,
                                  report['userId'],
                                ),
                                child: const Text(
                                  'Assign Collection Team',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Assigned to $assignedTeam',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
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
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: Live Map එක
  // ==========================================
  Widget _buildLiveMapTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );

        List<Marker> mapMarkers = [];

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'Pending';
          double? lat = data['latitude'];
          double? lng = data['longitude'];

          if (lat != null && lng != null) {
            Color pinColor = status == 'Pending' ? Colors.red : Colors.green;
            IconData pinIcon = status == 'Pending'
                ? Icons.warning_rounded
                : Icons.local_shipping;

            mapMarkers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _showMapReportDetails(context, data, doc.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: pinColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(pinIcon, color: Colors.white, size: 24),
                  ),
                ),
              ),
            );
          }
        }

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(6.9271, 79.8612),
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.swm_app',
                ),
                MarkerLayer(markers: mapMarkers),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Pending'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Assigned'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 3: අලුත් කරපු ලස්සන "Teams" Tab එක
  // ==========================================
  Widget _buildTeamsTab() {
    List<String> teamNames = [
      'Team Alpha (Truck 1)',
      'Team Beta (Truck 2)',
      'Team Gamma (Truck 3)',
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'Assigned')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );

        Map<String, int> teamWorkload = {
          'Team Alpha (Truck 1)': 0,
          'Team Beta (Truck 2)': 0,
          'Team Gamma (Truck 3)': 0,
        };

        int totalTasks = 0; // මුළු වැඩ ගාණ

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String assignedTo = data['assignedTeam'] ?? '';
          if (teamWorkload.containsKey(assignedTo)) {
            teamWorkload[assignedTo] = teamWorkload[assignedTo]! + 1;
            totalTasks++;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. උඩින්ම තියෙන අලුත් Overview Card එක
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3D1F), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
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
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FLEET OVERVIEW',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '3 Active Teams',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Tasks',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$totalTasks',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Live Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // 2. ලස්සන කරපු Teams Cards ටික
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: teamNames.length,
                itemBuilder: (context, index) {
                  String teamName = teamNames[index];
                  int tasks = teamWorkload[teamName] ?? 0;

                  bool isBusy = tasks > 3; // වැඩ 3 කට වඩා තියෙනවා නම් Busy

                  // Progress Bar එකට අගය හදනවා (උපරිම වැඩ 5ක් කියලා හිතමු)
                  double progress = tasks / 5.0;
                  if (progress > 1.0) progress = 1.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Truck Icon එක
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isBusy
                                      ? Colors.orange.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: isBusy ? Colors.orange : Colors.green,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Team නම සහ Status එක
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teamName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isBusy
                                                ? Colors.orange
                                                : Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isBusy
                                              ? 'Busy / Heavy Workload'
                                              : 'Available',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Task ගාණ
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$tasks',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isBusy
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    ),
                                    const Text(
                                      'Tasks',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // අලුතින් දාපු Progress Bar එක
                          Row(
                            children: [
                              const Text(
                                'Capacity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    color: isBusy
                                        ? Colors.orange
                                        : Colors.green,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // ප්‍රධාන Build Function එක
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),

      body: _currentIndex == 0
          ? _buildReportsTab()
          : _currentIndex == 1
          ? _buildLiveMapTab()
          : _currentIndex == 2
          ? _buildTeamsTab() // 3 වෙනි Tab එකට ගියාම අලුත් කෑල්ල පෙන්වනවා
          : const Center(
              child: Text(
                'Settings Coming Soon...',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded),
                label: 'Live Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: 'Teams',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
