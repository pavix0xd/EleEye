import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _errorMessage = "";
  bool _isLoading = false;

  // Your app's Supabase URL
  final String appUrl = "https://yourapp.supabase.co";

  Future<void> _verifyUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = "Please enter your email.";
        _isLoading = false;
      });
      return;
    }

    final supabase = Supabase.instance.client;
    try {
      // Send the password reset request to Supabase
      await supabase.auth.resetPasswordForEmail(email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent! Check your inbox.")),
      );

      // Optional: Attempt to send additional email via Brevo
      final bool emailSent = await sendResetEmailToUser(email, "$appUrl/auth/v1/reset-password");

      if (!emailSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Supabase reset email sent, but custom email failed.")),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to send the email via Brevo (Sendinblue)
  Future<bool> sendResetEmailToUser(String email, String resetUrl) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': 'YOUR_BREVO_API_KEY', // Replace with actual API key
        },
        body: jsonEncode({
          'sender': {'email': 'your_email@example.com'}, // Replace with sender email
          'to': [{'email': email}],
          'subject': 'Reset Password',
          'htmlContent': '''
            <p>Click the link below to reset your password:</p>
            <p><a href="$resetUrl" target="_blank">Reset Password</a></p>
          ''',
        }),
      );

      if (response.statusCode == 200) {
        print("Custom email sent successfully!");
        return true;
      } else {
        print("Failed to send custom email: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Failed to send custom email: $error");
      return false;
    }
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Forgot Password", style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Enter your email to reset your password.",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Email Input Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Email"),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 10),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 20),

              // Reset Button
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade900,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: _verifyUser,
                      child: const Text(
                        "Reset Password",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade300,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
    );
  }
}
