import 'package:demo/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/signup_screen.dart';
import 'package:demo/screens/map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Get auth service 
  final authService = AuthScreen(); 

  // Email and password controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Login button pressed
  void login() async {
    // Prepare data
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Call login function
    try {
      await authService.signInWithEmailPassword(email, password);

      //if login is successful, the user will be redirected to the map screen
      if (mounted){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
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

  // Dispose controllers to avoid memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: SingleChildScrollView( // Prevents overflow on smaller screens
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50), // Adds some top spacing

              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // Hide password text
              ),
              const SizedBox(height: 20),

              // Login button
              ElevatedButton(
                onPressed: login,
                child: const Text("Login"),
              ),
              const SizedBox(height: 20),

              // Navigate to sign-up page
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                ),
                child: const Text(
                  "Don't have an account? Sign up here",
                  style: TextStyle(
                    color: Colors.blue, 
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 50), // Adds some bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}
