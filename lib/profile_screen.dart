import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'account_setting.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String fullName = 'NexTrack Member';
        String username = 'student_user';
        String email = user?.email ?? 'student@nextrack.com';
        String department = 'Computer Science';
        String profilePicture = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          fullName = data['name'] ?? fullName;
          username = data['username'] ?? username;
          email = data['email'] ?? email;
          department = data['department'] ?? department;
          profilePicture = data['profile_picture'] ?? '';
        }

        ImageProvider? profileImage;
        if (profilePicture.isNotEmpty) {
          if (profilePicture.startsWith('assets/')) {
            profileImage = AssetImage(profilePicture);
          } else {
            profileImage = NetworkImage(profilePicture);
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFCF8FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E0854),
                fontSize: 20.0,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF5C5468),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings feature is coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF3EEFC),
                        Color(0xFFFCF8FB),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEADDFF),
                                  width: 4.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
                                    blurRadius: 16.0,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 64.0,
                                backgroundColor: Colors.white,
                                backgroundImage: profileImage,
                                child: profileImage == null
                                    ? const Icon(
                                        Icons.person_outline_rounded,
                                        size: 64.0,
                                        color: Color(0xFF9E95A8),
                                      )
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4B0AAA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1B1D),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5C5468),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEADDFF),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: const Text(
                          'Student',
                          style: TextStyle(
                            color: Color(0xFF4B0AAA),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52.0,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B0AAA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('projects').where('members', arrayContains: user?.uid).snapshots(),
                        builder: (context, projSnapshot) {
                          final int projectsCount = projSnapshot.data?.docs.length ?? 0;
                          
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('tasks').where('user_id', isEqualTo: user?.uid).snapshots(),
                            builder: (context, taskSnapshot) {
                              final tasks = taskSnapshot.data?.docs ?? [];
                              final int totalTasks = tasks.length;
                              final int completedTasks = tasks.where((t) => t.get('status') == 'Completed').length;
                              final double rate = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100;
                              
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'PROJECTS',
                                      value: '$projectsCount',
                                      label: 'active',
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'EFFICIENCY',
                                      value: '${rate.toStringAsFixed(0)}%',
                                      label: 'score',
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      ),

                      const SizedBox(height: 24.0),
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                      ),
                      const SizedBox(height: 12.0),
                      _buildInfoCard(
                        icon: Icons.school_outlined,
                        label: 'Department',
                        value: department,
                      ),
                      const SizedBox(height: 24.0),
                      const Text(
                        'PREFERENCES',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5C5468),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      _buildPreferenceTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Account Settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountSettingScreen(),
                            ),
                          );
                        },
                      ),
                      _buildPreferenceTile(
                        icon: Icons.shield_outlined,
                        title: 'Privacy & Security',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy settings coming soon!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24.0),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFE11D48),
                          ),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFE11D48),
                              fontWeight: FontWeight.w700,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE4E2E4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5C5468),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4B0AAA),
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E95A8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE4E2E4),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFC),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4B0AAA),
              size: 22.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E95A8),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1B1D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: const Color(0xFF5C5468),
        size: 22.0,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1B1D),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9E95A8),
      ),
      onTap: onTap,
    );
  }
}
