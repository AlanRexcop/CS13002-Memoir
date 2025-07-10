class Event {
  final String info;
  final DateTime time;
  final String? rrule;

  Event({
    required this.info,
    required this.time,
    this.rrule,
  });
}