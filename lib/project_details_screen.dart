import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'project_chat_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _proofLinkController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editDescController = TextEditingController();
  final TextEditingController _editLimitController = TextEditingController();

  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescController.dispose();
    _remarksController.dispose();
    _proofLinkController.dispose();
    _commentController.dispose();
    _editNameController.dispose();
    _editDescController.dispose();
    _editLimitController.dispose();
    super.dispose();
  }

  void _confirmDeleteProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text('This will permanently remove the project and all its tasks. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              // delete all task under this project
              final tasks = await FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: widget.projectId).get();
              for (var doc in tasks.docs) {
                await doc.reference.delete();
              }
              // delete project from database
              await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).delete();
              
              if (mounted) {
                navigator.pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // go back to project list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(String taskId, String taskName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "$taskName"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              // delete submission first
              final subs = await FirebaseFirestore.instance.collection('submissions').where('task_id', isEqualTo: taskId).get();
              for (var doc in subs.docs) {
                await doc.reference.delete();
              }
              // delete task from database
              await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
              
              _updateProjectProgress();
              if (mounted) navigator.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    
    final Uri? uri = Uri.tryParse(formattedUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link. Please ensure it is a valid URL.')));
    }
  }

  Stream<List<Map<String, dynamic>>> _getMembersStream() {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('members')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> memberDetails = [];
          for (var doc in snapshot.docs) {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(doc['user_id']).get();
            if (userDoc.exists) {
              memberDetails.add({
                ...userDoc.data()!,
                'member_role': doc['member_role'],
              });
            }
          }
          return memberDetails;
        });
  }

  void _showEditProjectSheet(Map<String, dynamic> project) {
    _editNameController.text = project['project_name'] ?? '';
    _editDescController.text = project['description'] ?? '';
    _editLimitController.text = (project['task_limit'] ?? 5).toString();
    String priority = project['priority'] ?? 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Project Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2E0854))),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteProject(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSheetLabel('PROJECT NAME'),
              TextField(controller: _editNameController),
              const SizedBox(height: 16),
              _buildSheetLabel('DESCRIPTION'),
              TextField(controller: _editDescController, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSheetLabel('PRIORITY'),
                        DropdownButtonFormField<String>(
                          initialValue: priority,
                          items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (val) => setModalState(() => priority = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSheetLabel('TASK LIMIT'),
                        TextField(controller: _editLimitController, keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).update({
                      'project_name': _editNameController.text.trim(),
                      'description': _editDescController.text.trim(),
                      'priority': priority,
                      'task_limit': int.tryParse(_editLimitController.text) ?? 5,
                    });
                    _updateProjectProgress();
                    if (mounted) navigator.pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B0AAA), foregroundColor: Colors.white),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet() {
    _taskTitleController.clear();
    _taskDescController.clear();
    String selectedDifficulty = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2E0854))),
              const SizedBox(height: 18),
              _buildSheetLabel('TASK NAME'),
              TextField(controller: _taskTitleController),
              const SizedBox(height: 16),
              _buildSheetLabel('DESCRIPTION'),
              TextField(controller: _taskDescController, maxLines: 2),
              const SizedBox(height: 16),
              _buildSheetLabel('DIFFICULTY LEVEL'),
              const SizedBox(height: 8),
              _buildDifficultyButton('Hard', Colors.redAccent, selectedDifficulty == 'Hard', (val) => setModalState(() => selectedDifficulty = val)),
              const SizedBox(height: 8),
              _buildDifficultyButton('Medium', Colors.orange, selectedDifficulty == 'Medium', (val) => setModalState(() => selectedDifficulty = val)),
              const SizedBox(height: 8),
              _buildDifficultyButton('Easy', Colors.green, selectedDifficulty == 'Easy', (val) => setModalState(() => selectedDifficulty = val)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (_taskTitleController.text.isEmpty) return;
                    // add new task to database
                    DocumentReference taskRef = await FirebaseFirestore.instance.collection('tasks').add({
                      'project_id': widget.projectId,
                      'task_name': _taskTitleController.text.trim(),
                      'description': _taskDescController.text.trim(),
                      'status': 'Pending',
                      'difficulty_level': selectedDifficulty,
                      'user_id': null, 
                      'created_at': FieldValue.serverTimestamp(),
                    });
                    await taskRef.update({'task_id': taskRef.id});
                    _updateProjectProgress();
                    if (mounted) navigator.pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B0AAA), foregroundColor: Colors.white),
                  child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String level, Color color, bool isSelected, Function(String) onTap) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () => onTap(level),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          side: BorderSide(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) Icon(Icons.check_circle, size: 16, color: color),
            if (isSelected) const SizedBox(width: 8),
            Text(
              level.toUpperCase(),
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitProofSheet(String taskId) {
    _remarksController.clear();
    _proofLinkController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit Work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2E0854))),
            const SizedBox(height: 18),
            _buildSheetLabel('WORK LINK (URL)'),
            TextField(controller: _proofLinkController),
            const SizedBox(height: 16),
            _buildSheetLabel('REMARKS'),
            TextField(controller: _remarksController, maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (_proofLinkController.text.isEmpty) return;
                  // add submission to database
                  DocumentReference subRef = await FirebaseFirestore.instance.collection('submissions').add({
                    'task_id': taskId,
                    'user_id': _currentUserId,
                    'remarks': _remarksController.text.trim(),
                    'submission_date': FieldValue.serverTimestamp(),
                    'approval_status': 'Pending',
                    'leader_comment': null,
                    'review_date': null,
                    'file_path': _proofLinkController.text.trim(), 
                  });
                  await subRef.update({'submission_id': subRef.id});
                  await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'status': 'In Review'});
                  if (mounted) navigator.pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B0AAA), foregroundColor: Colors.white),
                child: const Text('Submit for Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSheet(String taskId, Map<String, dynamic> submission, String submissionId) {
    _commentController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Submission', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2E0854))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF3EEFC), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.link, size: 16, color: Color(0xFF4B0AAA)), SizedBox(width: 8), Text('Member Work:', style: TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 4),
                  InkWell(onTap: () => _launchURL(submission['file_path']), child: Text(submission['file_path'], style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13))),
                  const SizedBox(height: 12),
                  const Text('Member Remarks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(submission['remarks'] ?? 'No remarks.', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildSheetLabel('LEADER COMMENT'),
            TextField(controller: _commentController, maxLines: 3, decoration: const InputDecoration(hintText: 'Provide feedback for improvement...')),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      // change submission to reject
                      await FirebaseFirestore.instance.collection('submissions').doc(submissionId).update({
                        'approval_status': 'Rejected',
                        'leader_comment': _commentController.text.trim(),
                        'review_date': FieldValue.serverTimestamp(),
                      });
                      // change task to pending
                      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'status': 'Pending'});
                      _updateProjectProgress();
                      if (mounted) navigator.pop();
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      // change submission to approve
                      await FirebaseFirestore.instance.collection('submissions').doc(submissionId).update({
                        'approval_status': 'Approved',
                        'leader_comment': _commentController.text.trim(),
                        'review_date': FieldValue.serverTimestamp(),
                      });
                      // change task to complete
                      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'status': 'Completed'});
                      _updateProjectProgress();
                      if (mounted) navigator.pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProjectProgress() async {
    final snap = await FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: widget.projectId).get();
    
    double progress = 0.0;
    String status = 'Not started';

    if (snap.docs.isNotEmpty) {
      final int done = snap.docs.where((d) => (d.data() as Map)['status'] == 'Completed').length;
      progress = (done / snap.docs.length) * 100;
      
      if (progress == 100.0) {
        status = 'Completed';
      } else if (progress > 0.0) {
        status = 'In progress';
      } else {
        status = 'Not started';
      }
    }

    await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).update({
      'progress': progress,
      'status': status,
    });
  }

  Future<void> _claimTask(String taskId, int limit) async {
    final myTasks = await FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: widget.projectId).where('user_id', isEqualTo: _currentUserId).get();
    if (myTasks.docs.length >= limit) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wait! You have reached your limit for this project.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'user_id': _currentUserId});
    _updateProjectProgress();
  }

  Future<void> _unclaimTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'user_id': null});
    _updateProjectProgress();
  }

  Widget _buildSheetLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.1));
  }

  void _confirmLeaveProject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Project?'),
        content: const Text('Are you sure you want to leave this project? All your claimed tasks will be returned to the pool.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              // remove all task from this user
              final tasks = await FirebaseFirestore.instance
                  .collection('tasks')
                  .where('project_id', isEqualTo: widget.projectId)
                  .where('user_id', isEqualTo: _currentUserId)
                  .get();
              
              for (var doc in tasks.docs) {
                await doc.reference.update({'user_id': null});
              }

              // remove user from project member
              await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).update({
                'members': FieldValue.arrayRemove([_currentUserId])
              });

              // delete user from member collection
              final memberDoc = await FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('members')
                  .where('user_id', isEqualTo: _currentUserId)
                  .get();
              
              for (var doc in memberDoc.docs) {
                await doc.reference.delete();
              }

              _updateProjectProgress();
              
              if (mounted) {
                navigator.pop();
                Navigator.of(context).pop(); // go back
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have left the project.')));
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').doc(widget.projectId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final project = snapshot.data!.data() as Map<String, dynamic>;
        final bool isLeader = project['team_leader_id'] == _currentUserId;
        
        return Scaffold(
          backgroundColor: const Color(0xFFFCF8FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(project['project_name'] ?? 'Project', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854))),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF4B0AAA)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectChatScreen(
                      projectId: widget.projectId,
                      projectName: project['project_name'] ?? 'Project',
                    ),
                  ),
                ),
              ),
              if (isLeader) 
                IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF4B0AAA)), onPressed: () => _showEditProjectSheet(project))
              else
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
                  onPressed: _confirmLeaveProject,
                  tooltip: 'Leave Project',
                ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(project),
                  _buildInvitationCard(project['join_code'] ?? 'N/A', isLeader),
                  const SizedBox(height: 24),
                  
                  _buildTeamPerformanceSection(),
                  
                  const SizedBox(height: 24),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _getMembersStream(),
                    builder: (context, mSnap) {
                      final members = mSnap.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TEAM MEMBERS (${members.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5C5468))),
                          const SizedBox(height: 8),
                          _buildMembersList(members, isLeader),
                          const SizedBox(height: 24),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('TASK POOL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5C5468))),
                            if (isLeader) ElevatedButton.icon(onPressed: _showAddTaskSheet, icon: const Icon(Icons.add, size: 16), label: const Text('Add Task'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B0AAA), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
                          ]),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 12),
                  _buildTaskList(isLeader, project['task_limit'] ?? 5),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildTeamPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TEAM PERFORMANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: widget.projectId).snapshots(),
          builder: (context, taskSnap) {
            if (!taskSnap.hasData) return const SizedBox();
            final allTasks = taskSnap.data!.docs;

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getMembersStream(),
              builder: (context, memberSnap) {
                if (!memberSnap.hasData) return const SizedBox();
                final members = memberSnap.data!;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E2E4))),
                  child: Column(
                    children: members.map((member) {
                      final memberTasks = allTasks.where((doc) => (doc.data() as Map)['user_id'] == member['user_id']).toList();
                      final completedCount = memberTasks.where((doc) => (doc.data() as Map)['status'] == 'Completed').length;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text(member['name'] ?? 'Member', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('$completedCount/${memberTasks.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4B0AAA))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> p) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4B0AAA)]), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p['project_name'] ?? 'Project', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(
          p['description'] ?? 'No description provided.',
          style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildHeaderBadge('Status: ${p['status']}'),
            const SizedBox(width: 8),
            _buildHeaderBadge('Priority: ${p['priority']}'),
          ],
        ),
      ]),
    );
  }

  Widget _buildHeaderBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInvitationCard(String code, bool isLeader) {
    return Container(
      padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E2E4))),
      child: Row(children: [
        const Icon(Icons.qr_code_2, color: Color(0xFF4B0AAA)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('JOIN CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9E95A8))), Text(code, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF4B0AAA), letterSpacing: 1.5))])),
        if (isLeader) TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: code)), icon: const Icon(Icons.copy, size: 16), label: const Text('Copy'), style: TextButton.styleFrom(foregroundColor: const Color(0xFF4B0AAA))),
      ]),
    );
  }

  Widget _buildMembersList(List members, bool isLeader) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E2E4))),
      child: ListView.separated(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: members.length,
        separatorBuilder: (c, i) => const Divider(height: 1),
        itemBuilder: (c, i) {
          final m = members[i];
          final bool isTLeader = m['member_role'] == 'Team Leader';
          final String profilePic = m['profile_picture'] ?? '';
          ImageProvider? memberImage;
          if (profilePic.isNotEmpty) memberImage = profilePic.startsWith('assets/') ? AssetImage(profilePic) : NetworkImage(profilePic) as ImageProvider;
          return ListTile(
            leading: CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF3EEFC), backgroundImage: memberImage, child: memberImage == null ? const Icon(Icons.person, color: Color(0xFF4B0AAA), size: 18) : null),
            title: Text(m['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: isTLeader ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEADDFF), borderRadius: BorderRadius.circular(8)), child: const Text('LEAD', style: TextStyle(color: Color(0xFF4B0AAA), fontSize: 9, fontWeight: FontWeight.w800))) : null,
          );
        },
      ),
    );
  }

  Widget _buildTaskList(bool isLeader, int limit) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: widget.projectId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final tasks = snap.data!.docs;
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: tasks.length,
          itemBuilder: (context, index) {
            final doc = tasks[index];
            final t = doc.data() as Map<String, dynamic>;
            final String status = t['status'] ?? 'Pending';
            final String? assignedUserId = t['user_id'];
            final bool isMine = assignedUserId == _currentUserId;

            return Card(
              margin: const EdgeInsets.only(bottom: 12), color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isMine ? const Color(0xFF4B0AAA) : const Color(0xFFE4E2E4))),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (t['difficulty_level'] == 'Hard' ? Colors.redAccent : (t['difficulty_level'] == 'Medium' ? Colors.orange : Colors.green)).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (t['difficulty_level'] ?? 'Medium').toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: t['difficulty_level'] == 'Hard' ? Colors.redAccent : (t['difficulty_level'] == 'Medium' ? Colors.orange : Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t['task_name'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
                  if (isLeader)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDeleteTask(doc.id, t['task_name'] ?? 'Task'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ]),
                const SizedBox(height: 8),
                Text(t['description'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF5C5468))),
                const Divider(),
                if (status == 'Pending' && assignedUserId == null)
                  ElevatedButton(onPressed: () => _claimTask(doc.id, limit), child: const Text('Claim Task'))
                else if (assignedUserId != null)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(assignedUserId).get(),
                    builder: (context, uSnap) {
                      if (!uSnap.hasData) return const SizedBox();
                      final userData = uSnap.data!.data() as Map<String, dynamic>;
                      final String pic = userData['profile_picture'] ?? '';
                      ImageProvider? img = pic.isNotEmpty ? (pic.startsWith('assets') ? AssetImage(pic) : NetworkImage(pic)) as ImageProvider : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 10, backgroundImage: img, child: img == null ? const Icon(Icons.person, size: 10) : null),
                              const SizedBox(width: 8),
                              Text(userData['name'] ?? 'Member', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5C5468))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isMine && status == 'Pending')
                            Column(
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('submissions').where('task_id', isEqualTo: doc.id).where('approval_status', isEqualTo: 'Rejected').orderBy('submission_date', descending: true).limit(1).snapshots(),
                                  builder: (context, sSnap) {
                                    if (sSnap.hasData && sSnap.data!.docs.isNotEmpty) {
                                      final sub = sSnap.data!.docs.first;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Rejected! Check Feedback:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                                            Text(sub['leader_comment'] ?? '', style: const TextStyle(fontSize: 11)),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  }
                                ),
                                Row(
                                  children: [
                                    TextButton(onPressed: () => _unclaimTask(doc.id), child: const Text('Unclaim', style: TextStyle(color: Colors.redAccent))),
                                    const Spacer(),
                                    ElevatedButton(onPressed: () => _showSubmitProofSheet(doc.id), child: const Text('Submit Work')),
                                  ],
                                ),
                              ],
                            )
                          else if (isLeader && status == 'In Review')
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('submissions').where('task_id', isEqualTo: doc.id).where('approval_status', isEqualTo: 'Pending').snapshots(),
                              builder: (context, sSnap) {
                                if (!sSnap.hasData || sSnap.data!.docs.isEmpty) return const Text('Loading sub...');
                                final subDoc = sSnap.data!.docs.first;
                                return ElevatedButton(onPressed: () => _showReviewSheet(doc.id, subDoc.data() as Map<String, dynamic>, subDoc.id), child: const Text('Review Work'));
                              }
                            )
                          else if (status == 'Completed')
                            const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 4), Text('Completed & Approved', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))])
                          else
                            Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B0AAA), fontSize: 12)),
                        ],
                      );
                    }
                  )
                else
                  Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B0AAA))),
              ])),
            );
          },
        );
      }
    );
  }
}
