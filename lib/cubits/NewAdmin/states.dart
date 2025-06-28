import 'package:equatable/equatable.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminStatsLoaded extends AdminState {
  final int totalUsers;
  final int totalWorkouts;
  final int totalExercises;

  const AdminStatsLoaded({
    required this.totalUsers,
    required this.totalWorkouts,
    required this.totalExercises,
  });

  @override
  List<Object> get props => [totalUsers, totalWorkouts, totalExercises];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object> get props => [message];
}