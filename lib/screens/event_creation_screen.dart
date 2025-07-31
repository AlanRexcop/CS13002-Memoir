// C:\dev\memoir\lib\screens\event_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // State for the new dynamic reminder UI
  bool _isReminderEnabled = false;
  final _reminderValueController = TextEditingController(text: '15');
  String _selectedReminderUnit = 'm'; // m, h, d, w

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _reminderValueController.dispose();
    super.dispose();
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
    // This must NOT call setState, to prevent the RRuleGenerator from resetting.
    _rrule = value;
  }

  String _getReminderString() {
    if (!_isReminderEnabled) return '';

    final value = int.tryParse(_reminderValueController.text) ?? 0;
    if (value == 0) return '';

    return ';$value$_selectedReminderUnit';
  }

  void _saveEvent() {
    final dtStart = _selectedDate.toIso8601String().split('.').first;
    final rrulePart = (_rrule == null || _rrule!.isEmpty) ? '' : ';$_rrule';
    final reminderPart = _getReminderString();

    final markdown =
        ' {event}[${widget.eventTitle}]($dtStart$rrulePart$reminderPart) ';
    Navigator.of(context).pop(markdown);
  }

  // Helper for consistent section headers
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    const double sectionSpacing = 24.0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Create a theme-aware switch style to override the library's defaults.
    final RRuleSwitchStyle materialSwitchStyle = RRuleSwitchStyle(
      isCupertinoStyle: false,
      // Use theme colors instead of hardcoded green/grey.
      activeTrackColor: colorScheme.primary.withOpacity(0.5),
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      // Use a theme color for the outline on inactive switches.
      trackOutlineColor: colorScheme.outline,
      // Remove the distracting red border on active switches.
      trackOutlineWidth: 0.0,
      // The library forces an icon as a thumb. We use theme colors to make it blend in.
      thumbColor: colorScheme.onPrimary,
      // Set the text style to be consistent with the rest of the app.
      switchTextStyle:
          (theme.textTheme.bodyLarge ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.normal),
    );

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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Date & Time Section ---
          _buildSectionHeader('Start Date & Time'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.yMMMMd().add_jm().format(_selectedDate),
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                label: const Text('Change'),
                onPressed: _pickDateTime,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: sectionSpacing / 2),
          const Divider(),
          const SizedBox(height: sectionSpacing / 2),

          // --- Reminder Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Reminder'),
              Switch(
                value: _isReminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _isReminderEnabled = value;
                  });
                },
              )
            ],
          ),
          if (_isReminderEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _reminderValueController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedReminderUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'm', child: Text('Minutes before')),
                        DropdownMenuItem(
                            value: 'h', child: Text('Hours before')),
                        DropdownMenuItem(
                            value: 'd', child: Text('Days before')),
                        DropdownMenuItem(
                            value: 'w', child: Text('Weeks before')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedReminderUnit = value;
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          const SizedBox(height: sectionSpacing / 2),
          const Divider(),
          const SizedBox(height: sectionSpacing / 2),

          // --- Recurrence Section ---
          _buildSectionHeader('Repeat'),
          const SizedBox(height: 8),
          RRuleGenerator(
            onChange: _onRRuleChanged,
            initialDate: _selectedDate,
            config: RRuleGeneratorConfig(
              headerStyle: const RRuleHeaderStyle(enabled: false),
              labelStyle: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
              // Pass our beautifully crafted style object here.
              switchStyle: materialSwitchStyle,
              inputTextStyle: RRuleInputTextStyle(
                inputTextDecoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: const UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                ),
              ),
              divider: const SizedBox(height: 12),
            ),
          ),
        ],
      ),
    );
  }
}