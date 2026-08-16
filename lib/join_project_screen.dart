import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinProjectScreen extends StatefulWidget {
  const JoinProjectScreen({super.key});

  @override
  State<JoinProjectScreen> createState() => _JoinProjectScreenState();
}

class _JoinProjectScreenState extends State<JoinProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    final String code = _codeController.text.trim().toUpperCase();
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // find project by code
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('join_code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid invitation code. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        DocumentSnapshot projectDoc = querySnapshot.docs.first;
        String projectId = projectDoc.id;
        List members = (projectDoc.data() as Map<String, dynamic>)['members'] ?? [];

        if (members.contains(user.uid)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are already a member of this project.'),
                backgroundColor: Colors.amber,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // add user to project member
          await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
            'members': FieldValue.arrayUnion([user.uid]),
          });

          // add to member collection
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .collection('members')
              .doc(user.uid)
              .set({
            'project_id': projectId,
            'user_id': user.uid,
            'join_date': FieldValue.serverTimestamp(),
            'member_role': 'Member',
          });

          // add project id to user
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'project_ids': FieldValue.arrayUnion([projectId]),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Joined workspace successfully!'),
                backgroundColor: Color(0xFF4B0AAA),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1B1B1D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join via Invitation',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E0854),
            fontSize: 20.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20.0),
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: const Color(0xFFE4E2E4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 16.0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3EEFC),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_add_rounded,
                                color: Color(0xFF4B0AAA),
                                size: 40.0,
                              ),
                            ),
                            const SizedBox(height: 18.0),
                            const Text(
                              'Enter Invitation Code',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E0854),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            const Text(
                              'Ask your team leader for the 6-character project invitation code to join their workspace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF5C5468),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            TextFormField(
                              controller: _codeController,
                              style: const TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6.0,
                                color: Color(0xFF4B0AAA),
                              ),
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 6,
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'ABCDEF',
                                hintStyle: const TextStyle(
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6.0,
                                  color: Color(0xFFE4E2E4),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFCF8FB),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE4E2E4),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE4E2E4),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4B0AAA),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter invitation code.';
                                }
                                if (value.trim().length != 6) {
                                  return 'Code must be exactly 6 characters.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      SizedBox(
                        width: double.infinity,
                        height: 52.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B0AAA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              else ...[
                                const Icon(Icons.login_rounded, size: 18.0),
                                const SizedBox(width: 8.0),
                                const Text(
                                  'Join Workspace',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      SizedBox(
                        width: double.infinity,
                        height: 52.0,
                        child: OutlinedButton(
                          onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5C5468),
                            side: const BorderSide(
                              color: Color(0xFFE4E2E4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
