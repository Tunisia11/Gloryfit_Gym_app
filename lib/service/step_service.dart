import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'package:gloryfit_version_3/models/step_record_model.dart';
import 'package:permission_handler/permission_handler.dart';

class StepServiceV2 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'steps';
  
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;
  int _baselineSteps = 0;
  DateTime? _lastReset;
  double _userWeight = 70.0;
  double _userHeight = 170.0;

  void setUserMetrics({required double weight, required double height}) {
    _userWeight = weight;
    _userHeight = height;
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb && await Permission.activityRecognition.request().isDenied) {
      throw Exception('Activity recognition permission denied');
    }
  }

  Future<StepRecordModel> getTodaySteps() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .collection('daily')
          .doc(startOfDay.toIso8601String().split('T')[0])
          .get();

      if (doc.exists) {
        return StepRecordModel.fromJson(doc.data()!);
      } else {
        final newRecord = StepRecordModel(
          date: startOfDay,
          steps: 0,
          distance: 0.0,
          caloriesBurned: 0.0,
          goal: 10000,
          goalAchieved: false,
        );
        
        await _firestore
            .collection(_collection)
            .doc(userId)
            .collection('daily')
            .doc(startOfDay.toIso8601String().split('T')[0])
            .set(newRecord.toJson());
            
        return newRecord;
      }
    } catch (e) {
      throw Exception('Failed to get steps: $e');
    }
  }

  double _calculateDistance(int steps) => (steps * 0.762) / 1000;

  double _calculateCalories(int steps) {
    const met = 3.8;
    final distance = _calculateDistance(steps);
    final hours = distance / 5.0;
    return met * _userWeight * hours;
  }

  Future<void> startStepTracking(
    Function(StepRecordModel record) onStepUpdate,
    {Function(PedestrianStatus status)? onPedestrianStatusUpdate,
     Function(dynamic error)? onError}
  ) async {
    if (kIsWeb) return;

    try {
      await _requestPermissions();
      await _initializeStepCounter();
      
      _stepSubscription = Pedometer.stepCountStream.listen((StepCount event) async {
        print('StepCount event received: ${event.steps}');
        
        // Calculate today's steps
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        
        // Reset baseline if it's a new day
        if (_lastReset == null || _lastReset!.isBefore(startOfDay)) {
          _baselineSteps = event.steps;
          _lastReset = startOfDay;
        }
        
        final todaysSteps = event.steps - _baselineSteps;
        final distance = _calculateDistance(todaysSteps);
        final calories = _calculateCalories(todaysSteps);
        final goal = 10000;

        final record = StepRecordModel(
          date: today,
          steps: todaysSteps,
          distance: distance,
          caloriesBurned: calories,
          goal: goal,
          goalAchieved: todaysSteps >= goal,
        );

        onStepUpdate(record);
        await _updateStepsInFirestore(record);
      }, onError: onError);

      _pedestrianSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          onPedestrianStatusUpdate?.call(event);
        },
        onError: onError
      );

      print('Mobile step tracking started successfully.');
    } catch (e) {
      print('Error starting mobile step tracking: $e');
      onError?.call(e); 
    }
  }

  Future<void> _initializeStepCounter() async {
    try {
      // Get initial step count to use as baseline
      final initialCount = await Pedometer.stepCountStream.first;
      _baselineSteps = initialCount.steps;
      _lastReset = DateTime.now();
      print('Initial step count: $_baselineSteps');
    } catch (e) {
      print('Error getting initial step count: $e');
      throw Exception('Failed to initialize step counter');
    }
  }

  Future<void> _updateStepsInFirestore(StepRecordModel record) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      await _firestore
          .collection(_collection)
          .doc(userId)
          .collection('daily')
          .doc(startOfDay.toIso8601String().split('T')[0])
          .set(record.toJson());
    } catch (e) {
      print('Error updating steps in Firestore: $e');
    }
  }

  Future<void> stopStepTracking() async {
    if (kIsWeb) return;
    await _stepSubscription?.cancel();
    await _pedestrianSubscription?.cancel();
  }

  // Other methods (updateDailyGoal, getStepHistory, etc.) remain the same
}