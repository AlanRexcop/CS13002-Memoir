import 'package:memoir/models/location_model.dart';
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/mention_model.dart';

class Note {
  final String path; // id
  final String title;
  final DateTime creationDate;
  final DateTime lastModified;
  final List<String> tags;
  final List<Event> events;
  final List<String> images;
  final List<Mention> mentions;
  final List<Location> locations;

  Note({
    required this.path,
    required this.title,
    required this.creationDate,
    required this.lastModified,
    this.tags = const [],
    this.events = const [],
    this.images = const [],
    this.mentions = const [],
    this.locations = const []
  });
}