import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

void _launchPhoneDialer(String phoneNumber) async {
  final Uri url = Uri.parse("tel:$phoneNumber");
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    debugPrint("Could not launch $url");
  }
}

void _launchEmailClient(String email) async {
  final Uri url = Uri.parse("mailto:$email");
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    debugPrint("Could not launch $url");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle("Frequently Asked Questions"),
          _buildFAQItem("How do I reset my password?", 
          "Go to the login screen and tap on 'Forgot Password'. You'll prompted to enter your email. Enter your email and check your inbox. You'll receive an email with a link. Click that and You will be redirected to the page that you can change your password to a new one."),
          _buildFAQItem("How can I contact support?",
           "You can reach out to us via email at eleeye17@gmail.com or call our helpline."),
          _buildFAQItem("How do I update the app?",
           "Visit the App store or Google Play store and check for updates under 'My Apps'."),
          
          const SizedBox(height: 20),
          _buildSectionTitle("Contact Support"),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text("Email Us"),
            subtitle: const Text("eleeye17@gmail.com"),
            onTap: () => _launchEmailClient("eleeye17@gmail.com"),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text("Call Us"),
            subtitle: const Text("+94 71 491 9945"),
            onTap: () => _launchPhoneDialer("+94714919945"),
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Troubleshooting"),
          _buildFAQItem("App is not responding", "Try restarting the app. If the issue persists, reinstall the app from the store."),
          _buildFAQItem("Login issues", "Ensure you are using the correct credentials. If needed, reset your password."),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(answer),
        ),
      ],
    );
  }
}
