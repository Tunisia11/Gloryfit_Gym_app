import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';
import 'package:gloryfit_version_3/cubits/event/eventState.dart';

import 'package:gloryfit_version_3/service/event_service.dart';
// Other necessary imports...

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upcoming Events")),
      body: BlocProvider(
        create: (context) => EventCubit(EventService())..loadEvents(),
        child: BlocBuilder<EventCubit, EventState>(
          builder: (context, state) {
            if (state is EventLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EventsLoaded) {
              if (state.events.isEmpty) {
                 return const Center(child: Text("No upcoming events."));
              }
              return ListView.builder(
                itemCount: state.events.length,
                itemBuilder: (context, index) {
                  final event = state.events[index];
                  // Create an EventCard widget (similar to ClassCard)
                  // to display event details and navigate to EventDetailScreen on tap.
                  return Card(
                     margin: const EdgeInsets.all(12),
                     child: ListTile(
                       leading: Image.network(event.imageUrl, width: 80, fit: BoxFit.cover),
                       title: Text(event.name),
                       subtitle: Text("${event.location} - ${event.eventDate.toLocal()}"),
                       onTap: () {
                          // Navigate to EventDetailScreen
                       },
                     ),
                  );
                },
              );
            }
            return const Center(child: Text("Failed to load events."));
          },
        ),
      ),
    );
  }
}