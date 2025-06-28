import 'package:flutter/material.dart';

// Top-level function for reuse
Widget buildNavItem(
  IconData icon,
  String label,
  bool isActive,
  int index,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class BottomNavigationbar extends StatefulWidget {
  const BottomNavigationbar({Key? key}) : super(key: key);

  @override
  _BottomNavigationbarState createState() => _BottomNavigationbarState();
}

class _BottomNavigationbarState extends State<BottomNavigationbar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildNavItem(
          Icons.home,
          'Home',
          _currentIndex == 0,
          0,
          () => setState(() => _currentIndex = 0),
        ),
        buildNavItem(
          Icons.search,
          'Search',
          _currentIndex == 1,
          1,
          () => setState(() => _currentIndex = 1),
        ),
        buildNavItem(
          Icons.person,
          'Profile',
          _currentIndex == 2,
          2,
          () => setState(() => _currentIndex = 2),
        ),
      ],
    );
  }
}