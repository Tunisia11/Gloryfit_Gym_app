import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/cubits/classes/classes_cubit.dart';
import 'package:gloryfit_version_3/models/classes/class_model.dart';

import 'package:gloryfit_version_3/screens/classes/screens/classDetilsScreen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/intl.dart';

class WeeklyClassCalendar extends StatefulWidget {
  final List<Class> allclasses;
  const WeeklyClassCalendar({super.key, required this.allclasses});

  @override
  State<WeeklyClassCalendar> createState() => _WeeklyClassCalendarState();
}

class _WeeklyClassCalendarState extends State<WeeklyClassCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Class> _selectedClasses = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _filterClassesForSelectedDay();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _filterClassesForSelectedDay();
      });
    }
  }

  void _filterClassesForSelectedDay() {
    if (_selectedDay == null) return;
    final dayOfWeek = _selectedDay!.weekday;

    setState(() {
      _selectedClasses = widget.allclasses.where((aClass) {
        final isWithinDateRange =
            (_selectedDay!.isAfter(aClass.schedule.startDate) ||
                isSameDay(_selectedDay, aClass.schedule.startDate)) &&
            (_selectedDay!.isBefore(aClass.schedule.endDate) ||
                isSameDay(_selectedDay, aClass.schedule.endDate));

        final runsOnThisDay = aClass.schedule.daysOfWeek.contains(dayOfWeek);

        return isWithinDateRange && runsOnThisDay;
      }).toList();
      // Sort classes by time of day
      _selectedClasses.sort((a, b) => a.schedule.timeOfDay.compareTo(b.schedule.timeOfDay));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendar(),
        _buildScheduledClassesList(),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.week,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.red.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledClassesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Scheduled for ${DateFormat.yMMMEd().format(_selectedDay!)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_selectedClasses.isEmpty)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: const Text(
                "No classes scheduled for this day.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedClasses.length,
              itemBuilder: (context, index) {
                final aClass = _selectedClasses[index];
                return _ScheduledClassTile(aClass: aClass);
              },
            ),
        ],
      ),
    );
  }
}

class _ScheduledClassTile extends StatelessWidget {
  final Class aClass;
  const _ScheduledClassTile({required this.aClass});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ClassCubit>(),
              child: ClassDetailScreen(aClass: aClass),
            ),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: aClass.coverImageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(aClass.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('at ${aClass.schedule.timeOfDay}',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('with ${aClass.trainerName}',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
