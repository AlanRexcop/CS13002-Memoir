// C:\dev\memoir\lib\widgets\custom_markdown_elements.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memoir/models/location_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/calendar_screen.dart';
import 'package:memoir/screens/map_screen.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:path/path.dart' as p;

class MarkdownBuildContext {
  final BuildContext context;
  final WidgetRef ref;
  MarkdownBuildContext(this.context, this.ref);
}

// --- MENTION WIDGET ---

class MentionNode extends SpanNode {
  final String text;
  final String path;
  final MarkdownBuildContext buildContext;

  MentionNode(this.text, this.path, this.buildContext);

  @override
  InlineSpan build() {
    return TextSpan(
      text: '@$text',
      style: TextStyle(
        color: Theme.of(buildContext.context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          // --- FIX: Decode the URL-encoded path before normalizing and using it ---
          final decodedPath = Uri.decodeFull(path);
          final normalizedPath = p.joinAll(decodedPath.split('/'));

          final allPersons = buildContext.ref.read(appProvider).persons;
          Note? targetNote;
          for (var person in allPersons) {
            final found = [person.info, ...person.notes].where((note) => note.path == normalizedPath);
            if (found.isNotEmpty) {
              targetNote = found.first;
              break;
            }
          }
          if (targetNote != null) {
            Navigator.of(buildContext.context).push(
              MaterialPageRoute(builder: (context) => NoteViewScreen(note: targetNote!)),
            );
          } else {
            ScaffoldMessenger.of(buildContext.context).showSnackBar(
              const SnackBar(content: Text('Could not find the mentioned note.'), backgroundColor: Colors.red),
            );
          }
        },
    );
  }
}

// ... rest of the file is unchanged
// --- LOCATION WIDGET ---

class LocationNode extends SpanNode {
  final Location location;
  final MarkdownBuildContext buildContext;
  
  LocationNode(this.location, this.buildContext);

  @override
  InlineSpan build() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () {
          Navigator.of(buildContext.context).push(
            MaterialPageRoute(builder: (context) => MapScreen(initialLocation: location)),
          );
        },
        child: Chip(
          avatar: const Icon(Icons.location_on_outlined, size: 16),
          label: Text(location.info),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// --- CALENDAR/EVENT WIDGET ---

class EventNode extends SpanNode {
  final String text;
  final DateTime time;
  final MarkdownBuildContext buildContext;

  EventNode(this.text, this.time, this.buildContext);
  
  @override
  InlineSpan build() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () {
          Navigator.of(buildContext.context).push(
            MaterialPageRoute(builder: (context) => CalendarScreen(initialDate: time)),
          );
        },
        child: Chip(
          avatar: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text('$text (${DateFormat.yMMMd().format(time)})'),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}


// --- GENERATOR FUNCTIONS ---

SpanNodeGeneratorWithTag mentionGenerator(MarkdownBuildContext buildContext) {
  return SpanNodeGeneratorWithTag(
    tag: 'mmention',
    generator: (e, config, visitor) => MentionNode(
      e.attributes['data-text']!,
      e.attributes['data-value']!,
      buildContext,
    ),
  );
}

SpanNodeGeneratorWithTag locationGenerator(MarkdownBuildContext buildContext) {
  return SpanNodeGeneratorWithTag(
    tag: 'mlocation',
    generator: (e, config, visitor) {
      final text = e.attributes['data-text']!;
      final value = e.attributes['data-value']!;
      final parts = value.split(',');
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      final location = Location(info: text, lat: lat, lng: lng);
      return LocationNode(location, buildContext);
    },
  );
}

SpanNodeGeneratorWithTag eventGenerator(MarkdownBuildContext buildContext) {
  return SpanNodeGeneratorWithTag(
    tag: 'mcalendar',
    generator: (e, config, visitor) => EventNode(
      e.attributes['data-text']!,
      DateTime.parse(e.attributes['data-value']!),
      buildContext,
    ),
  );
}