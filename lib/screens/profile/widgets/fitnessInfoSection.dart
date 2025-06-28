  import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/profile/widgets/profileItem.dart';

Widget buildFitnessInfoSection(BuildContext context , UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fitness Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              
              // Height
              buildProfileItem(
                context,
                Icons.height,
                'Height',
                user.height != null 
                    ? '${user.height} cm' 
                    : 'Not specified',
              ),
              
              const SizedBox(height: 12),
              
              // Weight
              buildProfileItem(
                context,
                Icons.monitor_weight,
                'Weight',
                user.weight != null 
                    ? '${user.weight} kg' 
                    : 'Not specified',
              ),
              
              const SizedBox(height: 12),
              
              // Fitness goal
              buildProfileItem(
                context,
                Icons.flag,
                'Fitness Goal',
                user.fitnessGoal != null 
                    ? formatEnumName(user.fitnessGoal.toString()) 
                    : 'Not specified',
              ),
              
              const SizedBox(height: 12),
              
              // Training days
              buildProfileItem(
                context,
                Icons.calendar_view_week,
                'Training Days',
                user.trainingDaysPerWeek != null 
                    ? '${user.trainingDaysPerWeek} days per week' 
                    : 'Not specified',
              ),
            ],
          ),
        ),
      ),
    );
  }
  String formatEnumName(String enumString) {
    final name = enumString.split('.').last;
    return name[0].toUpperCase() + 
      name.substring(1).replaceAllMapped(
        RegExp('[A-Z]'), 
        (match) => ' ${match.group(0)}'
      );
  }