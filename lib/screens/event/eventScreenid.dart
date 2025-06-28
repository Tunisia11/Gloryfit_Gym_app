import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';

import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/event/eventmodel.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.calendar_today, "DATE & TIME", DateFormat.yMMMd().add_jm().format(event.eventDate)),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on, "LOCATION", event.location),
                   const SizedBox(height: 24),
                  const Text("About this event", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                  Text(event.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is! UserLoaded) return const SizedBox.shrink();
        final user = state.user;
        final bool isAttending = event.attendeeIds.contains(user.id);

        if(isAttending) {
          return const Padding(
             padding: EdgeInsets.all(24),
             child: Text("✅ You're going to this event!", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
           );
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.confirmation_number),
            label: const Text("Get Ticket"),
            onPressed: () => _handleJoinEvent(context, user),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        );
      },
    );
  }

  void _handleJoinEvent(BuildContext context, UserModel user){
    if (event.enrollmentType == EventEnrollmentType.ticketCode){
        final codeController = TextEditingController();
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Enter Ticket Code"),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(hintText: "e.g., FIT-PARTY-2025"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  context.read<EventCubit>().joinEvent(event, user, ticketCode: codeController.text.trim());
                  Navigator.pop(dialogContext);
                },
                child: const Text("Submit"),
              ),
            ],
          )
        );
    } else {
       context.read<EventCubit>().joinEvent(event, user);
    }
  }
}
