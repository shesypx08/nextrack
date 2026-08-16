import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  Future<void> _register() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) { _showError('Please enter your full name.'); return; }
    if (email.isEmpty || !email.contains('@')) { _showError('Please enter a valid email address.'); return; }
    if (username.isEmpty) { _showError('Please enter a username.'); return; }
    if (password.length < 6) { _showError('Password must be at least 6 characters.'); return; }
    if (confirmPassword != password) { _showError('Passwords do not match.'); return; }
    if (!_agreeToTerms) { _showError('Please agree to the terms of service.'); return; }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);


      // create user in database
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'user_id': userCredential.user!.uid,
        'name': name,
        'username': username,
        'email': email
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, $name! ✨'), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF4B0AAA)));
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'An error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B1B1D)), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                const Text('NEXTRACK', style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w800, color: Color(0xFF2E0854), letterSpacing: 2.0)),
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Account', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24.0),
                      _buildTextField(_nameController, 'FULL NAME', Icons.person_outline),
                      const SizedBox(height: 20.0),
                      _buildTextField(_emailController, 'EMAIL ADDRESS', Icons.email_outlined),
                      const SizedBox(height: 20.0),
                      _buildTextField(_usernameController, 'USERNAME', Icons.person_outline),
                      const SizedBox(height: 20.0),
                      _buildPasswordField(_passwordController, 'PASSWORD', _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
                      const SizedBox(height: 20.0),
                      _buildPasswordField(_confirmPasswordController, 'CONFIRM PASSWORD', _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Checkbox(value: _agreeToTerms, activeColor: const Color(0xFF4B0AAA), onChanged: (val) => setState(() => _agreeToTerms = val ?? false)),
                          const Expanded(child: Text('I agree to the Terms & Privacy Policy', style: TextStyle(fontSize: 12.0))),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        width: double.infinity,
                        height: 52.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B0AAA), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0))),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF5C5468))),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          decoration: InputDecoration(prefixIcon: Icon(icon, size: 19.0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0))),
        ),
      ],
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF5C5468))),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline, size: 19.0), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19.0), onPressed: toggle), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0))),
        ),
      ],
    );
  }
}
