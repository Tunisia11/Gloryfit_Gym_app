import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/onboarding/steps/personal_info_step.dart';
import 'package:gloryfit_version_3/screens/onboarding/steps/body_metrics_step.dart';
import 'package:gloryfit_version_3/screens/onboarding/steps/fitness_goals_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final userState = context.read<UserCubit>().state;
    if (userState is OnboardingInProgress) {
      _currentPage = userState.currentStep;
    }
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        // This listener will react to state changes and move the page
        if (state is OnboardingInProgress && state.currentStep != _currentPage) {
           _goToPage(state.currentStep);
        }
      },
      builder: (context, state) {
        if (state is OnboardingInProgress) {
          final pages = [
            PersonalInfoStep(user: state.user),
            BodyMetricsStep(user: state.user),
            FitnessGoalsStep(user: state.user),
          ];

          return Scaffold(
            backgroundColor: const Color(0xFF101010),
            appBar: AppBar(
              backgroundColor: const Color(0xFF101010),
              elevation: 0,
              leading: _currentPage > 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () {
                         final prevPage = _currentPage - 1;
                         context.read<UserCubit>().setOnboardingStep(prevPage);
                      },
                    )
                  : null,
              title: Text(
                'Step ${_currentPage + 1} of ${pages.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: (_currentPage) / pages.length,
                      end: (_currentPage + 1) / pages.length,
                    ),
                    builder: (context, value, child) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey.shade800,
                      color: Colors.white,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pages.length,
                    onPageChanged: (page) {
                       setState(() {
                         _currentPage = page;
                       });
                    },
                    itemBuilder: (context, index) {
                      return pages[index];
                    },
                  ),
                ),
              ],
            ),
          );
        }

        // Fallback for other states
        return const Scaffold(
          backgroundColor: Color(0xFF101010),
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
