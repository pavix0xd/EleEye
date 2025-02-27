import 'package:demo/screens/auth_screen.dart';
import 'package:demo/screens/forgot_pass_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/signup_screen.dart';
import 'package:demo/screens/map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthScreen();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isButtonPressed = false;

  void login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await authService.signInWithEmailPassword(email, password);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      constraints: const BoxConstraints.expand(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "Hey! Good to see you again",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),

              // Email field
              _buildTextField("Email", _emailController),
              const SizedBox(height: 20),

              // Password field
              _buildTextField("Password", _passwordController, isPassword: true),
              const SizedBox(height: 10),

              // Forgot password link with press effect
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTapDown: (_) => setState(() {}),
                  onTapUp: (_) => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                  ),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Login button with press effect
              Center(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isButtonPressed = true),
                  onTapUp: (_) {
                    setState(() => _isButtonPressed = false);
                    login();
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
                        'Log In',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Sign up link with press effect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?  ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  GestureDetector(
                    onTapDown: (_) => setState(() {}),
                    onTapUp: (_) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TextField with focus effect
  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 8),
        Focus(
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return TextField(
                controller: controller,
                obscureText: isPassword && !_isPasswordVisible,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isFocused ? Colors.white : Colors.white.withOpacity(0.1),
                  hintText: label,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
