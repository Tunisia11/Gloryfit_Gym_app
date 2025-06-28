import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/user_model.dart';

Widget buildProfileHeader(BuildContext context , UserModel user) {
    return Container(
      width: double.infinity,
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // User avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null || user.photoURL!.isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.blue)
                : null,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading profile image: $exception');
            },
          ),
          
          const SizedBox(height: 4),
          
          // User email
          Text(
            user.email ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // User role badge
          if (user.role == UserRole.admin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
