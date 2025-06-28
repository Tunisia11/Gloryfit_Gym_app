// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.userImage.isNotEmpty
                        ? CachedNetworkImageProvider(post.userImage)
                        : null,
                    child: post.userImage.isEmpty ? Text(post.userName[0].toUpperCase()) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(timeago.format(post.createdAt), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
            
            // Post Content
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(post.content),
              ),
              
            // Post Image
            if (post.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrls[0],
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),

            // Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onLike,
                        icon: Icon(
                          post.likes.isNotEmpty ? Icons.favorite : Icons.favorite_border,
                          color: post.likes.isNotEmpty ? Colors.red : Colors.grey[600],
                        ),
                      ),
                      if (post.likes.isNotEmpty) Text('${post.likes.length}'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onTap,
                        icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
                      ),
                       if (post.comments.isNotEmpty) Text('${post.comments.length}'),
                    ],
                  ),
                  IconButton(
                    onPressed: () { /* Share action */ },
                    icon: Icon(Icons.share_outlined, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}