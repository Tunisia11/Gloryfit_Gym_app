import 'package:cloud_firestore/cloud_firestore.dart';

class Class {
  final String id;
  final String name;
 String description;
  final String coverImageUrl;
  final String trainerId;
  final String trainerName;
  final String trainerPhotoUrl;
  final ClassPricing pricing;
  final ClassSchedule schedule;
  final List<String> targetAudience; // e.g., ['Beginner', 'Weight Loss']
  final int capacity;
  final List<String> memberIds;
  final DateTime createdAt;

  Class({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.trainerId,
    required this.trainerName,
    required this.trainerPhotoUrl,
    required this.pricing,
    required this.schedule,
    required this.targetAudience,
    required this.capacity,
    required this.memberIds,
    required this.createdAt,
  });

  factory Class.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Class(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      trainerId: data['trainerId'] ?? '',
      trainerName: data['trainerName'] ?? '',
      trainerPhotoUrl: data['trainerPhotoUrl'] ?? '',
      pricing: ClassPricing.fromMap(data['pricing'] ?? {}),
      schedule: ClassSchedule.fromMap(data['schedule'] ?? {}),
      targetAudience: List<String>.from(data['targetAudience'] ?? []),
      capacity: data['capacity'] ?? 0,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'trainerPhotoUrl': trainerPhotoUrl,
      'pricing': pricing.toMap(),
      'schedule': schedule.toMap(),
      'targetAudience': targetAudience,
      'capacity': capacity,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ClassPricing {
  final ClassPriceType type;
  final double amount; // 0 for free

  ClassPricing({required this.type, this.amount = 0});

  factory ClassPricing.fromMap(Map<String, dynamic> map) {
    return ClassPricing(
      type: ClassPriceType.values
          .firstWhere((e) => e.name == map['type'], orElse: () => ClassPriceType.free),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'amount': amount,
    };
  }
}

class ClassSchedule {
  final DateTime startDate;
  final DateTime endDate;
  final List<int> daysOfWeek; // 1 for Monday, 7 for Sunday
  final String timeOfDay; // e.g., "18:00"

  ClassSchedule({
    required this.startDate,
    required this.endDate,
    required this.daysOfWeek,
    required this.timeOfDay,
  });

   factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      timeOfDay: map['timeOfDay'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'daysOfWeek': daysOfWeek,
      'timeOfDay': timeOfDay,
    };
  }
}

enum ClassPriceType { free, oneTime, subscription }
