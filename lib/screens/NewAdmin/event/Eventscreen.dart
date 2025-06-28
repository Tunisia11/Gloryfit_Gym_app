import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';
import 'package:gloryfit_version_3/cubits/event/eventState.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/event/createEventScreen.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/event/ticketScanner.dart';

class ManageEventsScreen extends StatelessWidget {
  const ManageEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<EventCubit, EventState>(
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventsLoaded) {
            if (state.events.isEmpty) {
              return const Center(child: Text("No events created yet."));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.events.length,
              itemBuilder: (context, index) {
                final event = state.events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${event.attendeeIds.length} Attendees'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navigate to an edit event screen
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text("Failed to load events."));
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create_event_fab',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<EventCubit>(),
                  child: const CreateEventScreen(),
                ),
              ));
            },
            label: const Text("Create Event"),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
           FloatingActionButton.extended(
            heroTag: 'scan_ticket_fab',
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const TicketScannerScreen(),
              ));
            },
            label: const Text("Scan Ticket"),
            icon: const Icon(Icons.qr_code_scanner),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
