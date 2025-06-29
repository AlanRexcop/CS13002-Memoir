import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

// A simple helper class to link an event to its source note.
class CalendarEventEntry {
  final Event event;
  final Note parentNote;

  CalendarEventEntry(this.event, this.parentNote);
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // The ValueNotifier now holds our new entry type.
  late final ValueNotifier<List<CalendarEventEntry>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]); 
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // This helper function gets the list of entries for a given day.
  List<CalendarEventEntry> _getEventsForDay(DateTime day, Map<DateTime, List<CalendarEventEntry>> source) {
    return source[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay, Map<DateTime, List<CalendarEventEntry>> source) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay, source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPersons = ref.watch(appProvider).persons;
    // --- THIS IS THE KEY LOGIC CHANGE ---
    // The event source map now stores CalendarEventEntry objects.
    final Map<DateTime, List<CalendarEventEntry>> eventsSource = {};

    for (var person in allPersons) {
      // Iterate over the combined list of info and other notes.
      for (var note in [person.info, ...person.notes]) {
        for (var event in note.events) {
          final dayKey = DateTime.utc(event.time.year, event.time.month, event.time.day);
          if (eventsSource[dayKey] == null) eventsSource[dayKey] = [];
          // When we add an event, we wrap it in our helper class
          // along with a reference to its parent note.
          eventsSource[dayKey]!.add(CalendarEventEntry(event, note));
        }
      }
    }
    
    // Update selected events for the initial day after the source is built.
    if (_selectedEvents.value.isEmpty && eventsSource.isNotEmpty) {
       _selectedEvents.value = _getEventsForDay(_selectedDay!, eventsSource);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Event Calendar')),
      body: Column(
        children: [
          TableCalendar<CalendarEventEntry>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) => _getEventsForDay(day, eventsSource),
            onDaySelected: (selected, focused) => _onDaySelected(selected, focused, eventsSource),
            onFormatChanged: (format) {
              if (_calendarFormat != format) setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder<List<CalendarEventEntry>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(child: Text("No events for this day."));
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    // We now have the full entry object.
                    final entry = value[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text(entry.event.info),
                        subtitle: Text(
                          'In: "${entry.parentNote.title}" at ${DateFormat('HH:mm').format(entry.event.time.toLocal())}',
                        ),
                        onTap: () {
                          // --- THE NAVIGATION IS NOW TRIVIAL ---
                          // We already have the parentNote object, no search needed!
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NoteViewScreen(note: entry.parentNote),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}