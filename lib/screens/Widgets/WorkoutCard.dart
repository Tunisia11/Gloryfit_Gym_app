import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';

/// A card widget that displays a workout preview
/// Used in the dashboard and workout list screens
class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  
  const WorkoutCard({
    Key? key,
    required this.workout,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout image with overlay
            Stack(
              children: [
                // Workout image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    workout.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.fitness_center,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                
                // Stats overlay (duration, calories)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      // Duration chip
                      _buildStatChip(
                        icon: Icons.timer,
                        label: '${workout.estimatedDurationMinutes}min',
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Calories chip
                      _buildStatChip(
                        icon: Icons.local_fire_department,
                        label: '${workout.estimatedCaloriesBurn}kcal',
                      ),
                    ],
                  ),
                ),
                
                // Difficulty badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(workout.difficulty).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyText(workout.difficulty),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Workout details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout name
                  Text(
                    workout.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Series count info
                  Text(
                    '${workout.seriesCount} ${workout.seriesCount > 1 ? 'Series' : 'Series'} Workout',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Trainer info row
                  Row(
                    children: [
                      // Trainer photo
                      if (workout.trainerPhotoUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(workout.trainerPhotoUrl),
                        )
                      else
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      // Trainer name
                      Text(
                        'With ${workout.trainerName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Helper widget to build a stat chip (e.g., duration, calories)
  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get color based on workout difficulty
  Color _getDifficultyColor(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return Colors.green;
      case WorkoutDifficulty.intermediate:
        return Colors.orange;
      case WorkoutDifficulty.advanced:
        return Colors.red;
      case WorkoutDifficulty.expert:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
  
  /// Get text based on workout difficulty
  String _getDifficultyText(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'BEGINNER';
      case WorkoutDifficulty.intermediate:
        return 'INTERMEDIATE';
      case WorkoutDifficulty.advanced:
        return 'ADVANCED';
      case WorkoutDifficulty.expert:
        return 'EXPERT';
      default:
        return 'UNKNOWN';
    }
  }
} 