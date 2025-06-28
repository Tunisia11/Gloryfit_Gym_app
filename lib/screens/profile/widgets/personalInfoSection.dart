import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/profile/widgets/profileItem.dart';
import 'package:intl/intl.dart';

Widget buildPersonalInfoSection(BuildContext context , UserModel user) {
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
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              
              // Date of birth
              buildProfileItem(
                context,
                Icons.calendar_today,
                'Date of Birth',
                user.dateOfBirth != null 
                    ? DateFormat('MMMM d, yyyy').format(user.dateOfBirth!) 
                    : 'Not specified',
              ),
              
              const SizedBox(height: 12),
              
              // Gender
              buildProfileItem(
                context,
                Icons.person,
                'Gender',
                user.gender != null 
                    ? user.gender.toString().split('.').last 
                    : 'Not specified',
              ),
            ],
          ),
        ),
      ),
    );
  }
