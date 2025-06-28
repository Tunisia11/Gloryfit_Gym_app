import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';
import 'package:gloryfit_version_3/cubits/event/eventState.dart';

import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/event/eventTicketModel.dart';

import 'package:qr_flutter/qr_flutter.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserCubit>().state;
    if (userState is! UserLoaded) {
      return const Scaffold(body: Center(child: Text("Please log in to see your tickets.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Event Tickets")),
      body: BlocProvider(
        create: (context) => EventCubit(context.read())..loadMyTickets(userState.user.id),
        child: BlocBuilder<EventCubit, EventState>(
          builder: (context, state) {
            if (state is EventLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EventTicketsLoaded) {
              if (state.tickets.isEmpty) {
                return const Center(child: Text("You have no event tickets."));
              }
              return PageView.builder(
                itemCount: state.tickets.length,
                itemBuilder: (context, index) {
                  return TicketCard(ticket: state.tickets[index]);
                },
              );
            }
            return const Center(child: Text("Could not load tickets."));
          },
        ),
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final EventTicket ticket;
  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    // Structured data for the QR code
    final qrData = '{"userId":"${ticket.userId}","ticketId":"${ticket.ticketId}"}';

    return Card(
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(ticket.eventName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
            ),
            Column(
              children: [
                Text("Scan this code at the event entrance.", style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                if (ticket.isUsed)
                  const Chip(label: Text("USED"), backgroundColor: Colors.redAccent)
                else
                  const Chip(label: Text("VALID"), backgroundColor: Colors.greenAccent)
              ],
            )
          ],
        ),
      ),
    );
  }
}

