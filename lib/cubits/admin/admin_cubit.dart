import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/models/classes/class_model.dart';
import 'package:gloryfit_version_3/models/classes/join_request.dart';

import 'package:gloryfit_version_3/models/exercise_model.dart';

import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/service/class_service.dart';
import 'package:gloryfit_version_3/services/admin_service.dart';
import 'package:gloryfit_version_3/service/exercise_service.dart';
import 'package:gloryfit_version_3/service/workout_service.dart';
import 'package:image_picker/image_picker.dart';

// --- STATES ---
abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object> get props => [];
}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}

class AdminDashboardLoaded extends AdminState {
  final int totalUsers;
  final int totalWorkouts;
  final int totalExercises;
  final int totalClasses;
  final List<Class> classes;
  final List<JoinRequest> joinRequests;
  final List<UserModel> users;
  final List<Workout> workouts;
  final List<Exercise> exercises;

  const AdminDashboardLoaded({
    required this.totalUsers,
    required this.totalWorkouts,
    required this.totalExercises,
    required this.totalClasses,
    required this.classes,
    required this.joinRequests,
    required this.users,
    required this.workouts,
    required this.exercises,
  });

  @override
  List<Object> get props => [
        totalUsers,
        totalWorkouts,
        totalExercises,
        totalClasses,
        classes,
        joinRequests,
        users,
        workouts,
        exercises
      ];
}

class AdminOperationSuccess extends AdminState {
  final String message;
  const AdminOperationSuccess(this.message);
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
}


// --- CUBIT ---
class AdminCubit extends Cubit<AdminState> {
  final AdminService _adminService;
  final ClassService _classService;
  final WorkoutService _workoutService;
  final ExerciseService _exerciseService;

  AdminCubit(this._adminService, this._classService, this._workoutService, this._exerciseService) : super(AdminInitial());
   Future<void> createExercise({
    required String name,
    required String description,
    required List<String> targetMuscles,
    required XFile videoFile,
    XFile? imageFile,
  }) async {
    try {
      emit(AdminLoading());
      await _exerciseService.createExercise(
        name: name,
        description: description,
        targetMuscles: targetMuscles,
        videoFile: videoFile,
        imageFile: imageFile,
      );
      emit(const AdminOperationSuccess("Exercise Created Successfully!"));
      await loadAdminDashboard(); // Refresh data
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // --- Workout Management ---
  Future<void> createWorkout(Workout workout, XFile imageFile) async {
    try {
       emit(AdminLoading());
       await _workoutService.createWorkout(workout, imageFile);
       emit(const AdminOperationSuccess("Workout Created Successfully!"));
       await loadAdminDashboard(); // Refresh data
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> loadAdminDashboard() async {
    try {
      emit(AdminLoading());
      // Fetch all data in parallel for a super fast load time
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _classService.getClasses(),
        _adminService.getPendingJoinRequests(),
        _adminService.getAllUsers(),
        _workoutService.getAllWorkouts(),
        _exerciseService.getAllExercises(),
      ]);

      final stats = results[0] as Map<String, int>;
      final classes = results[1] as List<Class>;
      final requests = results[2] as List<JoinRequest>;
      final users = results[3] as List<UserModel>;
      final workouts = results[4] as List<Workout>;
      final exercises = results[5] as List<Exercise>;

      emit(AdminDashboardLoaded(
        totalUsers: stats['totalUsers'] ?? 0,
        totalWorkouts: stats['totalWorkouts'] ?? 0,
        totalExercises: stats['totalExercises'] ?? 0,
        totalClasses: stats['totalClasses'] ?? 0,
        classes: classes,
        joinRequests: requests,
        users: users,
        workouts: workouts,
        exercises: exercises,
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
  
  Future<void> approveRequest(JoinRequest request) async {
    try {
      await _adminService.approveJoinRequest(request);
      emit(const AdminOperationSuccess("Request Approved!"));
      loadAdminDashboard();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
  
  Future<void> denyRequest(String requestId) async {
    try {
      await _adminService.denyJoinRequest(requestId);
      emit(const AdminOperationSuccess("Request Denied."));
      loadAdminDashboard();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
  
  // You can add more methods here for managing workouts, users etc.
}
