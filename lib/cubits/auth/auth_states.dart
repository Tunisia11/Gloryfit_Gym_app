import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final Session? session;

  const AuthAuthenticated({
    required this.userId,
    this.email,
    this.displayName,
    this.photoURL,
    this.session,
  });

  @override
  List<Object?> get props => [userId, email, displayName, photoURL, session];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
