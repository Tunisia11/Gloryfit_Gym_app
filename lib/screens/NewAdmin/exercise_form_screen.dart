// lib/screens/admin/exercise_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/admin/admin_cubit.dart';
import 'package:gloryfit_version_3/service/exercise_service.dart';
import 'package:image_picker/image_picker.dart';

/// A form for creating a new exercise.
/// Allows admin to input details and upload media files.
class ExerciseFormScreen extends StatefulWidget {
  const ExerciseFormScreen({super.key});

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _musclesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final ExerciseService _exerciseService = ExerciseService();

  XFile? _videoFile;
  XFile? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _musclesController.dispose();
    super.dispose();
  }

  /// Opens the device's gallery to select a video.
  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _videoFile = video);
    }
  }

  /// Opens the device's gallery to select an image.
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  /// Validates the form and submits the data to the ExerciseService.
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // A video is mandatory for every exercise.
      if (_videoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video.'), backgroundColor: Colors.orange));
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Calling the service directly to create the exercise
        await _exerciseService.createExercise(
          name: _nameController.text,
          description: _descriptionController.text,
          targetMuscles: _musclesController.text.split(',').map((e) => e.trim()).toList(),
          videoFile: _videoFile!,
          imageFile: _imageFile,
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise created successfully!'), backgroundColor: Colors.green),
          );
           Navigator.of(context).pop();
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
         }
      } finally {
         if (mounted) {
           setState(() => _isLoading = false);
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Exercise Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'This field is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'This field is required' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                controller: _musclesController,
                decoration: const InputDecoration(labelText: 'Target Muscles (comma-separated)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'This field is required' : null,
              ),
              const SizedBox(height: 24),
              _buildFilePicker(
                label: 'Exercise Video *',
                file: _videoFile,
                onTap: _pickVideo,
                icon: Icons.video_collection,
              ),
              const SizedBox(height: 16),
              _buildFilePicker(
                label: 'Thumbnail Image (Optional)',
                file: _imageFile,
                onTap: _pickImage,
                icon: Icons.photo,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE EXERCISE'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// A reusable widget for displaying a file picker UI.
  Widget _buildFilePicker({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: file == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(icon, color: Colors.grey, size: 40), Text('Select File')],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 30),
                      const SizedBox(width: 8),
                      Expanded(child: Text(file.name, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,)),
                    ],
                  ),
          ),
        )
      ],
    );
  }
}
