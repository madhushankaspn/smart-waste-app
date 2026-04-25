import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart'; // මේක අලුතින් ඕනේ
import 'dart:typed_data';
import 'dart:convert';
import 'map_picker_screen.dart'; // මැප් එක තියෙන ෆයිල් එක
import 'package:geolocator/geolocator.dart'; // දුර මනින්න මේක ඕනේ

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  Uint8List? _selectedImageBytes;
  String? _base64Image;
  LatLng? _pickedLocation; // තෝරගත්ත මැප් ලොකේෂන් එක සේව් කරන්න
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // මැප් එක ඕපන් කරන Function එක
  Future<void> _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _pickedLocation = result;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_base64Image == null || _pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image and map location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ------------------------------------------------------------------
      // අලුත් කෑල්ල: කලින් රිපෝට් කරලා තියෙනවද කියලා දුර මැනලා බලන කොටස
      // ------------------------------------------------------------------

      // Database එකේ දැනට තියෙන (Pending සහ Assigned) රිපෝට් ටික ගන්නවා
      QuerySnapshot existingReports = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', whereIn: ['Pending', 'Assigned'])
          .get();

      bool isDuplicate = false;

      // එකින් එක අරන් දුර බලනවා
      for (var doc in existingReports.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double? lat = data['latitude'];
        double? lng = data['longitude'];

        if (lat != null && lng != null) {
          // අලුත් ලොකේෂන් එකයි, පරණ ලොකේෂන් එකයි අතර දුර මීටර් වලින් මනිනවා
          double distanceInMeters = Geolocator.distanceBetween(
            _pickedLocation!.latitude,
            _pickedLocation!.longitude,
            lat,
            lng,
          );

          // මීටර් 50කට වඩා අඩු නම්, ඒක Duplicate එකක් විදිහට සලකනවා
          if (distanceInMeters < 50) {
            isDuplicate = true;
            break; // Loop එක නවත්තනවා
          }
        }
      }

      // කලින් රිපෝට් කරපු එකක් නම්, Pop-up එක පෙන්නලා සේව් කරන එක නවත්තනවා
      if (isDuplicate) {
        setState(() => _isLoading = false); // Loading එක නවත්තනවා
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Already Reported!',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
              content: const Text(
                'This garbage location has already been reported by someone else recently.\n\nThank you for your vigilance!',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Pop-up එක වහනවා
                      Navigator.pop(
                        context,
                      ); // Report Screen එකෙනුත් අයින් වෙලා Home එකට යනවා
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return; // Function එක මෙතනින් නවත්තනවා (Database එකට යවන්නේ නෑ)
      }
      // ------------------------------------------------------------------

      // අලුත් එකක් නම් සාමාන්‍ය විදිහටම Database එකට Save කරනවා
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('reports')
          .add({
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'imageBase64': _base64Image,
            'userId': user?.uid,
            'userEmail': user?.email,
            'status': 'Pending',
            'latitude': _pickedLocation!.latitude,
            'longitude': _pickedLocation!.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report Submitted! Waiting for Admin Approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Waste'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Image Picker Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.add_a_photo,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Report Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // මැප් එකෙන් ලොකේෂන් තෝරන Button එක
            InkWell(
              onTap: _openMapPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _pickedLocation != null ? Colors.green : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: _pickedLocation != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedLocation == null
                            ? 'Select Location from Map'
                            : 'Location Selected: ${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          color: _pickedLocation != null
                              ? Colors.green
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _isLoading ? null : _submitReport,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
