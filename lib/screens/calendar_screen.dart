// C:\dev\memoir\lib\screens\calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

// A simple helper class to link an event to its source note,
// giving us all the context we need for navigation and display.
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
  // We only need to manage the currently focused/selected day in the local state.
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Initialize the selected day when the screen is first built.
    _selectedDay = _focusedDay;
  }

  // The dispose method is now simpler as we don't have a ValueNotifier.
  @override
  void dispose() {
    super.dispose();
  }

  // Helper function to get the list of entries for a given day from the main source map.
  List<CalendarEventEntry> _getEventsForDay(DateTime day, Map<DateTime, List<CalendarEventEntry>> source) {
    // The key for the map is a UTC date with time set to zero.
    return source[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // Callback for when the user taps a day on the calendar.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // We only call setState if the selected day has actually changed.
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the main app provider. Whenever it changes (e.g., after a note is
    // edited), this entire build method will re-run, ensuring all data is fresh.
    final allPersons = ref.watch(appProvider).persons;
    
    // Build the event source map from scratch on every build. This guarantees it's up-to-date.
    final Map<DateTime, List<CalendarEventEntry>> eventsSource = {};
    for (var person in allPersons) {
      for (var note in [person.info, ...person.notes]) {
        for (var event in note.events) {
          final dayKey = DateTime.utc(event.time.year, event.time.month, event.time.day);
          if (eventsSource[dayKey] == null) eventsSource[dayKey] = [];
          // When we add an event, we wrap it with its parent note for context.
          eventsSource[dayKey]!.add(CalendarEventEntry(event, note));
        }
      }
    }
    
    // Calculate the list for the selected day directly in the build method.
    // This is the key to fixing the state bug.
    final selectedDayEvents = _getEventsForDay(_selectedDay!, eventsSource);

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
            // --- NEW: Custom builders to change marker appearance ---
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
                      color: Theme.of(context).primaryColor,
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
            // --- END NEW ---
            onDaySelected: _onDaySelected,
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
            // We no longer need a ValueListenableBuilder. A simple ListView is sufficient
            // because the `selectedDayEvents` list is recalculated on every build.
            child: ListView.builder(
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, index) {
                final entry = selectedDayEvents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(entry.event.info, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In: "${entry.parentNote.title}" at ${DateFormat('HH:mm').format(entry.event.time.toLocal())}',
                        ),
                        const SizedBox(height: 4),
                        if (entry.parentNote.tags.isNotEmpty)
                          Wrap(
                            spacing: 4.0, runSpacing: 4.0,
                            children: entry.parentNote.tags.map((tag) => Chip(
                              label: Text(tag),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              labelStyle: const TextStyle(fontSize: 10),
                            )).toList(),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Navigation is simple because we have the full parentNote object.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NoteViewScreen(note: entry.parentNote),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}