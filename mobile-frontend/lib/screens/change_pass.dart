import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;

  ChangePasswordScreen({required this.email});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = "";
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final String password = _passwordController.text.trim();
    if (password.isEmpty || password.length < 6) {
      setState(() {
        _errorMessage = "Password must be at least 6 characters long.";
        _isLoading = false;
      });
      return;
    }

    final supabase = Supabase.instance.client;
    try {
      //Update the user's password
      await supabase.auth.updateUser(UserAttributes(password: password));

      //Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password updated successfully! Please log in.")),
      );

      //Navigate back to login screen (Assuming you have a LoginScreen)
      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Change Password")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Enter a new password for ${widget.email}."),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            _errorMessage.isNotEmpty
                ? Text(_errorMessage, style: TextStyle(color: Colors.red))
                : Container(),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updatePassword,
                    child: Text("Update Password"),
                  ),
          ],
        ),
      ),
    );
  }
}
