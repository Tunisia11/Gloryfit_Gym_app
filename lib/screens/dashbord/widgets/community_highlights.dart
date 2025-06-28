import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/post/post_cubit.dart';
import 'package:gloryfit_version_3/cubits/post/post_states.dart';
import 'package:gloryfit_version_3/screens/dashbord/widgets/highlightposts.dart';
import 'package:gloryfit_version_3/screens/posts/post_detail_screen.dart';


class CommunityHighlights extends StatelessWidget {
  const CommunityHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCubit, PostState>(
      builder: (context, state) {
        if (state is PostLoaded && state.posts.isNotEmpty) {
          final highlightedPosts = state.posts.take(5).toList();
          // **FIXED**: Get the PostCubit instance to access userId and actions.
          final postCubit = context.read<PostCubit>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "From the Community",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "View All",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 340,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: highlightedPosts.length,
                  itemBuilder: (context, index) {
                    final post = highlightedPosts[index];
                    return HighlightPostCard(
                      post: post,
                      // **FIXED**: Pass the current user's ID.
                      currentUserId: postCubit.userId,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: postCubit,
                              child: PostDetailScreen(post: post),
                            ),
                          ),
                        );
                      },
                      // **FIXED**: Pass the like function.
                      onLike: () {
                        postCubit.toggleLike(post);
                      },
                    );
                  },
                ),
              )
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
