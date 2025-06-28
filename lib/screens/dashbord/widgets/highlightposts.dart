import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class HighlightPostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLike; // Callback for the like action

  const HighlightPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(),
              if (post.imageUrls.isNotEmpty) _buildPostImage(),
              _buildPostContent(),
              const Spacer(), // Pushes the footer to the bottom
              _buildPostFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: post.userImage.isNotEmpty
                ? CachedNetworkImageProvider(post.userImage)
                : null,
            backgroundColor: Colors.grey.shade200,
            child: post.userImage.isEmpty
                ? Text(post.userName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeago.format(post.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: post.imageUrls[0],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        post.content,
        maxLines:
            post.imageUrls.isNotEmpty ? 2 : 5, // More lines if no image
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade800, height: 1.4),
      ),
    );
  }

  Widget _buildPostFooter() {
    // **FIXED**: Check if the current user has liked the post.
    final bool isLiked = post.likes.contains(currentUserId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          )),
      child: Row(
        children: [
          // **FIXED**: Use a GestureDetector to make the like icon tappable.
          GestureDetector(
            onTap: onLike,
            child: _buildStatIcon(
              // **FIXED**: Show a filled or empty heart based on like status.
              isLiked ? Icons.favorite : Icons.favorite_border,
              post.likes.length.toString(),
              // **FIXED**: Change color based on like status.
              isLiked ? Colors.red : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 20),
          _buildStatIcon(Icons.chat_bubble_outline, post.comments.length.toString(), Colors.grey.shade600),
          const Spacer(),
          Text(
            "View Post",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, color: Colors.red[700], size: 16),
        ],
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          count,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
