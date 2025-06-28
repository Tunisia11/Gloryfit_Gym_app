import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Keys for SharedPreferences for robust state saving ---
const String dailyStepAnchorKey = 'daily_step_anchor';
const String dateOfAnchorKey = 'date_of_anchor';
const String lastSavedStepsKey = 'last_saved_steps';
const String userIdKey = 'user_id';

/// The entrypoint for the background service isolate.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure plugins are initialized in this isolate
  DartPluginRegistrant.ensureInitialized();
  
  // Initialize Firebase in the background isolate
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  String? userId;

  // This is a crucial check to access Android-specific APIs.
  if (service is AndroidServiceInstance) {
    service.on('setUserId').listen((data) {
      if (data != null) {
        userId = data['userId'];
        SharedPreferences.getInstance().then((prefs) {
          if (userId != null && userId!.isNotEmpty) {
            prefs.setString(userIdKey, userId!);
          }
        });
      }
    });
  }

  // --- NEW: Listener for Pedestrian Status ---
  Pedometer.pedestrianStatusStream.listen((PedestrianStatus status) {
    // When a new status is received (e.g., 'walking', 'stopped'),
    // send it to the UI through a new event named 'status_update'.
    service.invoke(
      'status_update',
      {
        'status': status.status, // We only need the status string
      },
    );
  });

  // Listener for Step Count
  Pedometer.stepCountStream.listen((StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    
    userId ??= prefs.getString(userIdKey);
    
    int stepAnchor = prefs.getInt(dailyStepAnchorKey) ?? 0;
    String? anchorDateStr = prefs.getString(dateOfAnchorKey);
    
    final now = DateTime.now();
    final todayDateStr = "${now.year}-${now.month}-${now.day}";

    if (anchorDateStr == null || anchorDateStr != todayDateStr) {
      stepAnchor = event.steps;
      await prefs.setInt(dailyStepAnchorKey, stepAnchor);
      await prefs.setString(dateOfAnchorKey, todayDateStr);
    }
    
    final int todaySteps = event.steps - stepAnchor;

    // Update the notification's text live
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "GloryFit Active",
        content: "Today's Steps: $todaySteps",
      );
    }
    
    // Send updated steps back to the UI
    service.invoke('update', {"steps": todaySteps});

    // Smartly update Firestore
    int lastSaved = prefs.getInt(lastSavedStepsKey) ?? 0;
    if (userId != null && (todaySteps > lastSaved + 500)) {
      await _updateStepsInFirestore(firestore, userId!, todaySteps);
      await prefs.setInt(lastSavedStepsKey, todaySteps);
    }
  });
}

/// Helper function to update the user's step history in Firestore.
Future<void> _updateStepsInFirestore(FirebaseFirestore firestore, String userId, int newSteps) async {
  try {
    final userRef = firestore.collection('users').doc(userId);
    final now = DateTime.now();
    
    final todayRecord = DailyStepRecord(
      date: DateTime(now.year, now.month, now.day), 
      steps: newSteps,
    
    );

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        print("User document does not exist, cannot update steps.");
        return;
      }
      
      final userData = snapshot.data()!;
      final List<dynamic> historyRaw = userData['stepHistory'] ?? [];
      final List<DailyStepRecord> history = historyRaw.map((e) => DailyStepRecord.fromJson(e)).toList();
      
      final index = history.indexWhere((record) =>
          record.date.year == now.year &&
          record.date.month == now.month &&
          record.date.day == now.day);
      
      if (index != -1) {
        history[index] = todayRecord;
      } else {
        history.add(todayRecord);
      }
      
      transaction.update(userRef, {
        'stepHistory': history.map((e) => e.toJson()).toList(),
      });
    });
  } catch (e) {
    print('Error updating steps in Firestore: $e');
  }
}

/// Initializes and configures the background service.
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'gloryfit_steps',
      initialNotificationTitle: 'GloryFit Active',
      initialNotificationContent: 'Initializing step tracking...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
    //  onBackground: onStart,
      autoStart: true,
    ),
  );
  await service.startService();
}