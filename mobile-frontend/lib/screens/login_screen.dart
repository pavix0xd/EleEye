import 'package:eleeye/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eleeye/api/firebase_api.dart';
import 'package:eleeye/screens/forgot_pass_screen.dart';
import 'package:eleeye/screens/signup_screen.dart';
import 'package:eleeye/screens/bottom_nav_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthScreen authScreen = AuthScreen(); // Replaced AuthScreen with AuthService
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isButtonPressed = false;
  bool _isLoading = false;

  Future<void> login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      HapticFeedback.vibrate();
      _showErrorSnackbar("Please fill in all fields.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authScreen.signInWithEmailPassword(email, password);
      await FirebaseApi().initNotifications(); // Register FCM token after login

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      }
    } catch (e) {
      HapticFeedback.vibrate();
      _showErrorSnackbar(_getUserFriendlyError(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getUserFriendlyError(String error) {
    if (error.contains("invalid-email")) {
      return "Invalid email format. Please enter a valid email.";
    } else if (error.contains("user-not-found")) {
      return "User not found. Please check your email and try again.";
    } else if (error.contains("wrong-password")) {
      return "Incorrect password. Please try again.";
    } else if (error.contains("network-request-failed")) {
      return "Network error. Check your internet connection.";
    } else {
      return "Something went wrong. Please try again.";
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              _buildAnimatedTitle(),
              const SizedBox(height: 40),
              _buildTextField("Email", _emailController, isEmail: true),
              const SizedBox(height: 20),
              _buildTextField("Password", _passwordController, isPassword: true),
              const SizedBox(height: 10),
              _buildForgotPassword(),
              const SizedBox(height: 30),
              _buildLoginButton(),
              const SizedBox(height: 30),
              _buildSignupOption(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Welcome Back",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            "Hey! Good to see you again",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
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
                obscureText: isPassword && !_isPasswordVisible,
                keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
                textInputAction: TextInputAction.next,
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
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        )
                      : null,
                ),
                style: const TextStyle(color: Colors.black),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen())),
        child: const Text("Forgot Password?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
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
          gradient: LinearGradient(
            colors: _isButtonPressed ? [Colors.teal.shade700, Colors.teal.shade800] : [Colors.teal.shade900, Colors.teal.shade700],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Log In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildSignupOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
          child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
