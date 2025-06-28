// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/admin/admin_cubit.dart';
import 'package:gloryfit_version_3/cubits/admin/admin_cubit.dart' as admin_states;
import 'package:gloryfit_version_3/cubits/event/eventCubit.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/event/Eventscreen.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/manageClasses.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/manageExercices.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/manageUsers.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/mangeWorkout.dart';
import 'package:gloryfit_version_3/service/class_service.dart';
import 'package:gloryfit_version_3/service/event_service.dart';
import 'package:gloryfit_version_3/service/exercise_service.dart';
import 'package:gloryfit_version_3/service/workout_service.dart';
import 'package:gloryfit_version_3/services/admin_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AdminCubit(
            AdminService(),
            ClassService(),
            WorkoutService(),
            ExerciseService(),
          )..loadAdminDashboard(),
        ),
        BlocProvider(
          create: (context) => EventCubit(EventService())..loadEvents(),
        ),
      ],
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.dashboard_customize), text: 'Overview'),
                Tab(icon: Icon(Icons.people_outline), text: 'Users'),
                Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
                Tab(icon: Icon(Icons.model_training), text: 'Exercises'),
                Tab(icon: Icon(Icons.school_outlined), text: 'Classes'),
                Tab(icon: Icon(Icons.celebration_outlined), text: 'Events'),
              ],
            ),
          ),
          body: BlocConsumer<AdminCubit, admin_states.AdminState>(
            listener: (context, state) {
              if (state is admin_states.AdminError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
              if (state is admin_states.AdminOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                );
              }
            },
            builder: (context, state) {
              if (state is admin_states.AdminLoading || state is admin_states.AdminInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is admin_states.AdminDashboardLoaded) {
                return TabBarView(
                  children: [
                    _buildOverviewTab(context, state),
                    ManageUsersScreen(users: state.users),
                    const ManageWorkoutsScreen(),
                    const ManageExercisesScreen(),
                    ManageClassesScreen(
                      classes: state.classes,
                      requests: state.joinRequests,
                    ),
                    const ManageEventsScreen(),
                  ],
                );
              }
              return const Center(child: Text('Something went wrong. Please pull to refresh.'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, admin_states.AdminDashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminCubit>().loadAdminDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Statistics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard('Users', state.totalUsers.toString(), Icons.group, Colors.blue),
                _buildStatCard('Classes', state.totalClasses.toString(), Icons.school, Colors.orange),
                _buildStatCard('Workouts', state.totalWorkouts.toString(), Icons.fitness_center, Colors.green),
                _buildStatCard('Exercises', state.totalExercises.toString(), Icons.format_list_bulleted, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
