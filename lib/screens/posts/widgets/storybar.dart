// lib/widgets/story_bar.dart
import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/cubits/story/cubit.dart';
import 'package:gloryfit_version_3/models/story_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gloryfit_version_3/screens/posts/story_viewer_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';

import 'package:gloryfit_version_3/models/user_model.dart' as gloryfit_user;
import 'package:image_picker/image_picker.dart';

class StoryBar extends StatelessWidget {
  final Map<String, List<StoryModel>> groupedStories;

  const StoryBar({super.key, required this.groupedStories});

  @override
  Widget build(BuildContext context) {
    final userIds = groupedStories.keys.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive dimensions
    final double avatarRadius = screenWidth < 360 ? 28 : 32;
    final double horizontalPadding = screenWidth < 360 ? 8 : 12;
    final double itemSpacing = screenWidth < 360 ? 6 : 8;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional: Add a subtle header if needed
          // Row(
          //   children: [
          //     Text(
          //       'Stories',
          //       style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //         fontWeight: FontWeight.w600,
          //         color: Colors.grey.shade700,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 8),
          
          SizedBox(
            height: avatarRadius * 2 + 40, // Avatar diameter + text space + padding
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: userIds.length + 1,
              separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AddStoryCircle(avatarRadius: avatarRadius);
                }

                final userId = userIds[index - 1];
                final userStories = groupedStories[userId]!;
                final representativeStory = userStories.first;

                return StoryCircle(
                  story: representativeStory,
                  avatarRadius: avatarRadius,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            StoryViewerScreen(
                          groupedStories: groupedStories,
                          initialUserId: userId,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;
                          final tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for the "Add Story" button in the story bar
class AddStoryCircle extends StatelessWidget {
  final double avatarRadius;
  
  const AddStoryCircle({
    super.key,
    this.avatarRadius = 32,
  });

  Future<void> _createStory(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null || !context.mounted) return;

    final userState = context.read<UserCubit>().state;
    gloryfit_user.UserModel? currentUser;

    if (userState is UserLoaded) currentUser = userState.user;
    if (userState is UserLoadedWithInProgressWorkout) currentUser = userState.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot create story. User not found.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adding your story...')),
    );
    
    try {
      await context.read<StoryCubit>().createStory(
        mediaFile: pickedFile,
        author: currentUser,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post story: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade700,
    );

    return GestureDetector(
      onTap: () => _createStory(context),
      child: Container(
        constraints: BoxConstraints(
          minWidth: avatarRadius * 2,
          maxWidth: avatarRadius * 2.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                String userImage = '';
                if (state is UserLoaded) userImage = state.user.photoURL ?? '';
                if (state is UserLoadedWithInProgressWorkout) {
                  userImage = state.user.photoURL ?? '';
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: userImage.isNotEmpty
                            ? CachedNetworkImageProvider(userImage)
                            : null,
                        child: userImage.isEmpty
                            ? Icon(
                                Icons.person,
                                size: avatarRadius * 0.8,
                                color: Colors.grey.shade400,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.add_circle,
                          color: Theme.of(context).primaryColor,
                          size: avatarRadius * 0.6,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: avatarRadius * 0.2),
            Text(
              'Your Story',
              style: textStyle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying a single user's story circle
class StoryCircle extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  final double avatarRadius;

  const StoryCircle({
    super.key,
    required this.story,
    required this.onTap,
    this.avatarRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade700,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: avatarRadius * 2,
          maxWidth: avatarRadius * 2.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Colors.amber.shade400,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: avatarRadius - 3,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: story.userImage.isNotEmpty
                      ? CachedNetworkImageProvider(story.userImage)
                      : null,
                  child: story.userImage.isEmpty
                      ? Icon(
                          Icons.person,
                          size: avatarRadius * 0.8,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: avatarRadius * 0.2),
            Text(
              story.userName.split(' ').first,
              style: textStyle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}