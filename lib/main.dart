// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/core/bloc_observer.dart';
import 'package:gloryfit_version_3/cubits/admin/admin_cubit.dart';
import 'package:gloryfit_version_3/cubits/auth/auth_cubit.dart';
import 'package:gloryfit_version_3/cubits/auth/auth_states.dart' as auth_states;
import 'package:gloryfit_version_3/cubits/classes/classes_cubit.dart';
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/nutrition/cubit.dart';
import 'package:gloryfit_version_3/cubits/post/post_cubit.dart';
import 'package:gloryfit_version_3/cubits/stepsCubit/step_cubit.dart';
import 'package:gloryfit_version_3/cubits/story/cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/firebase_options.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/auth/LoadingScreen.dart';
import 'package:gloryfit_version_3/screens/auth/login_screen.dart';
import 'package:gloryfit_version_3/screens/dashbord/screen/dashbord.dart';
import 'package:gloryfit_version_3/screens/onboarding/onboarding_screen.dart';
import 'package:gloryfit_version_3/service/auth_service.dart';
import 'package:gloryfit_version_3/service/class_service.dart';
import 'package:gloryfit_version_3/service/event_service.dart';
import 'package:gloryfit_version_3/service/exercise_service.dart';
import 'package:gloryfit_version_3/service/story_sevice.dart';
import 'package:gloryfit_version_3/service/user_service.dart';
import 'package:gloryfit_version_3/service/workout_service.dart';
import 'package:gloryfit_version_3/services/admin_service.dart';
import 'package:gloryfit_version_3/services/post_service.dart';
import 'package:gloryfit_version_3/services/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Permission.notification.request();
    await Permission.activityRecognition.request();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://nuzxgyavbihtmtzrlepk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51enhneWF2YmlodG10enJsZXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4ODU1NTAsImV4cCI6MjA2MjQ2MTU1MH0.UUyaFif2dGO36DRCWmqSmhlVe0KojrpVl3ihwdLyGPU',
  );
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(AuthService())),
        BlocProvider(
          create: (context) => UserCubit(
            UserService(),
            WorkoutService(),
            context.read<AuthCubit>(),
          ),
        ),
        BlocProvider(create: (context) => WorkoutCubit(WorkoutService())),
        BlocProvider(create: (context) => AdminCubit(AdminService() ,ClassService(), WorkoutService(), ExerciseService())),
        // **ADDED**: Provide ClassCubit so it's available to the dashboard.
        BlocProvider(
            create: (context) => ClassCubit(ClassService())..loadClasses()),
            // In main.dart
BlocProvider(create: (context) => EventCubit(EventService())),
        BlocProvider(
            create: (context) =>
                PostCubit(PostService(storageService: StorageService()))),
        BlocProvider(create: (context) => StoryCubit(StoryService())),
        BlocProvider(create: (context) => NutritionCubit()),
      ],
      child: MaterialApp(
        title: 'GloryFit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// **REWRITTEN**: The logic is now driven by the AuthCubit first.
/// This prevents race conditions during login and logout.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, auth_states.AuthState>(
      builder: (context, authState) {
        if (authState is auth_states.AuthUnauthenticated) {
          // If unauthenticated, show the login screen
          return const LoginScreen();
          
        }
        if (authState is auth_states.AuthLoading) {
          return const ModernLoadingScreen();
        }

        if (authState is auth_states.AuthAuthenticated) {
          // Once authenticated, the UI is driven by the UserCubit's state
          return BlocBuilder<UserCubit, UserState>(
            builder: (context, userState) {
              if (userState is UserLoading || userState is UserInitial) {
                // Show loading while the user profile is being fetched
                return const ModernLoadingScreen();
              }
              if (userState is OnboardingInProgress) {
                return OnboardingScreen();
              }
              if (userState is UserLoaded ||
                  userState is UserLoadedWithInProgressWorkout) {
                final user = (userState as dynamic).user as UserModel;
                return BlocProvider(
                  create: (context) => StepCubitV2(
                    userWeight: user.weight ?? 70.0,
                    userHeight: user.height ?? 170.0,
                    userId: user.id,
                  ),
                  child: Dashbord(user: user),
                );
              }
              if (userState is UserError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text(userState.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<AuthCubit>().signOut(),
                          child: const Text('Sign Out'),
                        )
                      ],
                    ),
                  ),
                );
              }
              // Fallback for any unhandled user state
              return const ModernLoadingScreen();
            },
          );
        }

        // If authState is anything else (e.g., AuthUnauthenticated), show login screen
        return const LoginScreen();
      },
    );
  }
}
