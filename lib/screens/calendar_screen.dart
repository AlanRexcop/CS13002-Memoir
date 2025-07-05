// C:\dev\memoir\lib\screens\calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

class CalendarEventEntry {
  final Event event;
  final Note parentNote;

  CalendarEventEntry(this.event, this.parentNote);
}

class CalendarScreen extends ConsumerStatefulWidget {
  // --- NEW: Optional parameter to set the initial date ---
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
    // --- NEW: Use the initialDate if provided, otherwise default to now ---
    final initial = widget.initialDate ?? DateTime.now();
    _focusedDay = initial;
    _selectedDay = initial;
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<CalendarEventEntry> _getEventsForDay(DateTime day, Map<DateTime, List<CalendarEventEntry>> source) {
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
    for (var person in allPersons) {
      for (var note in [person.info, ...person.notes]) {
        for (var event in note.events) {
          final dayKey = DateTime.utc(event.time.year, event.time.month, event.time.day);
          if (eventsSource[dayKey] == null) eventsSource[dayKey] = [];
          eventsSource[dayKey]!.add(CalendarEventEntry(event, note));
        }
      }
    }
    
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