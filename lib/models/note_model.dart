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
  final DateTime? deletedDate;

  Note({
    required this.path,
    required this.title,
    required this.creationDate,
    required this.lastModified,
    this.tags = const [],
    this.events = const [],
    this.images = const [],
    this.mentions = const [],
    this.locations = const [],
    this.deletedDate,
  });

  Note copyWith({
    String? path,
    String? title,
    DateTime? creationDate,
    DateTime? lastModified,
    List<String>? tags,
    List<Event>? events,
    List<String>? images,
    List<Mention>? mentions,
    List<Location>? locations,
    DateTime? deletedDate,
  }) {
    return Note(
      path: path ?? this.path,
      title: title ?? this.title,
      creationDate: creationDate ?? this.creationDate,
      lastModified: lastModified ?? this.lastModified,
      tags: tags ?? this.tags,
      events: events ?? this.events,
      images: images ?? this.images,
      mentions: mentions ?? this.mentions,
      locations: locations ?? this.locations,
      deletedDate: deletedDate ?? this.deletedDate,
    );
  }
}