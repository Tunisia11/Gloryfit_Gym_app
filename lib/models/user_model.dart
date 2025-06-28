import 'package:cloud_firestore/cloud_firestore.dart';

// **FIX**: This helper function safely parses date fields.
// It can handle Timestamps, Strings, or null values without crashing,
// which resolves the 'String is not a subtype of Timestamp' error.
DateTime? _parseDate(dynamic date) {
  if (date == null) return null;
  if (date is Timestamp) return date.toDate();
  if (date is String) return DateTime.tryParse(date);
  return null;
}

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final double? height;
  final double? weight;
  final FitnessGoal? fitnessGoal;
  final int? trainingDaysPerWeek;
  final bool isOnboardingCompleted;
  final bool isDietOnboardingCompleted;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool isOnline;
  final bool isBanned;
  final DateTime? bannedAt;
  
  // Other features from your model
  final List<String> followers;
  final List<String> following;
  final List<GymSession> gymSessions;
  final List<DailyStepRecord>? stepHistory;


  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.fitnessGoal,
    this.trainingDaysPerWeek,
    required this.isOnboardingCompleted,
    this.isDietOnboardingCompleted = false,
    this.role = UserRole.member,
    required this.createdAt,
    this.lastActive,
    this.isOnline = false,
    this.isBanned = false,
    this.bannedAt,
    this.followers = const [],
    this.following = const [],
    this.gymSessions = const [],
    this.stepHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'dateOfBirth': dateOfBirth,
      'gender': gender?.name,
      'height': height,
      'weight': weight,
      'fitnessGoal': fitnessGoal?.name,
      'trainingDaysPerWeek': trainingDaysPerWeek,
      'isOnboardingCompleted': isOnboardingCompleted,
      'isDietOnboardingCompleted': isDietOnboardingCompleted,
      'role': role.name,
      'createdAt': createdAt,
      'lastActive': lastActive,
      'isOnline': isOnline,
      'isBanned': isBanned,
      'bannedAt': bannedAt,
      'followers': followers,
      'following': following,
      'gymSessions': gymSessions.map((session) => session.toMap()).toList(),
      'stepHistory': stepHistory?.map((e) => e.toJson()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      // **FIX**: Use the safe parsing helper for all date fields.
      dateOfBirth: _parseDate(map['dateOfBirth']),
      gender: map['gender'] != null ? Gender.values.byName(map['gender']) : null,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      fitnessGoal: map['fitnessGoal'] != null ? FitnessGoal.values.byName(map['fitnessGoal']) : null,
      trainingDaysPerWeek: map['trainingDaysPerWeek'],
      isOnboardingCompleted: map['isOnboardingCompleted'] ?? false,
      isDietOnboardingCompleted: map['isDietOnboardingCompleted'] ?? false,
      role: UserRole.values.byName(map['role'] ?? 'member'),
      // Use the helper and provide a fallback for non-nullable required dates.
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      lastActive: _parseDate(map['lastActive']),
      isOnline: map['isOnline'] ?? false,
      isBanned: map['isBanned'] ?? false,
      bannedAt: _parseDate(map['bannedAt']),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      gymSessions: (map['gymSessions'] as List<dynamic>?)
          ?.map((e) => GymSession.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      stepHistory: (map['stepHistory'] as List<dynamic>?)
          ?.map((e) => DailyStepRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? dateOfBirth,
    Gender? gender,
    double? height,
    double? weight,
    FitnessGoal? fitnessGoal,
    int? trainingDaysPerWeek,
    bool? isOnboardingCompleted,
    bool? isDietOnboardingCompleted,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isOnline,
    bool? isBanned,
    DateTime? bannedAt,
    List<String>? followers,
    List<String>? following,
    List<GymSession>? gymSessions,
    List<DailyStepRecord>? stepHistory,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      isDietOnboardingCompleted: isDietOnboardingCompleted ?? this.isDietOnboardingCompleted,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      isBanned: isBanned ?? this.isBanned,
      bannedAt: bannedAt ?? this.bannedAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      gymSessions: gymSessions ?? this.gymSessions,
      stepHistory: stepHistory ?? this.stepHistory,
    );
  }
}

// Enums for user properties
enum Gender { male, female, other }
enum FitnessGoal { weightLoss, muscleGain, endurance, toning, strength, flexibility, generalFitness, sportsSpecific }
enum UserRole { member, trainer, admin }

class GymSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;

  GymSession({
    required this.id,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory GymSession.fromMap(Map<String, dynamic> map) {
    return GymSession(
      id: map['id'] ?? '',
      startTime: _parseDate(map['startTime']) ?? DateTime.now(),
      endTime: _parseDate(map['endTime']),
    );
  }
}

class DailyStepRecord {
  final DateTime date;
  final int steps;

  DailyStepRecord({
    required this.date,
    required this.steps,
  });

  factory DailyStepRecord.fromJson(Map<String, dynamic> json) {
    return DailyStepRecord(
      date: _parseDate(json['date']) ?? DateTime.now(),
      steps: json['steps'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'steps': steps,
    };
  }
}
