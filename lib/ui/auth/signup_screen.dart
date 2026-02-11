import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../services/push_notification_service.dart';
import 'login_screen.dart';

class StitchSignupScreen extends StatefulWidget {
  const StitchSignupScreen({super.key});

  @override
  State<StitchSignupScreen> createState() => _StitchSignupScreenState();
}

class _StitchSignupScreenState extends State<StitchSignupScreen> {
  // Colors from Tailwind config
  static const Color primary = Color(0xFF2bee6c);
  static const Color backgroundDark = Color(0xFF0a0f0b);
  static const Color fieldDark = Color(0xFF1a1f1b);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Added confirm password
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> signupUser(
      BuildContext context,
      String email,
      String password,
  ) async {
    setState(() => _isLoading = true);
    try {
      // Validate confirm password
      if (_passwordController.text != _confirmPasswordController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Passwords do not match")),
          );
        }
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // Update display name if provided
      if (userCredential.user != null) {
        // Update display name
        if (_nameController.text.isNotEmpty) {
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
        }

        // Create user document in Firestore
        await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'User',
            'email': email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      }

      // Save FCM Token
      await PushNotificationService.saveTokenToFirestore();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account already exists. Please login")),
          );
        }
      } else {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup failed: ${e.message}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 24),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Icon(Icons.eco, color: primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'ZeroSpill',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join ZeroSpill and start saving money and reducing food waste today.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Inputs
                _buildLabel('Full Name'),
                _buildTextField(
                  controller: _nameController,
                  icon: Icons.person_outline,
                  hint: 'John Doe',
                ),
                const SizedBox(height: 16),
                
                _buildLabel('Email'),
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.mail_outline,
                  hint: 'your@email.com',
                ),
                const SizedBox(height: 16),
                
                _buildLabel('Password'),
                _buildTextField(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  hint: '••••••••',
                  isPassword: true,
                  isObscure: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),

                _buildLabel('Confirm Password'),
                _buildTextField(
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  hint: '••••••••',
                  isPassword: true,
                  isObscure: _obscurePassword,
                ),
                
                const SizedBox(height: 32),
                
                // Sign Up Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => signupUser(context, _emailController.text, _passwordController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: backgroundDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      shadowColor: primary.withOpacity(0.3),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: backgroundDark)
                      : Text(
                          'Create Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Initial Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          color: primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.3)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.3),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        ),
      ),
    );
  }
}
