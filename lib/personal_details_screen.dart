import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B1B1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Details',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          final String name = data['name'] ?? 'Not set';
          final String username = data['username'] ?? 'Not set';
          final String department = data['department'] ?? 'Not set';
          final String bio = data['bio'] ?? 'No bio added yet.';
          final String profilePic = data['profile_picture'] ?? '';

          ImageProvider? img;
          if (profilePic.isNotEmpty) {
            img = profilePic.startsWith('assets') ? AssetImage(profilePic) : NetworkImage(profilePic) as ImageProvider;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFF3EEFC),
                    backgroundImage: img,
                    child: img == null ? const Icon(Icons.person, size: 50, color: Color(0xFF4B0AAA)) : null,
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoBlock('FULL NAME', name),
                const SizedBox(height: 24),
                _buildInfoBlock('USERNAME', '@$username'),
                const SizedBox(height: 24),
                _buildInfoBlock('DEPARTMENT', department),
                const SizedBox(height: 24),
                _buildInfoBlock('BIO', bio),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B0AAA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF9E95A8), letterSpacing: 1.1),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1D)),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFFE4E2E4)),
      ],
    );
  }
}
