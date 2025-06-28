import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single, reusable exercise.
/// Stored in a top-level 'exercises' collection.
class Exercise {
  final String id;
  final String name;
  final String description;
  final String? imageUrl; // Optional image for thumbnails
  final String videoUrl; // The direct URL from Supabase Storage
  final List<String> targetMuscles;
  final String createdBy; // Admin user ID
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.videoUrl,
    required this.targetMuscles,
    required this.createdBy,
    required this.createdAt,
  });

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'] ?? '',
      targetMuscles: List<String>.from(data['targetMuscles'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'targetMuscles': targetMuscles,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}