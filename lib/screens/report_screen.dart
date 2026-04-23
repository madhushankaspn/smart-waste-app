import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  Uint8List? _selectedImageBytes;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  // අලුත් කරපු Image Pick කරන Function එක
  Future<void> _pickImage() async {
    try {
      // Web එකට අවුලක් නොඑන්න සාමාන්‍ය විදිහටම ෆොටෝ එක ගන්නවා
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _selectedImageBytes = bytes;
          _base64Image = base64String;
        });
      }
    } catch (e) {
      // මොකක් හරි අවුලක් ගියොත් අපිට රතු පාටින් Error එක පෙන්වයි
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

  // Database එකට යවන Function එක
  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all text fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // තත්පර 15ක Timeout එකක් දාලා තියෙන්නේ. ඊට වඩා ගියොත් Error එකක් පෙන්වනවා.
      await FirebaseFirestore.instance
          .collection('reports')
          .add({
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'location': _locationController.text.trim(),
            'imageBase64': _base64Image,
            'userId': user?.uid,
            'userEmail': user?.email,
            'status': 'Pending',
            'timestamp': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report Submitted Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // මොකක් හරි වැරදුනොත් Loading එක නවත්තලා Error එක පෙන්වනවා
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload Failed! Image might be too large. (Error: $e)',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
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
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add a photo',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
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

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              maxLines: 4,
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
