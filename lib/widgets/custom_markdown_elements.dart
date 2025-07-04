// C:\dev\memoir\lib\widgets\custom_markdown_elements.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/calendar_screen.dart';
import 'package:memoir/screens/map_screen.dart';
import 'package:memoir/screens/note_view_screen.dart';

// A helper class to bundle context needed for navigation.
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
          // Find the note from the provider and navigate to it.
          final allPersons = buildContext.ref.read(appProvider).persons;
          Note? targetNote;
          for (var person in allPersons) {
            final found = [person.info, ...person.notes].where((note) => note.path == path);
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

// --- LOCATION WIDGET ---

class LocationNode extends SpanNode {
  final String text;
  final MarkdownBuildContext buildContext;
  
  LocationNode(this.text, this.buildContext);

  @override
  InlineSpan build() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () {
          Navigator.of(buildContext.context).push(
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        child: Chip(
          avatar: const Icon(Icons.location_on_outlined, size: 16),
          label: Text(text),
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
            MaterialPageRoute(builder: (context) => const CalendarScreen()),
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
    generator: (e, config, visitor) => LocationNode(
      e.attributes['data-text']!,
      buildContext,
    ),
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