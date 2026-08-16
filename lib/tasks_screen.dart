import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Academic Tasks',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E0854),
            fontSize: 20.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E2E4)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4B0AAA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('user_id', isEqualTo: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyTaskView();
                }

                // search task by name
                final tasksDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['task_name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (tasksDocs.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text('No matching tasks found.', style: TextStyle(color: Colors.grey)));
                }

                final Map<String, List<QueryDocumentSnapshot>> groupedTasks = {};

                for (final doc in tasksDocs) {
                  final task = doc.data() as Map<String, dynamic>;
                  final String projectId = task['project_id'] ?? 'Independent';
                  if (!groupedTasks.containsKey(projectId)) {
                    groupedTasks[projectId] = [];
                  }
                  groupedTasks[projectId]!.add(doc);
                }

                final List<String> projectIds = groupedTasks.keys.toList();

                return ListView.builder(
                  itemCount: projectIds.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  itemBuilder: (context, projectIndex) {
                    final String projectId = projectIds[projectIndex];
                    final List<QueryDocumentSnapshot> projectTasks = groupedTasks[projectId]!;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('projects').doc(projectId).get(),
                      builder: (context, projectSnapshot) {
                        String projectName = 'Independent Tasks';
                        if (projectSnapshot.hasData && projectSnapshot.data!.exists) {
                          projectName = projectSnapshot.data!['project_name'] ?? projectName;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EEFC),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: const Color(0xFFEADDFF)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.folder_shared_rounded, color: Color(0xFF4B0AAA), size: 18.0),
                                        const SizedBox(width: 8.0),
                                        Expanded(
                                          child: Text(
                                            projectName.toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4B0AAA),
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4B0AAA),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Text(
                                      '${projectTasks.length} tasks',
                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: projectTasks.length,
                              itemBuilder: (context, taskIndex) {
                                final taskDoc = projectTasks[taskIndex];
                                final task = taskDoc.data() as Map<String, dynamic>;
                                final String taskName = task['task_name'] ?? 'Untitled Task';
                                final String description = task['description'] ?? 'No description provided';
                                final String status = task['status'] ?? 'Pending';
                                final bool isCompleted = status == 'Completed';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  color: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    side: const BorderSide(color: Color(0xFFE4E2E4)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                taskName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15.0,
                                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                  color: isCompleted ? const Color(0xFF9E95A8) : const Color(0xFF1B1B1D),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (task['difficulty_level'] == 'Hard' ? Colors.redAccent : (task['difficulty_level'] == 'Medium' ? Colors.orange : Colors.green)).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (task['difficulty_level'] ?? 'Medium').toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: task['difficulty_level'] == 'Hard' ? Colors.redAccent : (task['difficulty_level'] == 'Medium' ? Colors.orange : Colors.green),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(description, style: const TextStyle(fontSize: 13.0, color: Color(0xFF5C5468), height: 1.3)),
                                        const SizedBox(height: 14.0),
                                        const Divider(height: 1.0, color: Color(0xFFE4E2E4)),
                                        const SizedBox(height: 10.0),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Status: $status',
                                              style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Color(0xFF5C5468)),
                                            ),
                                            if (status == 'Completed')
                                              const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                            else
                                              const Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
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

  Widget _buildEmptyTaskView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(color: Color(0xFFF3EEFC), shape: BoxShape.circle),
              child: const Icon(Icons.playlist_add_check_rounded, size: 64.0, color: Color(0xFF4B0AAA)),
            ),
            const SizedBox(height: 20.0),
            const Text('All Caught Up!', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF2E0854))),
            const SizedBox(height: 8.0),
            const Text(
              'No tasks assigned. Go to Workspace\nto create and assign new tasks for your team.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF5C5468), height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
