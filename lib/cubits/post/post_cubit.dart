import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/post/post_states.dart';
import 'package:gloryfit_version_3/models/comment_model.dart';
import 'package:gloryfit_version_3/models/post_model.dart';
import 'package:gloryfit_version_3/models/user_model.dart' as gloryfit_user;
import 'package:gloryfit_version_3/services/post_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PostCubit extends Cubit<PostState> {
  final PostService _postService;
  final String userId;

  PostCubit(this._postService, {String? currentUserId})
      : userId = currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
        super( PostInitial());

  Future<void> loadPosts() async {
    try {
      emit( PostLoading());
      final posts = await _postService.getPosts();
      emit(PostLoaded(posts));
    } catch (e) {
      emit(PostError('Failed to load posts: $e'));
    }
  }

  Future<void> fetchPostsByUserId(String userId) async {
    try {
      emit( PostLoading());
      final posts = await _postService.getPostsByUserId(userId);
      emit(PostLoaded(posts));
    } catch (e) {
      emit(PostError('Failed to load user posts: $e'));
    }
  }

  /// **FIXED**: Calls the service with a list of XFiles directly.
  Future<void> createPost({
    required String content,
    required gloryfit_user.UserModel author,
    List<XFile> images = const [],
    bool isQuestion = false,
  }) async {
    try {
      emit( PostLoading()); // Show loading state
      await _postService.createPost(
        content: content,
        author: author,
        isQuestion: isQuestion,
        images: images,
      );
      // Refresh the main post list after creating a new one.
      await loadPosts();
    } catch (e) {
      emit(PostError('Failed to create post: $e'));
    }
  }

  Future<void> toggleLike(PostModel post) async {
    try {
      // Optimistically update the UI for instant feedback
      _optimisticallyUpdatePost(post.copyWith(
        likes: post.likes.contains(userId)
            ? (List<String>.from(post.likes)..remove(userId))
            : (List<String>.from(post.likes)..add(userId)),
      ));

      await _postService.toggleLike(post.id, userId);
    } catch (e) {
      // If the API call fails, revert the change
      _optimisticallyUpdatePost(post);
      emit(PostError('Failed to update like: $e'));
    }
  }

  Future<void> addComment(String postId, String content,
      {required gloryfit_user.UserModel author}) async {
    try {
      final comment = CommentModel(
        id: const Uuid().v4(),
        userId: author.id,
        userName: author.displayName ?? 'Anonymous',
        userImage: author.photoURL ?? '',
        content: content,
        createdAt: DateTime.now(),
        likes: [],
      );
      await _postService.addComment(postId, comment);
      // For a better user experience, we could update the post in the state
      // instead of a full reload, but this is simpler for now.
      await loadPosts();
    } catch (e) {
      emit(PostError('Failed to add comment: $e'));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      // Optimistically remove the post from the UI
      final currentState = state;
      if (currentState is PostLoaded) {
        final updatedPosts =
            currentState.posts.where((p) => p.id != postId).toList();
        emit(PostLoaded(updatedPosts));
      }
      await _postService.deletePost(postId);
    } catch (e) {
      // If the deletion fails, reload the posts to bring it back
      await loadPosts();
      emit(PostError('Failed to delete post: $e'));
    }
  }

  // Helper to update a single post within the PostLoaded state instantly
  void _optimisticallyUpdatePost(PostModel updatedPost) {
    final currentState = state;
    if (currentState is PostLoaded) {
      final updatedList = currentState.posts.map((post) {
        return post.id == updatedPost.id ? updatedPost : post;
      }).toList();
      emit(PostLoaded(updatedList));
    }
  }
}
