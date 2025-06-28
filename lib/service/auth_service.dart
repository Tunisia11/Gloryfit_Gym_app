// lib/service/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// **FIXED**: Added getter for current user to support state checks
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// **FIXED**: Enhanced auth state stream with better error handling
  Stream<firebase_auth.User?> onAuthStateChanged() {
    return _auth.authStateChanges().handleError((error) {
      print('Firebase auth stream error: $error');
      // Return null user on stream error to maintain consistency
      return null;
    });
  }

  /// **FIXED**: Enhanced session sync with better error handling and validation
  Future<void> syncSupabaseSession() async {
    try {
      final currentUser = _auth.currentUser;
      print('Syncing Supabase session for user: ${currentUser?.uid}');
      
      if (currentUser == null) {
        print('No current Firebase user, skipping Supabase sync');
        return;
      }

      // Check if user is already signed in to Supabase
      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser != null && supabaseUser.id == currentUser.uid) {
        print('Supabase session already exists for user');
        return;
      }

      // Get fresh ID token
      final idToken = await currentUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to get Firebase ID token');
      }

      print('Attempting Supabase sign in with ID token');
      
      // Sign in to Supabase using the Firebase ID token
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user == null) {
        throw Exception('Supabase sign in failed - no user returned');
      }

      print('Supabase session synced successfully for user: ${response.user!.id}');
      
    } catch (e) {
      print('Error syncing Supabase session: $e');
      // Don't rethrow here as this shouldn't block the main auth flow
      // Just log the error for debugging
    }
  }
Future<firebase_auth.UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Use signInWithPopup for web
        print('Starting Google sign in with popup for web...');
        final googleProvider = firebase_auth.GoogleAuthProvider();
        // Optionally, you can add scopes if needed
        // googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
        final userCredential = await _auth.signInWithPopup(googleProvider);

        if (userCredential.user == null) {
          throw Exception('Firebase sign in via popup failed - no user returned');
        }

        print('Firebase web sign in successful for user: ${userCredential.user!.uid}');

        // You still need to handle Supabase sync
        final googleAuth = userCredential.credential as firebase_auth.OAuthCredential?;
        if (googleAuth?.idToken != null) {
             try {
                print('Signing in to Supabase...');
                await _supabase.auth.signInWithIdToken(
                  provider: OAuthProvider.google,
                  idToken: googleAuth!.idToken!,
                  accessToken: googleAuth.accessToken,
                );
                 print('Supabase sign in successful');
              } catch (supabaseError) {
                print('Supabase sign in error (non-fatal): $supabaseError');
              }
        }
        
        return userCredential;

      } else {
        // Keep the existing logic for Android/iOS
        print('Starting Google sign in process for mobile...');
        
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google sign in was cancelled by user');
        }
        
        print('Google user selected: ${googleUser.email}');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        if (googleAuth.idToken == null) {
          throw Exception('Failed to get Google ID token');
        }
        
        if (googleAuth.accessToken == null) {
          throw Exception('Failed to get Google access token');
        }

        print('Google authentication tokens obtained');

        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('Signing in to Firebase...');
        final userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user == null) {
          throw Exception('Firebase sign in failed - no user returned');
        }

        print('Firebase sign in successful for user: ${userCredential.user!.uid}');

        try {
          print('Signing in to Supabase...');
          await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );
           print('Supabase sign in successful');
        } catch (supabaseError) {
          print('Supabase sign in error (non-fatal): $supabaseError');
        }
        
        print('Google sign in process completed successfully');
        return userCredential;
      }
    } catch (e) {
      print('Google sign in error: $e');
      
      try {
        await _googleSignIn.signOut();
      } catch (cleanupError) {
        print('Error during cleanup: $cleanupError');
      }
      
      rethrow;
    }
  }

  /// **FIXED**: Enhanced sign out with immediate state clearing
  Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      
      // Get current user info for logging
      final firebaseUser = _auth.currentUser;
      final supabaseUser = _supabase.auth.currentUser;
      
      print('Signing out Firebase user: ${firebaseUser?.uid}');
      print('Signing out Supabase user: ${supabaseUser?.id}');

      // Sign out from all services in parallel for faster execution
      await Future.wait([
        _signOutFirebase(),
        _signOutGoogle(),
        _signOutSupabase(),
      ], eagerError: false); // Don't stop if one fails

      print('Sign out process completed');
      
    } catch (e) {
      print('Sign out error (non-critical): $e');
      // Don't rethrow for sign out errors - we want to clear state anyway
    }
  }

  /// **FIXED**: Individual Firebase sign out with error handling
  Future<void> _signOutFirebase() async {
    try {
      await _auth.signOut();
      print('Firebase sign out successful');
    } catch (e) {
      print('Firebase sign out error: $e');
      // Don't rethrow - we want to continue with other sign outs
    }
  }

  /// **FIXED**: Individual Google sign out with error handling
  Future<void> _signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('Google sign out successful');
    } catch (e) {
      print('Google sign out error: $e');
      // Don't rethrow - we want to continue with other sign outs
    }
  }

  /// **FIXED**: Individual Supabase sign out with error handling
  Future<void> _signOutSupabase() async {
    try {
      await _supabase.auth.signOut();
      print('Supabase sign out successful');
    } catch (e) {
      print('Supabase sign out error: $e');
      // Don't rethrow - we want to continue with other sign outs
    }
  }

  /// **NEW**: Method to check if user is fully authenticated
  bool get isFullyAuthenticated {
    final firebaseUser = _auth.currentUser;
    final supabaseUser = _supabase.auth.currentUser;
    return firebaseUser != null && supabaseUser != null;
  }

  /// **NEW**: Method to get current session info for debugging
  Map<String, dynamic> get sessionInfo {
    return {
      'firebase_user_id': _auth.currentUser?.uid,
      'firebase_user_email': _auth.currentUser?.email,
      'supabase_user_id': _supabase.auth.currentUser?.id,
      'supabase_user_email': _supabase.auth.currentUser?.email,
      'fully_authenticated': isFullyAuthenticated,
    };
  }

  /// **NEW**: Method to force refresh authentication state
  Future<void> refreshAuthState() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        print('Firebase auth state refreshed');
      }
    } catch (e) {
      print('Error refreshing auth state: $e');
    }
  }
}