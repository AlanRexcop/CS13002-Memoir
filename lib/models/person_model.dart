import 'package:memoir/models/note_model.dart';

class Person {
  final String path; // id
  final Note info;
  final List<Note> notes;

  Person({
    required this.path,
    required this.info,
    this.notes = const [],
  });
}