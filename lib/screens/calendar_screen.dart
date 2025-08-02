// C:\dev\memoir\lib\screens\calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teno_rrule/teno_rrule.dart';

class CalendarEventEntry {
  final Event event;
  final Note parentNote;

  CalendarEventEntry(this.event, this.parentNote);
}

class CalendarScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const CalendarScreen({super.key, this.initialDate});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  late DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _focusedDay = initial;
    _selectedDay = initial;
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<CalendarEventEntry> _getEventsForDay(
      DateTime day, Map<DateTime, List<CalendarEventEntry>> source) {
    return source[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPersons = ref.watch(appProvider).persons;

    final Map<DateTime, List<CalendarEventEntry>> eventsSource = {};

    // Get the visible range from the calendar to optimize instance generation.
    // Instead of just the focused month, we need the entire visible grid range,
    // which for `CalendarFormat.month` is typically 6 weeks.
    final firstDayOfMonth = DateTime.utc(_focusedDay.year, _focusedDay.month, 1);
    
    // The calendar's default starting day is Sunday. `DateTime.weekday` is 7 for Sunday.
    // This calculation finds the Sunday on or before the first day of the month.
    final daysToSubtract = firstDayOfMonth.weekday % 7;
    final firstVisibleDay = firstDayOfMonth.subtract(Duration(days: daysToSubtract));

    // The end of the visible range is 6 weeks (42 days) after the start.
    final lastVisibleDay = firstVisibleDay.add(const Duration(days: 42));


    for (var person in allPersons) {
      for (var note in [person.info, ...person.notes]) {
        for (var event in note.events) {
          if (event.rrule == null || event.rrule!.isEmpty) {
            // It's a single event
            final dayKey =
            DateTime.utc(event.time.year, event.time.month, event.time.day);
            if (eventsSource[dayKey] == null) eventsSource[dayKey] = [];
            eventsSource[dayKey]!.add(CalendarEventEntry(event, note));
          } else {
            // It's a recurring event
            try {
              final dtStart = DateFormat("yyyyMMdd'T'HHmmss'Z'")
                  .format(event.time.toUtc());
              final rruleString = 'DTSTART:$dtStart\n${event.rrule!}';
              final rrule = RecurrenceRule.from(rruleString);
              if (rrule != null) {
                final instances = rrule.between(
                    firstVisibleDay.toUtc(), lastVisibleDay.toUtc());
                for (final instance in instances) {
                  final dayKey =
                  DateTime.utc(instance.year, instance.month, instance.day);
                  if (eventsSource[dayKey] == null) eventsSource[dayKey] = [];
                  // Create a new event object for this specific instance to show correct time
                  final instanceEvent = Event(
                      info: event.info,
                      time: instance.toLocal(),
                      rrule: event.rrule);
                  eventsSource[dayKey]!
                      .add(CalendarEventEntry(instanceEvent, note));
                }
              }
            } catch (e) {
              print(
                  'Error parsing rrule: "${event.rrule}" for event "${event.info}". Error: $e');
              // Optionally add the base event as a fallback if parsing fails
              final dayKey = DateTime.utc(
                  event.time.year, event.time.month, event.time.day);
              if (eventsSource[dayKey] == null) eventsSource[dayKey] = [];
              eventsSource[dayKey]!.add(CalendarEventEntry(event, note));
            }
          }
        }
      }
    }

    final selectedDayEvents = _getEventsForDay(_selectedDay!, eventsSource);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, size: 30,),
            tooltip: 'Go to Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar<CalendarEventEntry>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              daysOfWeekHeight: 30.0,
              eventLoader: (day) => _getEventsForDay(day, eventsSource),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.primary),
                rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                weekendStyle: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              calendarStyle: CalendarStyle(
                defaultDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0)),
                weekendDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0)),
                outsideDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0)),
                holidayDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0)),
                disabledDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0)),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                selectedTextStyle: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                todayDecoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                todayTextStyle: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                outsideTextStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                weekendTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
                defaultTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;

                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                      ),
                      child: Center(
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
            const SizedBox(height: 8.0),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, index) {
                final entry = selectedDayEvents[index];
                return Card(
                  // color: colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: colorScheme.outline, width: 1),
                  ),
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(entry.event.info,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10,),
                          Row(
                            children: [

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple[50],
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(entry.event.time.toLocal()),
                                  style: TextStyle(
                                    color: Colors.deepPurple[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple[50],
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  DateFormat('h:mm a')
                                      .format(entry.event.time.toLocal()),
                                  style: TextStyle(
                                    color: Colors.deepPurple[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // if (entry.parentNote.tags.isNotEmpty)
                          //   Wrap(
                          //     spacing: 4.0,
                          //     runSpacing: 4.0,
                          //     children: entry.parentNote.tags
                          //         .map((tag) => Chip(
                          //       label: Text(tag),
                          //       padding: EdgeInsets.zero,
                          //       visualDensity: VisualDensity.compact,
                          //       labelStyle: const TextStyle(fontSize: 10),
                          //     ))
                          //         .toList(),
                          //   ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                NoteViewScreen(note: entry.parentNote),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}