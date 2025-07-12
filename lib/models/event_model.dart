class Event {
  final String info;
  final DateTime time;
  final String? rrule;
  final Duration? reminder;

  Event({
    required this.info,
    required this.time,
    this.rrule,
    this.reminder,
  }); 
}