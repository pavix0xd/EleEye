import 'package:eleeye/screens/auth_screen.dart';
import 'package:eleeye/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthScreen authService = AuthScreen();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isButtonPressed = false;
  String? _passwordErrorText;

  void signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await authService.signUpWithEmailPassword(email, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Redirecting to login...'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF004D40), Color(0xFFD1EEDD)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                const Text(
                  "Hello there!",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  "Register below with your details.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _buildTextField("Email", _emailController, isEmail: true),
                const SizedBox(height: 20),
                _buildTextField("Password", _passwordController, isPassword: true),
                const SizedBox(height: 20),
                _buildTextField("Confirm Password", _confirmPasswordController, isPassword: true),
                if (_passwordErrorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 8),
                    child: Text(_passwordErrorText!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 30),
                _buildSignupButton(),
                const SizedBox(height: 30),
                _buildLoginPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false, bool isEmail = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
      const SizedBox(height: 8),
      Focus(
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return TextFormField(
              controller: controller,
              obscureText: isPassword && (label == "Password" ? !_isPasswordVisible : !_isConfirmPasswordVisible),
              keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field cannot be empty';
                }
                if (isEmail && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                if (isPassword && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                if (label == "Confirm Password" && value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: isFocused ? Colors.white : Colors.white.withOpacity(0.1),
                hintText: label,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          label == "Password" ? (_isPasswordVisible ? Icons.visibility : Icons.visibility_off) 
                                             : (_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          color: Colors.grey.shade700,
                        ),
                        onPressed: () => setState(() {
                          if (label == "Password") {
                            _isPasswordVisible = !_isPasswordVisible;
                          } else {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          }
                        }),
                      )
                    : null,
              ),
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.black,
            );
          },
        ),
      ),
    ],
  );
}



  Widget _buildSignupButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isButtonPressed = true),
        onTapUp: (_) {
          setState(() => _isButtonPressed = false);
          HapticFeedback.lightImpact(); // Haptic feedback
          signUp();
        },
        onTapCancel: () => setState(() => _isButtonPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: _isButtonPressed ? Colors.teal.shade700 : Colors.teal.shade900,
            borderRadius: BorderRadius.circular(30),
            boxShadow: _isButtonPressed
                ? [
                    BoxShadow(
                      color: Colors.teal.shade700.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: const Center(
            child: Text(
              'Sign Up',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?  ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          child: const Text("Log In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
