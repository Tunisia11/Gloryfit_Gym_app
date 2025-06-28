import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:gloryfit_version_3/cubits/nutritionHistory/cubit.dart';
import 'package:gloryfit_version_3/cubits/nutritionHistory/states.dart';
import 'package:gloryfit_version_3/models/nutrition/dailyNutritionRecord.dart';
import 'package:intl/intl.dart';

class NutritionHistoryScreen extends StatelessWidget {
  final String userId;
  const NutritionHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NutritionHistoryCubit()..fetchWeeklyHistory(userId),
      child: Scaffold(
        appBar: AppBar(title: const Text("Weekly Progress")),
        body: BlocBuilder<NutritionHistoryCubit, NutritionHistoryState>(
          builder: (context, state) {
            if (state is NutritionHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NutritionHistoryError) {
              return Center(child: Text(state.message));
            }
            if (state is NutritionHistoryLoaded) {
              return _buildContent(state.records);
            }
            return const Center(child: Text("No history found."));
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<DailyNutritionRecord> records) {
    // Calculate consistency
    final daysTracked = records.length;
    final goalsMet = records.where((r) => r.goalMet).length;
    final consistency = daysTracked > 0 ? (goalsMet / daysTracked) * 100 : 0.0;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConsistencyCard(consistency),
        const SizedBox(height: 24),
        Text("Weekly Calorie Intake", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(height: 250, child: _buildBarChart(records)),
      ],
    );
  }
  
  Widget _buildConsistencyCard(double consistency) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.military_tech, color: Colors.green, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Weekly Consistency", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("You met your calorie goal ${consistency.toStringAsFixed(0)}% of the time this week.", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          ],
        ),
      )
    );
  }

  Widget _buildBarChart(List<DailyNutritionRecord> records) {
    // Create a map of the last 7 days to show on the chart
    final Map<int, double> weeklyData = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      // weekday: Monday=1, Sunday=7
      weeklyData[day.weekday] = 0;
    }

    // Populate with actual data
    for (var record in records) {
      if (weeklyData.containsKey(record.date.weekday)) {
        weeklyData[record.date.weekday] = record.caloriesConsumed;
      }
    }
    
    final maxCalories = weeklyData.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxCalories > 0 ? maxCalories : 2000, // have a default max Y
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
           
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String weekDay = DateFormat('EEEE').format(now.subtract(Duration(days: 6 - group.x)));
              return BarTooltipItem(
                '$weekDay\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                children: <TextSpan>[
                  TextSpan(
                    text: (rod.toY - 1).toStringAsFixed(0),
                    style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'M'; break;
                  case 1: text = 'T'; break;
                  case 2: text = 'W'; break;
                  case 3: text = 'T'; break;
                  case 4: text = 'F'; break;
                  case 5: text = 'S'; break;
                  case 6: text = 'S'; break;
                  default: text = ''; break;
                }
                return SideTitleWidget(meta: meta, space: 16, child: Text(text, style: style));
              },
              reservedSize: 38,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          final dayOfWeek = (now.weekday - 6 + i) % 7;
          final adjustedDay = dayOfWeek <= 0 ? dayOfWeek + 7: dayOfWeek;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: weeklyData[adjustedDay] ?? 0,
                color: Colors.blue,
                width: 22,
                borderRadius: BorderRadius.circular(8)
              )
            ],
          );
        })
      ),
    );
  }
}