import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageUsersScreen extends StatelessWidget {
  final List<UserModel> users;
  const ManageUsersScreen({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
     if (users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                  ? CachedNetworkImageProvider(user.photoURL!)
                  : null,
            ),
            title: Text(user.displayName ?? 'No Name',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
            trailing: Chip(
              label: Text(user.role.name, style: const TextStyle(fontSize: 12)),
              backgroundColor: user.role == UserRole.admin ? Colors.red.shade100 : Colors.grey.shade200,
            ),
             onTap: () {
              // TODO: Open user detail/edit screen
            },
          ),
        );
      },
    );
  }
}