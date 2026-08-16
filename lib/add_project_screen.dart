import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _taskLimitController = TextEditingController(text: '5');

  String _selectedPriority = 'Medium';
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _selectedDeadline == null) return;
    setState(() => _isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String joinCode = _generateJoinCode();
        
        DocumentReference projectRef = await FirebaseFirestore.instance.collection('projects').add({
          'project_name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'deadline': _selectedDeadline,
          'priority': _selectedPriority,
          'status': 'Not started', 
          'task_limit': int.parse(_taskLimitController.text.trim()),
          'join_code': joinCode,
          'team_leader_id': user.uid,
          'progress': 0.0,
          'created_at': FieldValue.serverTimestamp(),
          'members': [user.uid],
        });

        await projectRef.update({'project_id': projectRef.id});

        await projectRef.collection('members').doc(user.uid).set({
          'project_id': projectRef.id,
          'user_id': user.uid,
          'join_date': FieldValue.serverTimestamp(),
          'member_role': 'Team Leader',
        });

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'project_ids': FieldValue.arrayUnion([projectRef.id]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project Created! Code: $joinCode'), backgroundColor: const Color(0xFF4B0AAA)));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Create Project', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('PROJECT NAME'),
              TextFormField(controller: _nameController, decoration: InputDecoration(hintText: 'e.g. Mobile App Design', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E4))))),
              const SizedBox(height: 24),
              
              _buildLabel('DESCRIPTION'),
              TextFormField(controller: _descController, maxLines: 3, decoration: InputDecoration(hintText: 'Enter project details...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E4))))),
              const SizedBox(height: 24),

              _buildLabel('PRIORITY LEVEL'),
              _buildPriorityButton('High', Colors.redAccent),
              const SizedBox(height: 10),
              _buildPriorityButton('Medium', Colors.orange),
              const SizedBox(height: 10),
              _buildPriorityButton('Low', Colors.green),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('TASK LIMIT'),
                        TextFormField(controller: _taskLimitController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('DEADLINE'),
                        InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (picked != null) setState(() => _selectedDeadline = picked);
                          },
                          child: Container(
                            height: 58,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.centerLeft,
                            child: Text(_selectedDeadline == null ? 'Select Date' : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}', style: TextStyle(color: _selectedDeadline == null ? Colors.grey : Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEADDFF)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Color(0xFF4B0AAA)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Project status will update automatically based on task progress.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF4B0AAA), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B0AAA), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String level, Color color) {
    bool isSelected = _selectedPriority == level;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedPriority = level),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.transparent,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          level.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.1)));
  }
}
