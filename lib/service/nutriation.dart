import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gloryfit_version_3/models/nutrition/dailyNutritionRecord.dart' show DailyNutritionRecord;

class NutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save or update a nutrition record for a specific user and date
  Future<void> saveDailyRecord(String userId, DailyNutritionRecord record) async {
    final todayDocId = "${record.date.year}-${record.date.month}-${record.date.day}";
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dietHistory')
        .doc(todayDocId);
    
    await docRef.set(record.toMap());
  }

  // Fetch the last 7 days of nutrition records for the weekly chart
  Future<List<DailyNutritionRecord>> getWeeklyRecords(String userId) async {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dietHistory')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
        .orderBy('date', descending: true)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    return querySnapshot.docs.map((doc) => DailyNutritionRecord.fromMap(doc.data())).toList();
  }
}