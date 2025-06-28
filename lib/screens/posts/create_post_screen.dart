import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/post/post_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart' as gloryfit_user;
import 'package:image_picker/image_picker.dart';

import 'package:cached_network_image/cached_network_image.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  bool _isQuestion = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter some content for your post.');
      return;
    }

    final userState = context.read<UserCubit>().state;
    gloryfit_user.UserModel? currentUser;

    if (userState is UserLoaded) {
      currentUser = userState.user;
    } else if (userState is UserLoadedWithInProgressWorkout) {
      currentUser = userState.user;
    }

    if (currentUser == null) {
      _showErrorSnackBar('Could not verify user. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // **FIXED**: The parameter name is now 'images' and it correctly passes a list.
      await context.read<PostCubit>().createPost(
            content: _contentController.text.trim(),
            author: currentUser,
            isQuestion: _isQuestion,
            images: _imageFile == null ? [] : [_imageFile!],
          );
      
      if (mounted) {
         _showSuccessSnackBar('Post created successfully!');
         Navigator.pop(context);
      }

    } catch (e) {
       if (mounted) _showErrorSnackBar('Error creating post: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
     if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade600,
    ));
  }

   void _showSuccessSnackBar(String message) {
     if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade600,
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)))
                : TextButton(
                    onPressed: _submitPost,
                    child: Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserInfoHeader(),
            const SizedBox(height: 16),
            _buildTextField(),
            const SizedBox(height: 20),
            if (_imageFile != null) _buildImagePreview(),
            const Divider(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoaded || state is UserLoadedWithInProgressWorkout) {
          final user = (state as dynamic).user as gloryfit_user.UserModel;
          return Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: user.photoURL != null
                    ? CachedNetworkImageProvider(user.photoURL!)
                    : null,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(width: 12),
              Text(
                user.displayName ?? 'New Post',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _contentController,
      decoration: const InputDecoration(
        hintText: "What's on your mind?",
        border: InputBorder.none,
      ),
      maxLines: null, // Allows for multiline input
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 18, height: 1.5),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.network(_imageFile!.path, fit: BoxFit.cover)
              : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  _imageFile = null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
         ListTile(
          leading: Icon(Icons.photo_library, color: Colors.green[600]),
          title: const Text('Add Photo'),
          onTap: _pickImage,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Ask a Question'),
          subtitle: const Text('Your post will be marked as a Q&A.'),
          value: _isQuestion,
          onChanged: (bool value) {
            setState(() {
              _isQuestion = value;
            });
          },
          secondary: Icon(Icons.help_outline, color: Colors.amber[700]),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
