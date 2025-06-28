import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/classes/classes_cubit.dart';
import 'package:gloryfit_version_3/cubits/classes/states.dart';

import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/classes/screens/admin/createclass.dart';
import 'package:gloryfit_version_3/screens/classes/screens/classDetilsScreen.dart';
import 'package:gloryfit_version_3/screens/classes/widgets/classCard.dart';
import 'package:gloryfit_version_3/screens/classes/widgets/weeklyclander.dart';


class ClassesListScreen extends StatelessWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Classes'),
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
      ),
      body: BlocConsumer<ClassCubit, ClassState>(
        listener: (context, state) {
          if (state is ClassError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is ClassOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ));
          }
        },
        builder: (context, state) {
          if (state is ClassLoading && state is! ClassesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClassesLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<ClassCubit>().loadClasses(),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // **ADDED**: The new weekly calendar at the top of the screen.
                  WeeklyClassCalendar(allclasses: state.classes),
                  
                  const Divider(height: 32, thickness: 1, indent: 20, endIndent: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Browse All Classes",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),

                  if (state.classes.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No classes available yet.'),
                    ))
                  else
                    // The original list of all classes, now in the same scroll view.
                    ListView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.classes.length,
                      itemBuilder: (context, index) {
                        final aClass = state.classes[index];
                        return ClassCard(
                          aClass: aClass,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<ClassCubit>(),
                                  child: ClassDetailScreen(aClass: aClass),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          }
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      floatingActionButton: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          UserModel? currentUser;
          if (userState is UserLoaded) {
            currentUser = userState.user;
          } else if (userState is UserLoadedWithInProgressWorkout) {
            currentUser = userState.user;
          }

          if (currentUser != null &&
              (currentUser.role == UserRole.admin ||
                  currentUser.role == UserRole.trainer)) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                            value: context.read<ClassCubit>(),
                            child: const CreateClassScreen(),
                          )),
                );
              },
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
