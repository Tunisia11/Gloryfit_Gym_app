// lib/cubits/events/event_states.dart
import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/event/eventTicketModel.dart';
import 'package:gloryfit_version_3/models/event/eventmodel.dart';


abstract class EventState extends Equatable {
  const EventState();
  @override
  List<Object> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventsLoaded extends EventState {
  final List<Event> events;
  const EventsLoaded(this.events);
  @override
  List<Object> get props => [events];
}

class EventTicketsLoaded extends EventState {
  final List<EventTicket> tickets;
  const EventTicketsLoaded(this.tickets);
  @override
  List<Object> get props => [tickets];
}

class EventOperationSuccess extends EventState {
  final String message;
  const EventOperationSuccess(this.message);
}

class EventError extends EventState {
  final String message;
  const EventError(this.message);
  @override
  List<Object> get props => [message];
}

