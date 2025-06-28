import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

// A simple data class for our placeholder workout cards.
class _FakeWorkout {
  final String title;
  final String duration;
  final String calories;
  final String imageUrl;

  _FakeWorkout({
    required this.title,
    required this.duration,
    required this.calories,
    required this.imageUrl,
  });
}

class PlaceholderWorkouts extends StatefulWidget {
  const PlaceholderWorkouts({super.key});

  @override
  State<PlaceholderWorkouts> createState() => _PlaceholderWorkoutsState();
}

class _PlaceholderWorkoutsState extends State<PlaceholderWorkouts> {
  // A list of sample data to display in the slider.
  final List<_FakeWorkout> _fakeWorkouts = [
    _FakeWorkout(
      title: 'Full Body Shred',
      duration: '45min',
      calories: '550kcal',
      imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?fit=crop&w=800&q=80',
    ),
    _FakeWorkout(
      title: 'Morning Yoga Flow',
      duration: '30min',
      calories: '200kcal',
      imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?fit=crop&w=800&q=80',
    ),
    _FakeWorkout(
      title: 'HIIT Cardio Blast',
      duration: '25min',
      calories: '400kcal',
      imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?fit=crop&w=800&q=80',
    ),
     _FakeWorkout(
      title: 'Core & Abs Sculpt',
      duration: '20min',
      calories: '250kcal',
      imageUrl: 'https://images.unsplash.com/photo-1598266663999-abe9364b4348?fit=crop&w=800&q=80',
    ),
  ];

  late final PageController _pageController;
  late final Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85, // Makes the next card partially visible
      initialPage: _currentPage,
    );

    // Timer to auto-scroll the slider every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _fakeWorkouts.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Workouts",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
               Text(
                "See All",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _fakeWorkouts.length,
            itemBuilder: (context, index) {
              final workout = _fakeWorkouts[index];
              return _buildWorkoutCard(workout);
            },
          ),
        ),
      ],
    );
  }

  // Builds a single, beautifully designed placeholder card.
  Widget _buildWorkoutCard(_FakeWorkout workout) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = (_pageController.page ?? 0) - _fakeWorkouts.indexOf(workout);
          value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
        }
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: CachedNetworkImageProvider(workout.imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.8)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            workout.duration,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                       child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            workout.calories,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  workout.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)]
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
