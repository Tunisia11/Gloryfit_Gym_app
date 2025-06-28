import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gloryfit_version_3/models/post_model.dart';
import 'package:gloryfit_version_3/models/comment_model.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class PostService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;
  static const String _collectionPath = 'posts';

  PostService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  /// Fetches all posts, ordered by creation date.
  Future<List<PostModel>> getPosts() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionPath)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PostModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting posts: $e');
      rethrow;
    }
  }

  /// Fetches posts for a specific user ID.
  Future<List<PostModel>> getPostsByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PostModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting posts by user ID: $e');
      rethrow;
    }
  }

  /// **FIXED**: Creates a new post, handling multiple image uploads correctly.
  Future<void> createPost({
    required String content,
    required UserModel author,
    required bool isQuestion,
    List<XFile> images = const [], // Accepts a list of XFiles
  }) async {
    try {
      // Step 1: Upload all images in parallel and get their URLs.
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        final uploadTasks = images.map((imageFile) => _storageService
            .uploadImage(imageFile: imageFile, bucket: 'posts-images'));
        imageUrls = await Future.wait(uploadTasks);
      }

      // Step 2: Create a new post document reference to get an ID.
      final newPostRef = _firestore.collection(_collectionPath).doc();

      // Step 3: Create the PostModel object with the new ID and uploaded image URLs.
      final newPost = PostModel(
        id: newPostRef.id,
        content: content,
        userId: author.id,
        userName: author.displayName ?? 'Anonymous',
        userImage: author.photoURL ?? '',
        isQuestion: isQuestion,
        imageUrls: imageUrls,
        likes: [],
        comments: [],
        createdAt: DateTime.now(),
      );

      // Step 4: Set the post data in Firestore.
      await newPostRef.set(newPost.toJson());
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  /// Toggles a like on a post for a specific user.
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection(_collectionPath).doc(postId);
    try {
      final doc = await postRef.get();
      if (doc.exists) {
        final List<String> likes =
            List<String>.from(doc.data()?['likes'] ?? []);
        if (likes.contains(userId)) {
          postRef.update({
            'likes': FieldValue.arrayRemove([userId])
          });
        } else {
          postRef.update({
            'likes': FieldValue.arrayUnion([userId])
          });
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Adds a comment to a post.
  Future<void> addComment(String postId, CommentModel comment) async {
    try {
      await _firestore.collection(_collectionPath).doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toJson()])
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Deletes a post from the database.
  Future<void> deletePost(String postId) async {
    try {
      // Note: For a complete solution, you'd also delete associated images from storage.
      await _firestore.collection(_collectionPath).doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }
}
