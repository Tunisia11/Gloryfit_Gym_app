// lib/screens/posts/posts_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/post/post_cubit.dart';
import 'package:gloryfit_version_3/cubits/post/post_states.dart';
import 'package:gloryfit_version_3/cubits/story/cubit.dart';
import 'package:gloryfit_version_3/cubits/story/states.dart';

import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/post_model.dart';
import 'package:gloryfit_version_3/models/user_model.dart' as gloryfit_user;
import 'package:gloryfit_version_3/screens/posts/create_post_screen.dart';
import 'package:gloryfit_version_3/screens/posts/post_detail_screen.dart';
import 'package:gloryfit_version_3/screens/posts/postcard.dart';
import 'package:gloryfit_version_3/screens/posts/story_viewer_screen.dart';
import 'package:gloryfit_version_3/screens/posts/widgets/storybar.dart';

import 'package:image_picker/image_picker.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<PostCubit>().loadPosts();
    context.read<StoryCubit>().loadStories();
  }

  Future<void> _onRefresh() async => _loadData();

  Future<void> _createStory() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (pickedFile == null || !mounted) return;

    final userState = context.read<UserCubit>().state;
    gloryfit_user.UserModel? currentUser;

    if (userState is UserLoaded) currentUser = userState.user;
    if (userState is UserLoadedWithInProgressWorkout) currentUser = userState.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot create story. User not found.')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adding your story...')));
    try {
      await context.read<StoryCubit>().createStory(mediaFile: pickedFile, author: currentUser);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post story: $e')));
    }
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: Colors.red.shade600),
                title: const Text('Add to Your Story', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share a photo or a short video.'),
                onTap: () {
                  Navigator.pop(ctx);
                  _createStory();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_document, color: Colors.blue.shade600),
                title: const Text('Create a Post', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share your thoughts with the community.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<PostCubit>().userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade200,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text('Community', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.add, color: Colors.red.shade600),
            ),
            onPressed: () => _showCreateOptions(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.red.shade600,
        onRefresh: _onRefresh,
        child: Column(
          children: [
            BlocBuilder<StoryCubit, StoryState>(
              builder: (context, state) {
                if (state is StoriesLoaded && state.stories.isNotEmpty) {
                  // **THE FIX**: Pass the correct `groupedStories` map to the StoryBar,
                  // not the simple `stories` list.
                  return StoryBar(groupedStories: state.groupedStories);
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: BlocBuilder<PostCubit, PostState>(
                builder: (context, postState) {
                  if (postState is PostLoading || postState is PostInitial) {
                    return const Center(child: CupertinoActivityIndicator(color: Colors.red));
                  } else if (postState is PostLoaded) {
                    if (postState.posts.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: postState.posts.length,
                      itemBuilder: (context, index) {
                        final post = postState.posts[index];
                        return PostCard(
                          post: post,
                          currentUserId: currentUserId,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<PostCubit>(), child: PostDetailScreen(post: post)))),
                          onLike: () => context.read<PostCubit>().toggleLike(post),
                          onDelete: post.userId == currentUserId ? () => _showDeleteConfirmation(context, post) : null,
                        );
                      },
                    );
                  } else if (postState is PostError) {
                    return Center(child: Text('An error occurred: ${postState.message}'));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ... _buildEmptyState and _showDeleteConfirmation methods remain the same ...
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        CupertinoIcons.bubble_left_bubble_right,
                        size: 50,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Posts Yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share something with the community!',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
             // context.read<PostCubit>().deletePost(post);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}