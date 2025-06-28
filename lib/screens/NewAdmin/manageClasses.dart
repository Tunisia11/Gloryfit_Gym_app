import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/admin/admin_cubit.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:gloryfit_version_3/models/classes/class_model.dart';
import 'package:gloryfit_version_3/models/classes/join_request.dart';

class ManageClassesScreen extends StatelessWidget {
  final List<Class> classes;
  final List<JoinRequest> requests;

  const ManageClassesScreen(
      {super.key, required this.classes, required this.requests});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, 'Pending Join Requests', requests.length),
        const SizedBox(height: 8),
        requests.isEmpty
            ? const Text('No pending requests.')
            : _buildRequestsList(context),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'All Classes', classes.length),
        const SizedBox(height: 8),
        classes.isEmpty
            ? const Text('No classes created yet.')
            : _buildClassesList(context),
      ],
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Chip(label: Text(count.toString())),
      ],
    );
  }

  Widget _buildRequestsList(BuildContext context) {
    return Column(
      children: requests
          .map((request) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              CachedNetworkImageProvider(request.userPhotoUrl),
                        ),
                        title: Text('${request.userName} wants to join'),
                        subtitle: Text(request.className,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            label: const Text('Deny', style: TextStyle(color: Colors.red)),
                            onPressed: () =>
                                context.read<AdminCubit>().denyRequest(request.id),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Approve'),
                            onPressed: () =>
                                context.read<AdminCubit>().approveRequest(request),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildClassesList(BuildContext context) {
    return Column(
      children: classes
          .map((aClass) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        CachedNetworkImageProvider(aClass.coverImageUrl),
                  ),
                  title: Text(aClass.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${aClass.memberIds.length} / ${aClass.capacity} members'),
                  trailing: const Icon(Icons.edit_note),
                  onTap: () {
                    // Navigate to an edit screen
                  },
                ),
              ))
          .toList(),
    );
  }
}
