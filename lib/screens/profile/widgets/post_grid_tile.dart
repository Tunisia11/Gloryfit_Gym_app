import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostGridTile extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostGridTile({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: post.imageUrls.isNotEmpty
                ? CachedNetworkImageProvider(post.imageUrls.first)
                : const AssetImage('assets/placeholder.png')
                    as ImageProvider, // Add a placeholder asset
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              if (post.isQuestion)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      post.likes.length.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.comment, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      post.comments.length.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
