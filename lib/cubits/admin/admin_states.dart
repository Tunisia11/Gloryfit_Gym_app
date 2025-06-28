import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/user_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminAuthorized extends AdminState {}

class AdminUnauthorized extends AdminState {}

class AdminStatsLoaded extends AdminState {
  final int totalUsers;
  final int activeUsers;
  final int bannedUsers;
  final int totalExercises;
  final int totalWorkouts;

  const AdminStatsLoaded({
    required this.totalUsers,
    required this.activeUsers,
    required this.bannedUsers,
    required this.totalExercises,
    required this.totalWorkouts,
  });

  @override
  List<Object?> get props => [totalUsers, activeUsers, bannedUsers, totalExercises, totalWorkouts];
}

class UsersLoaded extends AdminState {
  final List<UserModel> users;

  const UsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserBanned extends AdminState {
  final String userId;

  const UserBanned(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UserUnbanned extends AdminState {
  final String userId;

  const UserUnbanned(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UserDeleted extends AdminState {
  final String userId;

  const UserDeleted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AdminActionSuccess extends AdminState {
  final String message;

  const AdminActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
} 