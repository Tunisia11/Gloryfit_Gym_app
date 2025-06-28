import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/admin/admin_cubit.dart';

import 'package:gloryfit_version_3/models/classes/class_model.dart';

class EditClassScreen extends StatefulWidget {
  final Class aClass;
  const EditClassScreen({super.key, required this.aClass});

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.aClass.name);
    _descriptionController =
        TextEditingController(text: widget.aClass.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _saveChanges() {
    // In a real app, you would have a more complex update method
    // For now, this is a placeholder to show the concept
    widget.aClass.description = _descriptionController.text;
    
    // You would call a cubit method here to save the changes
    // context.read<AdminCubit>().updateClass(widget.aClass);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Changes saved (demo)!"), backgroundColor: Colors.blue,)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.aClass.name}'),
        actions: [
          IconButton(onPressed: _saveChanges, icon: const Icon(Icons.save))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Class Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            const Text("Manage Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Placeholder for member list
            Text("Total Members: ${widget.aClass.memberIds.length}"),
            // In a real app, this would be a ListView of members with a "Remove" button
          ],
        ),
      ),
    );
  }
}
