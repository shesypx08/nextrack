import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';
import 'tasks_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 4) {
      return Scaffold(
        body: const ProfileScreen(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title = 'NexTrack';
    IconData icon = Icons.task_alt_rounded;

    if (_currentIndex == 0) {
      title = 'Dashboard';
      icon = Icons.dashboard_outlined;
    } else if (_currentIndex == 1) {
      title = 'Projects';
      icon = Icons.folder_open_outlined;
    } else if (_currentIndex == 2) {
      title = 'My Tasks';
      icon = Icons.check_circle_outline_rounded;
    } else if (_currentIndex == 3) {
      title = 'Reports';
      icon = Icons.bar_chart_rounded;
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEADDFF),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: const Color(0xFF4B0AAA), size: 20.0),
          ),
          const SizedBox(width: 10.0),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854), fontSize: 18.0),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
          tooltip: 'Log Out',
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return _buildHomeTab();
      case 1: return const ProjectsScreen();
      case 2: return const TasksScreen();
      case 3: return const ReportsScreen();
      default: return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        String greetingName = 'Student';
        String departmentName = 'Academic Member';
        String profilePicture = '';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>;
          greetingName = data['name'] ?? 'Student';
          departmentName = data['department'] ?? 'Academic Member';
          profilePicture = data['profile_picture'] ?? '';
        }

        ImageProvider? profileImage;
        if (profilePicture.isNotEmpty) {
          profileImage = profilePicture.startsWith('assets/') ? AssetImage(profilePicture) : NetworkImage(profilePicture) as ImageProvider;
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(greetingName, departmentName, profileImage),
                const SizedBox(height: 24.0),
                const Text('URGENT DELIVERABLE', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2)),
                const SizedBox(height: 10.0),
                _buildUrgentProjectStream(user?.uid),
                const SizedBox(height: 28.0),
                const Text('UPCOMING SUBMISSIONS', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2)),
                const SizedBox(height: 10.0),
                _buildUpcomingSubmissionsStream(user?.uid),
                const SizedBox(height: 28.0),
                const Text('PROJECT SUMMARY', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2)),
                const SizedBox(height: 12.0),
                _buildProjectMetrics(user?.uid),
                const SizedBox(height: 28.0),
                const Text('TASK SUMMARY', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2)),
                const SizedBox(height: 12.0),
                _buildTaskMetrics(user?.uid),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(String name, String dept, ImageProvider? img) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4B0AAA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [BoxShadow(color: const Color(0xFF4B0AAA).withValues(alpha: 0.12), blurRadius: 16.0, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WELCOME BACK!', style: TextStyle(color: Color(0xFFEADDFF), fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 6.0),
                Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4.0),
                Text(dept, style: const TextStyle(color: Colors.white70, fontSize: 13.0)),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          CircleAvatar(radius: 30.0, backgroundColor: Colors.white24, backgroundImage: img, child: img == null ? const Icon(Icons.person, color: Colors.white, size: 28.0) : null),
        ],
      ),
    );
  }

  Widget _buildUrgentProjectStream(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').where('members', arrayContains: uid).snapshots(),
      builder: (context, snapshot) {
        final projects = snapshot.data?.docs ?? [];
        Map<String, dynamic>? urgent;
        
        List<QueryDocumentSnapshot> activeOnes = projects.where((p) => p.get('status') != 'Completed').toList();
        
        if (activeOnes.isNotEmpty) {
          activeOnes.sort((a, b) {
            Timestamp? tA = a.get('deadline');
            Timestamp? tB = b.get('deadline');
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tA.compareTo(tB);
          });
          urgent = activeOnes.first.data() as Map<String, dynamic>;
        }
        
        return _buildUrgentProjectWidget(urgent);
      },
    );
  }

  Widget _buildUrgentProjectWidget(Map<String, dynamic>? project) {
    if (project == null) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.0), border: Border.all(color: const Color(0xFFE4E2E4))),
        child: const Column(children: [Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 36.0), SizedBox(height: 10.0), Text('No Urgent Projects', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF2E0854))), Text('Everything is under control!', style: TextStyle(fontSize: 12.5, color: Color(0xFF5C5468)))]),
      );
    }

    double prog = (project['progress'] ?? 0.0).toDouble();
    String deadline = 'No deadline';
    if (project['deadline'] != null) {
      deadline = DateFormat('d MMM yyyy').format((project['deadline'] as Timestamp).toDate());
    }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.0), border: Border.all(color: const Color(0xFFEADDFF), width: 1.5)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Text('PRIORITY ACTION', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          Text(project['project_name'] ?? 'Project', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF5C5468)),
              const SizedBox(width: 4),
              Text('Due: $deadline', style: const TextStyle(fontSize: 12, color: Color(0xFF5C5468))),
            ],
          ),
        ])),
        const SizedBox(width: 16),
        _buildCircularProgress(prog, 64, 7),
      ]),
    );
  }

  Widget _buildUpcomingSubmissionsStream(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').where('members', arrayContains: uid).snapshots(),
      builder: (context, snapshot) {
        final projects = snapshot.data?.docs ?? [];
        List<QueryDocumentSnapshot> activeOnes = projects.where((p) => p.get('status') != 'Completed').toList();
        
        if (activeOnes.length > 1) {
          activeOnes.sort((a, b) {
            Timestamp? tA = a.get('deadline');
            Timestamp? tB = b.get('deadline');
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tA.compareTo(tB);
          });
          activeOnes.removeAt(0);
        } else {
          activeOnes = [];
        }

        final displayList = activeOnes.take(3).toList();
        if (displayList.isEmpty) return const SizedBox.shrink();

        return Column(
          children: displayList.map((pDoc) {
            final p = pDoc.data() as Map<String, dynamic>;
            String deadline = 'No deadline';
            if (p['deadline'] != null) {
              deadline = DateFormat('d MMM').format((p['deadline'] as Timestamp).toDate());
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E2E4))),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 24,
                    decoration: BoxDecoration(color: const Color(0xFF4B0AAA), borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['project_name'] ?? 'Project', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Deadline: $deadline', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFE4E2E4)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCircularProgress(double val, double size, double stroke) {
    return Stack(alignment: Alignment.center, children: [
      SizedBox(width: size, height: size, child: CircularProgressIndicator(value: val / 100, strokeWidth: stroke, backgroundColor: const Color(0xFFF3EEFC), color: const Color(0xFF4B0AAA))),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${val.toStringAsFixed(0)}%', style: TextStyle(fontSize: size * 0.18, fontWeight: FontWeight.w900, color: const Color(0xFF4B0AAA))),
      ]),
    ]);
  }

  Widget _buildProjectMetrics(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').where('members', arrayContains: uid).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final completed = docs.where((p) => p.get('status') == 'Completed').length;
        final total = docs.length;
        return Row(children: [
          Expanded(child: _buildMetricCard('Completed', completed, Icons.check_circle, Colors.green, 'Projects')),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard('Active', total - completed, Icons.rocket_launch, Colors.blue, 'Projects')),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard('Total', total, Icons.folder, const Color(0xFF4B0AAA), 'Projects')),
        ]);
      },
    );
  }

  Widget _buildTaskMetrics(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').where('user_id', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final done = docs.where((t) => t.get('status') == 'Completed').length;
        return Row(children: [
          Expanded(child: _buildMetricCard('Finished', done, Icons.task_alt, Colors.teal, 'Tasks')),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard('Pending', docs.length - done, Icons.hourglass_top, Colors.orange, 'Tasks')),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard('Total', docs.length, Icons.checklist, const Color(0xFF6D28D9), 'Tasks')),
        ]);
      },
    );
  }

  Widget _buildMetricCard(String title, int count, IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE4E2E4))),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 12),
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF5C5468))),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9E95A8))),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: const Color(0xFFE4E2E4).withValues(alpha: 0.5), width: 1.0))),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4B0AAA),
        unselectedItemColor: const Color(0xFF9E95A8),
        selectedLabelStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_open_outlined), activeIcon: Icon(Icons.folder_rounded), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline_rounded), activeIcon: Icon(Icons.check_circle_rounded), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
