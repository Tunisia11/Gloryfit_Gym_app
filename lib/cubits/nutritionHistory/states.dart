import 'package:equatable/equatable.dart';

import 'package:gloryfit_version_3/models/nutrition/dailyNutritionRecord.dart';

abstract class NutritionHistoryState extends Equatable {
  const NutritionHistoryState();
  @override
  List<Object> get props => [];
}

class NutritionHistoryInitial extends NutritionHistoryState {}
class NutritionHistoryLoading extends NutritionHistoryState {}
class NutritionHistoryLoaded extends NutritionHistoryState {
  final List<DailyNutritionRecord> records;
  const NutritionHistoryLoaded(this.records);
  @override
  List<Object> get props => [records];
}
class NutritionHistoryError extends NutritionHistoryState {
  final String message;
  const NutritionHistoryError(this.message);
  @override
  List<Object> get props => [message];
}