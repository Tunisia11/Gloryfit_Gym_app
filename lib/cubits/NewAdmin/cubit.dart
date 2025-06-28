import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/models/classes/class_model.dart';
import 'package:gloryfit_version_3/models/classes/join_request.dart';

import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/service/class_service.dart' show ClassService;
import 'package:gloryfit_version_3/services/admin_service.dart';

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

  const AdminDashboardLoaded({
    required this.totalUsers,
    required this.totalWorkouts,
    required this.totalExercises,
    required this.totalClasses,
    required this.classes,
    required this.joinRequests,
    required this.users,
  });

  @override
  List<Object> get props => [totalUsers, totalWorkouts, totalExercises, totalClasses, classes, joinRequests, users];
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

  AdminCubit(this._adminService, this._classService) : super(AdminInitial());

  Future<void> loadAdminDashboard() async {
    try {
      emit(AdminLoading());
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _classService.getClasses(), // Assuming ClassService has getClasses()
        _adminService.getPendingJoinRequests(),
        _adminService.getAllUsers(),
      ]);

      final stats = results[0] as Map<String, int>;
      final classes = results[1] as List<Class>;
      final requests = results[2] as List<JoinRequest>;
      final users = results[3] as List<UserModel>;

      emit(AdminDashboardLoaded(
        totalUsers: stats['totalUsers'] ?? 0,
        totalWorkouts: stats['totalWorkouts'] ?? 0,
        totalExercises: stats['totalExercises'] ?? 0,
        totalClasses: stats['totalClasses'] ?? 0,
        classes: classes,
        joinRequests: requests,
        users: users,
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
}
