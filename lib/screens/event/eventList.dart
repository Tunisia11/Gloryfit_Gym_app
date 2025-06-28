import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';
import 'package:gloryfit_version_3/cubits/event/eventState.dart';
import 'package:gloryfit_version_3/models/event/eventmodel.dart';
import 'package:gloryfit_version_3/screens/event/eventScreenid.dart';
import 'package:intl/intl.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upcoming Events")),
      body: BlocConsumer<EventCubit, EventState>(
        listener: (context, state) {
           if(state is EventError){
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
           } else if (state is EventOperationSuccess){
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
           }
        },
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventsLoaded) {
            if (state.events.isEmpty) {
               return const Center(child: Text("No upcoming events. Check back soon!"));
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<EventCubit>().loadEvents(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.events.length,
                itemBuilder: (context, index) {
                  final event = state.events[index];
                  return EventCard(event: event);
                },
              ),
            );
          }
          return const Center(child: Text("Failed to load events."));
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<EventCubit>(), // Pass existing cubit
                child: EventDetailScreen(event: event),
              ),
            ));
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(height: 200, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
                errorWidget: (ctx, url, err) => Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.error)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(DateFormat.yMMMd().add_jm().format(event.eventDate), style: TextStyle(color: Colors.grey.shade800)),
                    ],
                  ),
                   const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(event.location, style: TextStyle(color: Colors.grey.shade800)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
