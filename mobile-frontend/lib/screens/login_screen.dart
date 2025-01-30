import 'package:demo/screens/map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'forgot_pass_screen.dart'; // Import the Forgot Password screen
import 'landing_screen.dart';
import 'signup_screen.dart'; 

class LoginScreen extends StatefulWidget {
  final VoidCallback showSignUpScreen;
  const LoginScreen({Key? key, required this.showSignUpScreen}): super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

Future logIn() async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );
  } on FirebaseAuthException catch (e) {
    String errorMessage;

    // Map Firebase error codes to user-friendly messages
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found with this email address.';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password. Please try again.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address entered is invalid.';
        break;
      case 'user-disabled':
        errorMessage = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many login attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Email/password sign-in is not enabled.';
        break;
      default:
        errorMessage = 'An unexpected error occurred: ${e.message}';
    }

    // Show error message in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}



  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // State variables
  bool _isRememberMeChecked = false; // Tracks "Remember Me" checkbox state
  bool _isPasswordVisible = false; // Tracks password visibility

  @override
  Widget build(BuildContext context) {
    return Container(
      // Gradient background
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF004D40), // Dark green shade (top)
            Color(0xFFD1EEDD), // Light green shade (bottom)
          ],
        ),
      ),
      constraints: BoxConstraints.expand(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),

                // Back Arrow Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios, // Minimal back arrow
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LandingScreen()),
                      );
                    },
                  ),
                ),

                SizedBox(height: 40),

                // Welcome Text
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Hey! Good to see you again",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 40),

                // Email Field
                Text("Email", style: TextStyle(fontSize: 16, color: Colors.white)),
                SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade300,
                    border: InputBorder.none, // Remove border
                    hintText: 'Email',
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    // Rounded edges
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Password Field with Eye Icon
                Text("Password", style: TextStyle(fontSize: 16, color: Colors.white)),
                SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // Show/hide password
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility // Eye open icon
                            : Icons.visibility_off, // Eye closed icon
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade300,
                    border: InputBorder.none, // Remove border
                    hintText: 'Password',
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    // Rounded edges
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Remember me and Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Transform.scale(
                          scale: 1.5,
                          child: Checkbox(
                            value: _isRememberMeChecked, // Checkbox state
                            onChanged: (value) {
                              setState(() {
                                _isRememberMeChecked = value ?? false;
                              });
                            },
                            activeColor: Colors.teal,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: Color(0xFF004D40),
                              width: 2,
                            ),
                          ),
                        ),
                        Text("Remember me", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                      child: Text("Forgot Password?",
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.none, // No underline
                          )),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Google Login
                Center(
                  child: Column(
                    children: [
                      Text("Or login using", style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          print("Google Login Pressed");
                        },
                        icon: Image.asset('assets/google_logo.png', width: 24),
                        label: Text(
                          "Log in using Google",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

               // Log In Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade900, 
                      minimumSize: Size(double.infinity, 50), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), 
                      ),
                    ),
                    onPressed: logIn, 
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16, 
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Sign Up Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?  ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.showSignUpScreen,
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
