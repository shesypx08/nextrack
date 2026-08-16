import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_project_screen.dart';
import 'join_project_screen.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // get member detail
  Future<List<Map<String, dynamic>>> _fetchMemberDetails(List uids) async {
    List<Map<String, dynamic>> memberDetails = [];
    // limit to first 5 member
    for (String uid in uids.take(5)) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        memberDetails.add(userDoc.data()!);
      }
    }
    return memberDetails;
  }

  void _confirmDeleteProject(String projectId, String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "$projectName"? This will permanently remove all tasks and data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              
              // delete project task
              final tasks = await FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: projectId).get();
              for (var doc in tasks.docs) {
                await doc.reference.delete();
              }
              
              // delete project submission
              final subs = await FirebaseFirestore.instance.collection('submissions').where('task_id', whereIn: tasks.docs.map((d) => d.id).toList() + ['dummy']).get();
              for (var doc in subs.docs) {
                await doc.reference.delete();
              }

              // delete project from database
              await FirebaseFirestore.instance.collection('projects').doc(projectId).delete();
              
              if (mounted) {
                navigator.pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted successfully.')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Academic Workspace',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E0854),
            fontSize: 20.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.group_add_rounded,
              color: Color(0xFF4B0AAA),
            ),
            tooltip: 'Join Project',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JoinProjectScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E2E4)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4B0AAA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProjectScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18.0,
                    ),
                    label: const Text(
                      'Add New Project',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B0AAA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JoinProjectScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.vpn_key_rounded,
                      size: 18.0,
                    ),
                    label: const Text(
                      'Join Project',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4B0AAA),
                      side: const BorderSide(
                        color: Color(0xFFEADDFF),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            const Text(
              'COLLABORATIONS & TEAMS',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C5468),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .where('members', arrayContains: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyProjectView();
                  }

                  // search project by name
                  final projects = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['project_name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (projects.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(child: Text('No matching projects found.', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    itemCount: projects.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final projectDoc = projects[index];
                      final project = projectDoc.data() as Map<String, dynamic>;
                      final String projectId = projectDoc.id;
                      final String name = project['project_name'] ?? 'Project Alpha';
                      final String desc = project['description'] ?? 'No description provided';
                      final String priority = project['priority'] ?? 'Medium';
                      final double progress = (project['progress'] ?? 0.0).toDouble();
                      final List memberUids = project['members'] ?? [];
                      final String leaderId = project['team_leader_id'] ?? '';
                      final bool isLeader = leaderId == user?.uid;
                      
                      Color pColor = Colors.orange;
                      if (priority == 'High') {
                        pColor = Colors.redAccent;
                      } else if (priority == 'Low') { pColor = Colors.green; }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailsScreen(
                                  projectId: projectId,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(24.0),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 4.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(radius: 3, backgroundColor: pColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            priority,
                                            style: TextStyle(
                                              color: pColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isLeader)
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        onPressed: () => _confirmDeleteProject(projectId, name),
                                      )
                                    else
                                      const Text(
                                        'Active Workspace',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5C5468),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 22.0,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1B1B1D),
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            desc,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14.0,
                                              color: Color(0xFF5C5468),
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 86,
                                          height: 86,
                                          child: CircularProgressIndicator(
                                            value: progress / 100,
                                            strokeWidth: 9,
                                            strokeCap: StrokeCap.round,
                                            backgroundColor: const Color(0xFFF3EEFC),
                                            color: const Color(0xFF4B89FF),
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${progress.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1B1B1D),
                                              ),
                                            ),
                                            const Text(
                                              'Complete',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF9E95A8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Color(0xFFF1F1F1), thickness: 1.2),
                                const SizedBox(height: 16),
                                const Text(
                                  'Team Members',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5C5468),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _fetchMemberDetails(memberUids),
                                  builder: (context, memberSnapshot) {
                                    if (!memberSnapshot.hasData) {
                                      return const SizedBox(height: 40);
                                    }
                                    final members = memberSnapshot.data!;
                                    return Row(
                                      children: [
                                        ...members.map((m) {
                                          final String pic = m['profile_picture'] ?? '';
                                          final bool isMemberLeader = m['user_id'] == leaderId;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isMemberLeader ? const Color(0xFF4B0AAA) : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(0xFFF3EEFC),
                                                backgroundImage: pic.isNotEmpty 
                                                  ? (pic.startsWith('assets') ? AssetImage(pic) : NetworkImage(pic)) as ImageProvider
                                                  : null,
                                                child: pic.isEmpty ? const Icon(Icons.person, size: 20) : null,
                                              ),
                                            ),
                                          );
                                        }),
                                        if (memberUids.length > 5)
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(0xFFEADDFF),
                                            child: Text(
                                              '+${memberUids.length - 5}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4B0AAA),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildEmptyProjectView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Color(0xFFF3EEFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                size: 64.0,
                color: Color(0xFF4B0AAA),
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'No Active Projects',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E0854),
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Create a new project or enter an invitation\ncode to join a collaborative team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF5C5468),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
