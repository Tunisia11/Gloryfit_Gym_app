import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/nutritionHistory/states.dart';
import 'package:gloryfit_version_3/service/nutriation.dart';


class NutritionHistoryCubit extends Cubit<NutritionHistoryState> {
  final NutritionService _nutritionService = NutritionService();

  NutritionHistoryCubit() : super(NutritionHistoryInitial());

  Future<void> fetchWeeklyHistory(String userId) async {
    try {
      emit(NutritionHistoryLoading());
      final records = await _nutritionService.getWeeklyRecords(userId);
      emit(NutritionHistoryLoaded(records));
    } catch (e) {
      emit(NutritionHistoryError("Failed to load history: ${e.toString()}"));
    }
  }
}