// lib/cubits/story/story_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/cubits/story/states.dart';
import 'package:gloryfit_version_3/models/story_model.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/service/story_sevice.dart';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';


class StoryCubit extends Cubit<StoryState> {
  final StoryService _storyService;
  StoryCubit(this._storyService) : super(StoryInitial());

  void loadStories() {
    // We check for StoryInitial or StoryError to prevent multiple listeners
    // if the data is already loaded or loading.
    if (state is StoryInitial || state is StoryError) {
      emit(StoryLoading());
      _storyService.getActiveStories().listen(
        (flatListOfStories) {
          // **THE FIX**: This logic groups the stories by user ID.
          final grouped = <String, List<StoryModel>>{};
          for (var story in flatListOfStories) {
            (grouped[story.userId] ??= []).add(story);
          }
          // Now we emit the state with BOTH the flat list and the grouped map.
          emit(StoriesLoaded(flatListOfStories, grouped));
        },
        onError: (error) => emit(StoryError(error.toString())),
      );
    }
  }

  Future<void> createStory({
    required XFile mediaFile,
    required UserModel author,
  }) async {
    try {
      final mediaUrl = await _storyService.uploadStoryMedia(mediaFile);
      final now = DateTime.now();
      
      final story = StoryModel(
        id: const Uuid().v4(),
        userId: author.id,
        userName: author.displayName ?? 'User',
        userImage: author.photoURL ?? '',
        mediaUrl: mediaUrl,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );

      await _storyService.createStory(story);
      // The stream from loadStories() will automatically update the UI.
    } catch (e) {
      emit(StoryError(e.toString()));
    }
  }
}