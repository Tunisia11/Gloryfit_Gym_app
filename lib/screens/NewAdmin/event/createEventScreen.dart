import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';
import 'package:gloryfit_version_3/models/event/eventmodel.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _ticketCodesController = TextEditingController();
  
  DateTime _eventDate = DateTime.now();
  EventEnrollmentType _enrollmentType = EventEnrollmentType.open;

  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _ticketCodesController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      _imageFile = image;
      if (kIsWeb) {
        _imageBytes = await image.readAsBytes();
      }
      setState(() {});
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
       if (_imageFile == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Please select a cover image."), backgroundColor: Colors.orange)
         );
         return;
       }
      
      final userState = context.read<UserCubit>().state;
      // **FIX**: Correctly check for any loaded user state
      if (userState is! UserLoaded && userState is! UserLoadedWithInProgressWorkout) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: User not loaded.")));
        return;
      }
      final adminUser = (userState as dynamic).user as UserModel;
      
      setState(() => _isLoading = true);
      
      try {
        final imageUrl = await StorageService().uploadImage(imageFile: _imageFile!, bucket: 'event-images');

        final newEvent = Event(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: imageUrl,
          location: _locationController.text.trim(),
          eventDate: _eventDate,
          createdBy: adminUser.id,
          enrollmentType: _enrollmentType,
          price: double.tryParse(_priceController.text) ?? 0.0,
          validTicketCodes: _ticketCodesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        );

        context.read<EventCubit>().createEvent(newEvent);
        if(mounted) Navigator.of(context).pop();

      } catch (e) {
         if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error creating event: $e"), backgroundColor: Colors.red)
           );
         }
      } finally {
        if(mounted) {
           setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Event')),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Event Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventEnrollmentType>(
                value: _enrollmentType,
                decoration: const InputDecoration(labelText: 'Enrollment Type', border: OutlineInputBorder()),
                items: EventEnrollmentType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(),
                onChanged: (val) => setState(() => _enrollmentType = val!),
              ),
               const SizedBox(height: 16),
              if (_enrollmentType == EventEnrollmentType.paid)
                TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              if (_enrollmentType == EventEnrollmentType.ticketCode)
                TextFormField(controller: _ticketCodesController, decoration: const InputDecoration(labelText: 'Valid Codes (comma-separated)', border: OutlineInputBorder())),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _submitForm, child: const Text('Create Event'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade400)
      ),
      title: const Text("Event Date & Time"),
      subtitle: Text(DateFormat.yMMMd().add_jm().format(_eventDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: _eventDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (date != null) {
          final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_eventDate));
          if (time != null && mounted) {
            setState(() {
              _eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            });
          }
        }
      },
    );
  }
  
  Widget _buildImagePicker() {
    Widget imagePreview;
    if (_imageBytes != null) {
      imagePreview = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_imageFile != null && !kIsWeb) {
      imagePreview = Image.file(File(_imageFile!.path), fit: BoxFit.cover);
    } else {
      imagePreview = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.camera_alt, size: 40, color: Colors.grey), Text('Select Cover Image')],
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400)),
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: imagePreview),
      ),
    );
  }
}
