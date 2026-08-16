import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      // project info
      {
        'q': 'How do I join a project?',
        'a': 'To join a project, you need a unique 6-digit Join Code provided by your Team Leader. Go to the Projects tab, tap "Join Project", enter the code, and you\'re in!'
      },
      {
        'q': 'How does the Task Pool work?',
        'a': 'The Task Pool is a collection of unassigned duties. Any member can browse the pool and "Claim" tasks they want to work on. Once claimed, the task is assigned to you until submitted.'
      },
      {
        'q': 'Can I change my role in a project?',
        'a': 'Roles are assigned automatically. The person who creates the project is the "Team Leader" (LEAD). Anyone who joins using a code is a "Student Member". Currently, roles cannot be changed manually.'
      },

      // chat info
      {
        'q': 'How do I communicate with my team?',
        'a': 'Every project has a dedicated real-time chat. Tap the chat bubble icon in the top right corner of your project workspace to start collaborating.'
      },
      {
        'q': 'Can I see who else is in my project?',
        'a': 'Yes. The "Team Members" section in the project details screen shows everyone currently working on the project along with their avatars.'
      },
      {
        'q': 'What does the "LEAD" tag mean?',
        'a': 'The "LEAD" tag identifies the Team Leader. This person created the project and has the authority to approve work and manage tasks.'
      },

      // search info
      {
        'q': 'How do I find a specific project or task?',
        'a': 'Use the search bar (magnifying glass icon) at the top of the Projects or Tasks tabs. Simply type the name to filter your list instantly.'
      },
      {
        'q': 'What is the "Urgent Deliverable" on my Home screen?',
        'a': 'Our smart sorting system automatically identifies the project with the nearest upcoming deadline and places it at the top of your dashboard.'
      },

      // task pool
      {
        'q': 'How does the Task Pool work?',
        'a': 'The Task Pool is a collection of unassigned duties. Members can voluntarily "Claim" any task they feel capable of completing.'
      },
      {
        'q': 'What is the Task Limit?',
        'a': 'To ensure fair workload distribution, Leaders can set a limit (e.g., 5 tasks). You cannot claim more tasks until your current ones are approved.'
      },
      {
        'q': 'What are Task Difficulty Levels?',
        'a': 'Tasks are labeled Easy (Green), Medium (Orange), or Hard (Red). This helps you pick tasks that match your current availability and skill level.'
      },
      {
        'q': 'Can I return a task after claiming it?',
        'a': 'Yes. Use the "Unclaim" button. This returns the task to the pool so a different teammate can pick it up if you are no longer able to complete it.'
      },

      // report info
      {
        'q': 'How is my Efficiency Score calculated?',
        'a': 'Your Efficiency Score is a quality metric calculated as: (Total Approved Tasks ÷ Total Tasks you ever Claimed) x 100. This tracks how often you successfully complete work without it being rejected by the Leader.'
      },
      {
        'q': 'How is the Project Progress percentage calculated?',
        'a': 'The progress ring follows a strict logic: (Count of "Approved" tasks ÷ Total tasks in the project pool) x 100. Note: Claimed tasks that are still "Pending" or "In Review" do not count toward progress until the Leader approves them.'
      },
      {
        'q': 'What does the "Task Progress Over Time" graph show?',
        'a': 'This line graph plots your daily productivity. It counts how many of your submissions were marked as "Approved" on specific dates. Each data point on the graph represents one day of successful work.'
      },
      {
        'q': 'How does the "Overall Task Distribution" bar work?',
        'a': 'In the Reports tab, this bar shows the average completion rate of all projects grouped by their status (Not Started, In Progress, or Completed).'
      },

      // device requirement
      {
        'q': 'What are the minimum system requirements?',
        'a': 'NexTrack requires Android 5.0 (Lollipop) or later. Your device should have at least 2GB of RAM and 100MB of free storage space for smooth performance.'
      },
      {
        'q': 'Do I need a constant internet connection?',
        'a': 'Yes. Since NexTrack is a real-time collaborative tool, an active Wi-Fi or Data connection is required to sync chat messages, claim tasks, and update progress charts.'
      },
      {
        'q': 'Does the app require Google Play Services?',
        'a': 'Yes. NexTrack uses Google Firebase for secure authentication and real-time push notifications, which require updated Google Play Services on Android devices.'
      },

      // profile info
      {
        'q': 'How do I change my icon?',
        'a': 'Go to Profile > Edit Profile and tap your current avatar. You can then pick a new character from our gallery.'
      },
      {
        'q': 'What is the "Academic Bio"?',
        'a': 'It is a space for you to list your expertise or current study interests so teammates know your strengths when assigning tasks.'
      },
      {
        'q': 'Is my data safe if I delete my account?',
        'a': 'If you choose "Delete Account," all your personal data and Firestore records are permanently erased. This action requires a safety checkbox confirmation.'
      },

      // support info
      {
        'q': 'What is a Join Code?',
        'a': 'A unique 6-character code generated for every project. Team Leaders share this code to invite specific members to their academic workspace.'
      },
      {
        'q': 'Who can I contact for technical bugs?',
        'a': 'Navigate to Account Settings > Contact Support to send a report directly to our development team.'
      },
    ];

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
          'Help & FAQ',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854)),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return _FAQTile(
            question: faqs[index]['q']!, 
            answer: faqs[index]['a']!,
          );
        },
      ),
    );
  }
}

class _FAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isExpanded ? const Color(0xFF4B0AAA).withValues(alpha: 0.3) : const Color(0xFFE4E2E4)),
        boxShadow: _isExpanded ? [BoxShadow(color: const Color(0xFF4B0AAA).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isExpanded ? const Color(0xFF4B0AAA).withValues(alpha: 0.1) : const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: _isExpanded ? const Color(0xFF4B0AAA) : const Color(0xFF9E95A8),
                size: 18,
              ),
            ),
            title: Text(
              widget.question,
              style: TextStyle(
                fontWeight: _isExpanded ? FontWeight.bold : FontWeight.w600, 
                color: _isExpanded ? const Color(0xFF2E0854) : const Color(0xFF1B1B1D),
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF4B0AAA),
              size: 20,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                widget.answer,
                style: const TextStyle(color: Color(0xFF5C5468), height: 1.6, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
