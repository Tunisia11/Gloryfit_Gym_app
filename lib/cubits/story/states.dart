// lib/cubits/story/story_states.dart

import 'package:flutter/cupertino.dart';
import 'package:gloryfit_version_3/models/story_model.dart';

@immutable
abstract class StoryState {}

class StoryInitial extends StoryState {}

class StoryLoading extends StoryState {}

// **FIXED**: This state now correctly defines the groupedStories map.
class StoriesLoaded extends StoryState {
  final List<StoryModel> stories;
  final Map<String, List<StoryModel>> groupedStories;

  StoriesLoaded(this.stories, this.groupedStories);
}

class StoryError extends StoryState {
  final String message;
  StoryError(this.message);
}