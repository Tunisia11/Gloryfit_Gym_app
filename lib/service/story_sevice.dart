// lib/services/story_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gloryfit_version_3/models/story_model.dart';
import 'package:gloryfit_version_3/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  static const String _collection = 'stories';

  /// Uploads media for a story to the 'stories-media' bucket.
  Future<String> uploadStoryMedia(XFile mediaFile) async {
    return await _storageService.uploadImage(imageFile: mediaFile, bucket: 'stories-media');
  }

  /// Creates a new story document in Firestore.
  Future<void> createStory(StoryModel story) async {
    await _firestore.collection(_collection).doc(story.id).set(story.toJson());
  }

  /// Fetches a real-time stream of ONLY active stories that have not expired.
  Stream<List<StoryModel>> getActiveStories() {
    return _firestore
        .collection(_collection)
        .where('expiresAt', isGreaterThan: DateTime.now()) // The magic query
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StoryModel.fromJson(doc.data())).toList();
    });
  }
}