import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'personal_details_screen.dart';
import 'manage_email_screen.dart';
import 'faq_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';

class AccountSettingScreen extends StatefulWidget {
  const AccountSettingScreen({super.key});

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen> {
  bool _isDeleting = false;

  void _confirmDeleteAccount() {
    bool agreed = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Delete Account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action is permanent and will remove all your data from NexTrack, including your project contributions.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: agreed,
                    activeColor: Colors.red,
                    onChanged: (val) => setModalState(() => agreed = val ?? false),
                  ),
                  const Expanded(
                    child: Text('I understand and wish to proceed.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: agreed ? () => _handleDeleteAccount() : null,
              child: Text('Delete', style: TextStyle(color: agreed ? Colors.red : Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final navigator = Navigator.of(context);
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isDeleting = true);
    Navigator.pop(context);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      
      // delete all submissions by user
      final submissions = await FirebaseFirestore.instance.collection('submissions').where('user_id', isEqualTo: uid).get();
      for (var doc in submissions.docs) {
        await doc.reference.delete();
      }

      // delete all chat messages by user
      final messages = await FirebaseFirestore.instance.collection('project_messages').where('user_id', isEqualTo: uid).get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // return tasks to pool
      final tasks = await FirebaseFirestore.instance.collection('tasks').where('user_id', isEqualTo: uid).get();
      for (var doc in tasks.docs) {
        await doc.reference.update({'user_id': null, 'status': 'Pending'});
      }

      // remove user from projects
      final projects = await FirebaseFirestore.instance.collection('projects').where('members', arrayContains: uid).get();
      for (var doc in projects.docs) {
        await doc.reference.update({'members': FieldValue.arrayRemove([uid])});
        await doc.reference.collection('members').doc(uid).delete();
        
        // delete project and all data if user is leader
        final data = doc.data() as Map<String, dynamic>;
        if (data['team_leader_id'] == uid) {
          // delete all tasks in this project
          final projectTasks = await FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: doc.id).get();
          for (var tDoc in projectTasks.docs) {
            // delete task submissions
            final taskSubs = await FirebaseFirestore.instance.collection('submissions').where('task_id', isEqualTo: tDoc.id).get();
            for (var sDoc in taskSubs.docs) {
              await sDoc.reference.delete();
            }
            await tDoc.reference.delete();
          }
          // delete all project messages
          final projectMsgs = await FirebaseFirestore.instance.collection('project_messages').where('project_id', isEqualTo: doc.id).get();
          for (var mDoc in projectMsgs.docs) {
            await mDoc.reference.delete();
          }
          await doc.reference.delete();
        }
      }

      if (user != null) {
        // delete user from database
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        
        // delete user from auth
        await user.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e. You might need to re-login to delete account.'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Account Settings',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854)),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildSection(
                  title: 'PROFILE INFORMATION',
                  items: [
                    _SettingTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Details',
                      subtitle: 'Name, username, and bio',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDetailsScreen()));
                      },
                    ),
                    _SettingTile(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      subtitle: 'Manage your verified email',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageEmailScreen()));
                      },
                    ),
                  ],
                ),
                _buildSection(
                  title: 'NOTIFICATIONS',
                  items: [
                    _SettingTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notification Settings',
                      subtitle: 'Push alerts and email reports',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                      },
                    ),
                  ],
                ),
                _buildSection(
                  title: 'HELP & SUPPORT',
                  items: [
                    _SettingTile(
                      icon: Icons.help_outline_rounded,
                      title: 'FAQ',
                      subtitle: 'Frequently asked questions',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
                      },
                    ),
                    _SettingTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Contact Support',
                      subtitle: 'Get help with your account',
                      onTap: () {},
                    ),
                  ],
                ),
                _buildSection(
                  title: 'ACCOUNT MANAGEMENT',
                  items: [
                    _SettingTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your security',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                      },
                    ),
                    _SettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your data',
                      onTap: _confirmDeleteAccount,
                      isDestructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5C5468),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E2E4)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFF3EEFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF4B0AAA), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDestructive ? Colors.red : const Color(0xFF1B1B1D),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9E95A8)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFE4E2E4)),
    );
  }
}
