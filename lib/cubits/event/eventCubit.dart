
// lib/cubits/events/event_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/event/eventState.dart';
import 'package:gloryfit_version_3/models/event/eventmodel.dart';

import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/service/event_service.dart';


class EventCubit extends Cubit<EventState> {
  final EventService _eventService;
  EventCubit(this._eventService) : super(EventInitial());

  Future<void> loadEvents() async {
    try {
      emit(EventLoading());
      final events = await _eventService.getAllEvents();
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> createEvent(Event event) async {
    try {
      emit(EventLoading());
      await _eventService.createEvent(event);
      emit(const EventOperationSuccess("Event created successfully!"));
      loadEvents();
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }
  
  Future<void> joinEvent(Event event, UserModel user, {String? ticketCode}) async {
    try {
      // Don't emit loading here to keep UI responsive
      await _eventService.joinEvent(event, user, ticketCode: ticketCode);
      emit(const EventOperationSuccess("Successfully joined event! Your ticket is generated."));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }
  
  Future<void> loadMyTickets(String userId) async {
     try {
      emit(EventLoading());
      final tickets = await _eventService.getMyTickets(userId);
      emit(EventTicketsLoaded(tickets));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }
}
