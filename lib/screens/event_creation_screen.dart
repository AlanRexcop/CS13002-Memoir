// C:\dev\memoir\lib\screens\event_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrule_generator/rrule_generator.dart';

class EventCreationScreen extends StatefulWidget {
  final String eventTitle;

  const EventCreationScreen({super.key, required this.eventTitle});

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  late DateTime _selectedDate;
  String? _rrule;

  @override
  void initState() {
    super.initState();
    // Default to the next hour
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    setState(() {
      _selectedDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _onRRuleChanged(String? value) {
    // Do not call setState here. RRuleGenerator handles its own UI updates.
    // We just need to store the latest rrule string for when we save.
    _rrule = value;
  }

  void _saveEvent() {
    String markdown;
    // Format to YYYY-MM-DDTHH:MM:SS, which is parsable by DateTime.parse
    final dtStart = _selectedDate.toIso8601String().split('.').first;
    if (_rrule == null || _rrule!.isEmpty) {
      markdown = ' {event}[${widget.eventTitle}]($dtStart) ';
    } else {
      // The rrule string from the generator already starts with "RRULE:"
      markdown = ' {event}[${widget.eventTitle}]($dtStart;$_rrule) ';
    }
    Navigator.of(context).pop(markdown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event: ${widget.eventTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Event',
            onPressed: _saveEvent,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start Date & Time',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMMd().add_jm().format(_selectedDate),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.normal),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Change'),
                  onPressed: _pickDateTime,
                ),
              ],
            ),
            const Divider(height: 32),
            RRuleGenerator(
              locale: RRuleLocale.en_GB,
              onChange: _onRRuleChanged,
              initialDate: _selectedDate,
              config: RRuleGeneratorConfig(
                headerStyle: const RRuleHeaderStyle(
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}