// lib/screens/admin/workout_form_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/exercise_model.dart' as ex_model;
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/service/exercise_service.dart';
import 'package:gloryfit_version_3/service/workout_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// A form for creating or editing a workout.
/// Allows admin to set workout metadata and build a list of exercises.
class WorkoutFormScreen extends StatefulWidget {
  final Workout? workout;
  const WorkoutFormScreen({super.key, this.workout});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _trainerNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();

  // Services
  final ExerciseService _exerciseService = ExerciseService();
  final WorkoutService _workoutService = WorkoutService();

  // State variables
  List<ex_model.Exercise>? _allExercises;
  List<WorkoutExercise> _selectedExercises = [];
  WorkoutDifficulty _difficulty = WorkoutDifficulty.intermediate;
  WorkoutType _type = WorkoutType.standard;
  XFile? _imageFile;
  Uint8List? _imageBytes; // **FIX**: To hold image data for web preview
  String? _networkImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllExercises();
    if (widget.workout != null) {
      final w = widget.workout!;
      _nameController.text = w.name;
      _descriptionController.text = w.description;
      _networkImageUrl = w.imageUrl;
      _trainerNameController.text = w.trainerName;
      _durationController.text = w.estimatedDurationMinutes.toString();
      _caloriesController.text = w.estimatedCaloriesBurn.toString();
      _difficulty = w.difficulty;
      _type = w.type;
      _selectedExercises = List<WorkoutExercise>.from(w.exercises);
    }
  }

  Future<void> _loadAllExercises() async {
    setState(() => _isLoading = true);
    try {
      _allExercises = await _exerciseService.getAllExercises();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error loading exercises: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExerciseSelectionDialog() {
    if (_allExercises == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select an Exercise'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allExercises!.length,
              itemBuilder: (context, index) {
                final exercise = _allExercises![index];
                final isAlreadyAdded =
                    _selectedExercises.any((e) => e.exerciseId == exercise.id);
                return ListTile(
                  title: Text(exercise.name),
                  enabled: !isAlreadyAdded,
                  trailing: isAlreadyAdded
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    if (!isAlreadyAdded) {
                      _addExerciseToWorkout(exercise);
                    }
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _addExerciseToWorkout(ex_model.Exercise exercise) {
    final workoutExercise = WorkoutExercise(
      id: '',
      exerciseId: exercise.id,
      name: exercise.name,
      videoUrl: exercise.videoUrl,
      imageUrl: exercise.imageUrl,
      sets: 3,
      repsPerSet: 10,
      restBetweenSetsSeconds: 60,
      orderIndex: _selectedExercises.length,
    );
    setState(() => _selectedExercises.add(workoutExercise));
  }

  /// **FIX**: Handles picking an image and prepares it for web or mobile preview.
  Future<void> _pickImage() async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      _imageFile = image;
      // If on web, read the bytes for the preview.
      if (kIsWeb) {
        _imageBytes = await image.readAsBytes();
      }
      setState(() {}); // Update UI to show preview
    }
  }

  Future<void> _handleSaveWorkout() async {
    if (!_formKey.currentState!.validate() || _selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill all required fields and add at least one exercise.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_imageFile == null && _networkImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a cover image for the workout.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newWorkout = Workout(
        id: widget.workout?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: _networkImageUrl ?? '',
        exercises: _selectedExercises,
        trainerName: _trainerNameController.text,
        trainerPhotoUrl: '',
        createdBy: '',
        createdAt: widget.workout?.createdAt ?? DateTime.now(),
        targetMuscleGroups: _selectedExercises
            .expand((e) => e.name.split(" "))
            .toSet()
            .toList(),
        difficulty: _difficulty,
        estimatedDurationMinutes: int.tryParse(_durationController.text) ?? 0,
        estimatedCaloriesBurn: int.tryParse(_caloriesController.text) ?? 0,
        type: _type,
        seriesCount: 1,
      );

      // We must have a new image file to create a workout
      if (_imageFile != null) {
        await _workoutService.createWorkout(newWorkout, _imageFile!);
      } else {
        // TODO: Implement update logic if needed
        throw Exception("Updating existing workouts is not yet implemented.");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Workout Saved!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving workout: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.workout == null ? 'Create Workout' : 'Edit Workout')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Workout Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        maxLines: 3),
                    TextFormField(
                        controller: _trainerNameController,
                        decoration:
                            const InputDecoration(labelText: 'Trainer Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: _durationController,
                                decoration: const InputDecoration(
                                    labelText: 'Duration (min)'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: TextFormField(
                                controller: _caloriesController,
                                decoration: const InputDecoration(
                                    labelText: 'Calories Burned'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<WorkoutDifficulty>(
                      value: _difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty'),
                      items: WorkoutDifficulty.values
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d.name)))
                          .toList(),
                      onChanged: (val) => setState(() => _difficulty = val!),
                    ),
                    const SizedBox(height: 24),
                    const Text('Exercises',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildSelectedExercisesList(),
                    Center(
                      child: ElevatedButton.icon(
                          onPressed: _showExerciseSelectionDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exercise')),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _handleSaveWorkout,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text('SAVE WORKOUT'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// **FIX**: Conditionally displays the image preview based on platform.
  Widget _buildImagePicker() {
    Widget imagePreview;

    // Web: Use Image.memory with the bytes.
    if (_imageBytes != null) {
      imagePreview = Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    // Mobile: Use Image.file with the path.
    else if (_imageFile != null && !kIsWeb) {
      imagePreview = Image.file(File(_imageFile!.path), fit: BoxFit.cover);
    }
    // Existing image from the network when editing.
    else if (_networkImageUrl != null && _networkImageUrl!.isNotEmpty) {
      imagePreview = Image.network(_networkImageUrl!, fit: BoxFit.cover);
    }
    // Placeholder if no image is selected.
    else {
      imagePreview = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
          Text('Select Cover Image')
        ],
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePreview,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedExercisesList() {
    if (_selectedExercises.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(child: Text('No exercises added yet.')));
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedExercises.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _selectedExercises.removeAt(oldIndex);
          _selectedExercises.insert(newIndex, item);
          // Update orderIndex for all items
          for (int i = 0; i < _selectedExercises.length; i++) {
            _selectedExercises[i] =
                _selectedExercises[i].copyWith(orderIndex: i);
          }
        });
      },
      itemBuilder: (context, index) {
        final ex = _selectedExercises[index];
        return Card(
          key: ValueKey(ex.exerciseId),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(ex.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          setState(() => _selectedExercises.removeAt(index))),
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                            initialValue: ex.sets.toString(),
                            decoration: const InputDecoration(labelText: 'Sets'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _selectedExercises[index] =
                                ex.copyWith(sets: int.tryParse(val) ?? 0))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextFormField(
                            initialValue: ex.repsPerSet.toString(),
                            decoration: const InputDecoration(labelText: 'Reps'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _selectedExercises[index] = ex
                                .copyWith(repsPerSet: int.tryParse(val) ?? 0))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextFormField(
                            initialValue: ex.restBetweenSetsSeconds.toString(),
                            decoration:
                                const InputDecoration(labelText: 'Rest (s)'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _selectedExercises[index] = ex
                                .copyWith(restBetweenSetsSeconds: int.tryParse(val) ?? 0))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
