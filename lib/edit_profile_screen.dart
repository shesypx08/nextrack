import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedDepartment = 'Computer Science';
  String _profilePictureUrl = '';

  final List<String> _departments = [
    'Computer Science',
    'Design & Product',
    'Business & Management',
    'Engineering & Tech',
    'Humanities & Arts',
    'Science & Math',
    'Others',
  ];

  final List<String> _cuteAssets = [
    'assets/images/blue.jpg',
    'assets/images/brown.jpg',
    'assets/images/green.jpg',
    'assets/images/grey.jpg',
    'assets/images/peace.jpg',
    'assets/images/pink.jpg',
    'assets/images/purple.jpg',
    'assets/images/style.jpg',
    'assets/images/smile.jpg',
    'assets/images/beige style.jpg',
    'assets/images/blue style.jpg',
    'assets/images/denim style.jpg',
    'assets/images/green style.jpg',
    'assets/images/navy style.jpg',
    'assets/images/orange style.jpg',
    'assets/images/pink style.jpg',
    'assets/images/purple style.jpg',
    'assets/images/style 1.jpg',
    'assets/images/style 2.jpg',
    'assets/images/style 3.jpg',
    'assets/images/style 4.jpg',
    'assets/images/style 5.jpg',
    'assets/images/style 6.jpg',
    'assets/images/style 7.jpg',
    'assets/images/style 8.jpg',
    'assets/images/style 9.jpg',
    'assets/images/girl 1.jpg',
    'assets/images/girl 2.jpg',
    'assets/images/girl 3.jpg',
    'assets/images/girl 4.jpg',
    'assets/images/girl 5.jpg',
    'assets/images/girl 6.jpg',
    'assets/images/girl 7.jpg',
    'assets/images/girl 8.jpg',

  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['name'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _selectedDepartment = data['department'] ?? 'Computer Science';
          _profilePictureUrl = data['profile_picture'] ?? '';
        });
      } else {
        setState(() {
          _emailController.text = user.email ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF4B0AAA)),
                  SizedBox(width: 12),
                  Text(
                    'Pick your Profile Icon',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: Color(0xFF2E0854)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: _cuteAssets.length,
                  itemBuilder: (context, index) {
                    final String assetPath = _cuteAssets[index];
                    final bool isSelected = _profilePictureUrl == assetPath;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _profilePictureUrl = assetPath);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4B0AAA) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(assetPath),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_profilePictureUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _profilePictureUrl = '');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    label: const Text(
                      'Remove profile picture',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _fullNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
          'department': _selectedDepartment,
          'profile_picture': _profilePictureUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! ✨'),
              backgroundColor: Color(0xFF4B0AAA),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B1B1D)), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854))),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showAvatarPicker,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFEADDFF), width: 4.0),
                                  ),
                                  child: CircleAvatar(
                                    radius: 56.0,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _profilePictureUrl.isNotEmpty && _profilePictureUrl.startsWith('assets') 
                                      ? AssetImage(_profilePictureUrl)
                                      : (_profilePictureUrl.isNotEmpty ? NetworkImage(_profilePictureUrl) as ImageProvider : null),
                                    child: _profilePictureUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Color(0xFF4B0AAA), shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _showAvatarPicker,
                            child: const Text(
                              'Edit profile picture',
                              style: TextStyle(
                                color: Color(0xFF4B0AAA),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLabel('FULL NAME'),
                    TextFormField(controller: _fullNameController),
                    const SizedBox(height: 20),
                    _buildLabel('USERNAME'),
                    TextFormField(controller: _usernameController),
                    const SizedBox(height: 20),
                    _buildLabel('BIO'),
                    TextFormField(controller: _bioController, maxLines: 3),
                    const SizedBox(height: 20),
                    _buildLabel('DEPARTMENT'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDepartment,
                      items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setState(() => _selectedDepartment = v!),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B0AAA), foregroundColor: Colors.white),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF5C5468))));
}
