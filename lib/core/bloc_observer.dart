import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    developer.log(
      '🔄 ${bloc.runtimeType} State Change',
      name: 'BlocObserver',
      error: 'Current State: ${change.currentState}\nNext State: ${change.nextState}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    developer.log(
      '❌ ${bloc.runtimeType} Error',
      name: 'BlocObserver',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    developer.log(
      '🎯 ${bloc.runtimeType} Event',
      name: 'BlocObserver',
      error: 'Event: $event',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    developer.log(
      '⚡ ${bloc.runtimeType} Transition',
      name: 'BlocObserver',
      error: 'Event: ${transition.event}\nCurrent State: ${transition.currentState}\nNext State: ${transition.nextState}',
    );
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    developer.log(
      '✨ ${bloc.runtimeType} Created',
      name: 'BlocObserver',
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    developer.log(
      '🔒 ${bloc.runtimeType} Closed',
      name: 'BlocObserver',
    );
  }
} 