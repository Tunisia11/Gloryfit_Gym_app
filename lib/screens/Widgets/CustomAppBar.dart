import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/Helpers/dateformater.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart';


class CustomAppBar extends StatefulWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return _buildHeaderCard();
  }
  @override
  Widget _buildHeaderCard() {
    // Date formatter utility function
String formattedDate() {
  final now = DateTime.now();
  final months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  return '${months[now.month - 1]} ${now.day}, ${now.year}';
}
    return BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          // Default values
          String userName = 'User';
          String photoUrl = '';

          // Update values based on state
          if (state is UserLoaded ) {
            userName = state.user.displayName ?? 'User';
            photoUrl = state.user.photoURL ?? '';
          }
             if (state is OnboardingCompleted ) {
            userName = state.user.displayName ?? 'User';
            photoUrl = state.user.photoURL ?? '';
          }

          return Container(
            margin: const EdgeInsets.all( 10),
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: const BorderRadius.all(Radius.circular(20)),  
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRow(),
                  const SizedBox(height: 16),
                  _buildUserInfoRow(userName, photoUrl),
                ],
              ),
            ),
          );
        },
      
    );
  }

  // Build the date row
  Widget _buildDateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              formattedDate(),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                fontWeight: FontWeight.w900
              ),
            ),
          ],
        ),
        Row(
          children: [
          
            _buildIcon(Icons.notifications_outlined, Colors.orange),
          ],
        ),
      ],
    );
  }

  // Build user info row
  Widget _buildUserInfoRow(String userName, String photoUrl) {
    return Row(
      children: [
        _buildUserAvatar(photoUrl),
        const SizedBox(width: 12),
        _buildUserDetails(userName),
        const Spacer(),
        _buildIcon(Icons.settings, Colors.grey[400]!),
      ],
    );
  }

  // Build user avatar
  Widget _buildUserAvatar(String photoUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        image: photoUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  print('Error loading profile image: $exception');
                },
              )
            : null,
      ),
      child: photoUrl.isEmpty
          ? const Icon(
              Icons.person,
              color: Colors.white,
            )
          : null,
    );
  }

  // Build user details
  Widget _buildUserDetails(String userName) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hello, ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[300],
                    ),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' !',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 8),
                  _buildRoleBadge(state.user.role),
                ],
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color badgeColor;
    IconData badgeIcon;
    String roleText;

    switch (role) {
      case UserRole.admin:
        badgeColor = Colors.red;
        badgeIcon = Icons.admin_panel_settings;
        roleText = 'ADMIN';
        break;
      case UserRole.trainer:
        badgeColor = Colors.green;
        badgeIcon = Icons.fitness_center;
        roleText = 'TRAINER';
        break;
      case UserRole.member:
        badgeColor = Colors.amber;
        badgeIcon = Icons.star;
        roleText = 'MEMBER';
        break;
    }

    return _buildBadge(
      roleText,
      badgeColor,
      badgeColor.withOpacity(0.8),
      icon: badgeIcon,
    );
  }

  // Build badge
  Widget _buildBadge(String text, Color bgColor, Color textColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.yellow,
              size: 12,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),)
          ],
        
      ),
    );
  }

  // Build icon
  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(6),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  // Build "See All" button

}