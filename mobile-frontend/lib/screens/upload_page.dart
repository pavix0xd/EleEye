import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;
  final String bucketName = 'avatars';

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final fileExt = _image!.path.split('.').last;
      final fileName = "$userId/profile.$fileExt";

      await supabase.storage.from(bucketName).upload(fileName, _image!);
      final imageUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);

      await supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);

      if (mounted) {
        Navigator.pop(context, imageUrl);
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Profile Picture")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: _pickImage, child: const Text("Pick Image")),
            ElevatedButton(onPressed: _uploadImage, child: const Text("Upload")),
          ],
        ),
      ),
    );
  }
}
