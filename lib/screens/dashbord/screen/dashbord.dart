import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/Nutrution/dietOnbording.dart';
import 'package:gloryfit_version_3/screens/classes/screens/classesListScrenn.dart';

import 'package:gloryfit_version_3/screens/dashbord/screen/homeDashbord.dart';
import 'package:gloryfit_version_3/screens/newWorkoutSystemScreens/workoutlist.dart';
import 'package:gloryfit_version_3/screens/posts/posts_screen.dart';

class Dashbord extends StatefulWidget {
  final UserModel user;
  const Dashbord({super.key, required this.user});

  @override
  State<Dashbord> createState() => _DashbordState();
}

class _DashbordState extends State<Dashbord> {
  // **MODIFIED**: Start on the Home tab (index 0)
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // **ADDED**: The list of screens now includes the new ClassesListScreen.
    final List<Widget> screens = [
      HomeScreen(user: widget.user),
      const WorkoutsListScreen(),
      const ClassesListScreen(), // New screen added here!
      const PostsScreen(),
      NutritionDashboardScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.fitness_center, 'Workouts', 1),
            _buildNavItem(Icons.school, 'Classes', 2), // New nav item!
            _buildNavItem(Icons.forum, 'Community', 3),
            _buildNavItem(Icons.local_pizza, 'Nutrition', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.red[700] : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.red[700] : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
