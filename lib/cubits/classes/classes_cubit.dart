import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/classes/states.dart';
import 'package:gloryfit_version_3/models/classes/class_model.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/service/class_service.dart';

import 'package:uuid/uuid.dart';

class ClassCubit extends Cubit<ClassState> {
  final ClassService _classService;

  ClassCubit(this._classService) : super(ClassInitial());

  /// Fetches all classes for the discovery screen.
  Future<void> loadClasses() async {
    try {
      emit(ClassLoading());
      final classes = await _classService.getClasses();
      emit(ClassesLoaded(classes));
    } catch (e) {
      emit(ClassError("Failed to load classes: ${e.toString()}"));
    }
  }

  /// Creates a new class (Admin/Trainer only).
  Future<void> createClass({
    required String name,
    required String description,
    required String coverImageUrl,
    required UserModel trainer,
    required ClassPricing pricing,
    required ClassSchedule schedule,
  }) async {
    try {
      emit(ClassLoading());
      final newClass = Class(
        id: const Uuid().v4(),
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        trainerId: trainer.id,
        trainerName: trainer.displayName ?? 'GloryFit Trainer',
        trainerPhotoUrl: trainer.photoURL ?? '',
        pricing: pricing,
        schedule: schedule,
        targetAudience: ['General'], // Example value
        capacity: 50, // Example value
        memberIds: [],
        createdAt: DateTime.now(),
      );
      await _classService.createClass(newClass);
      emit(const ClassOperationSuccess("Class created successfully!"));
      loadClasses(); // Refresh the list
    } catch (e) {
      emit(ClassError("Failed to create class: ${e.toString()}"));
    }
  }

  /// Allows a user to join a class based on its pricing model.
  Future<void> joinClass(Class aClass, UserModel user) async {
    try {
      emit(ClassLoading());
      switch (aClass.pricing.type) {
        case ClassPriceType.free:
          await _classService.joinFreeClass(aClass, user);
          emit(const ClassOperationSuccess("Successfully joined free class!"));
          break;
        case ClassPriceType.oneTime:
        case ClassPriceType.subscription:
          // For paid classes, we initiate a join request for admin approval.
          // A real app would integrate a payment gateway here.
          await _classService.requestToJoinClass(aClass, user);
          emit(const ClassOperationSuccess(
              "Request to join sent! You will be notified upon approval."));
          break;
      }
      loadClasses(); // Refresh to potentially show updated class state
    } catch (e) {
      emit(ClassError("Failed to join class: ${e.toString()}"));
    }
  }
}
