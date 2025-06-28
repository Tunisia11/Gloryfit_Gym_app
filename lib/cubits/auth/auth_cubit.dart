// lib/cubits/auth/auth_cubit.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/auth/auth_states.dart';
import 'package:gloryfit_version_3/service/auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authService) : super(const AuthInitial()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = _authService.onAuthStateChanged().listen(
      (user) {
        if (isClosed) return;
        print('Auth stream received user: ${user?.uid ?? 'null'}');
        if (user != null) {
          emit(AuthAuthenticated(
            userId: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
          ));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
      onError: (error) {
        if (isClosed) return;
        print('Auth stream error: $error');
        emit(AuthError('Authentication stream error: $error'));
      },
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      print('Starting Google sign in...');
      emit(const AuthLoading());
      await _authService.signInWithGoogle();
      // The stream listener will automatically emit AuthAuthenticated
    } catch (e) {
      print('Google sign in error: $e');
      emit(AuthError('Failed to sign in with Google: ${e.toString()}'));
      // After showing error, go back to unauthenticated state
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(const AuthUnauthenticated());
      }
    }
  }

  /// REFACTORED: signOut now emits AuthLoading for better UI feedback.
  /// The onAuthStateChanged stream will then naturally emit AuthUnauthenticated.
  Future<void> signOut() async {
    try {
      print('Starting sign out...');
      // Emit loading state to give user feedback and prevent double-taps.
      emit(const AuthLoading());
      await _authService.signOut();
      print('Sign out completed');
      // The auth stream listener will automatically catch the sign-out event
      // and emit AuthUnauthenticated.
    } catch (e) {
      print('Sign out error: $e');
      // On error, still force unauthenticated state to be safe.
      emit(const AuthUnauthenticated());
    }
  }

  @override
  void emit(AuthState state) {
    if (!isClosed) {
      print('AuthCubit emitting state: ${state.runtimeType}');
      super.emit(state);
    }
  }

  @override
  Future<void> close() {
    print('AuthCubit closing');
    _authSubscription?.cancel();
    return super.close();
  }
}
