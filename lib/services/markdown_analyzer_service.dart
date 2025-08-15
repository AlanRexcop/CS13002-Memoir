// lib/services/markdown_analyzer_service.dart
import 'package:markdown/markdown.dart' as md;
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/location_model.dart';
import 'package:memoir/models/mention_model.dart';

// Helper function to parse duration strings like "15m", "1h", "2d"
Duration? _parseDuration(String? reminderString) {
  if (reminderString == null || reminderString.isEmpty) return null;
  // Regex to ensure the format is <digits><one letter>
  final reminderRegex = RegExp(r'^(\d+)([mhd])$');
  final match = reminderRegex.firstMatch(reminderString);
  if (match == null) return null;

  try {
    final value = int.parse(match.group(1)!);
    final unit = match.group(2)!;
    switch (unit) {
      case 'm':
        return Duration(minutes: value);
      case 'h':
        return Duration(hours: value);
      case 'd':
        return Duration(days: value);
      case 'w':
        return Duration(days: value * 7);
      default:
        return null;
    }
  } catch (e) {
    return null;
  }
}

class MentionSyntax extends md.InlineSyntax {
  // \{(\w+)\}          - Group 1: Matches and captures the type inside {}, e.g., "mention"
  // \[([^\]]*)\]        - Group 2: Matches and captures the text inside [], e.g., "text"
  // \(([^)]*)\)         - Group 3: Matches and captures the value inside (), e.g., "path"
  MentionSyntax() : super(r'\{mention\}\[([^\]]*)\]\(([^)]*)\)');

  /// This method is called when the parser finds a match.
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // 1. Extract the captured groups from the regex match.
    final String text = match.group(1)!;
    final String value = match.group(2)!;

    // 2. Create a custom md.Element to represent this in the AST.
    final element = md.Element.withTag('mmention');

    // 3. Store our parsed data as attributes on the element.
    // for "visitor" ability to retrieve the data later.
    element.attributes['data-text'] = text;
    element.attributes['data-value'] = value;

    parser.addNode(element);
    return true;
  }
}

class EventSyntax extends md.InlineSyntax {
  // \{event\}          - Matches the literal "{event}"
  // \[([^\]]*)\]        - Group 1: Matches and captures the event description inside []
  // \(([^)]*)\)         - Group 2: Matches and captures the full content (DateTime, RRULE, Reminder) inside ()
  EventSyntax() : super(r'\{event\}\[([^\]]*)\]\(([^)]*)\)');

  /// This method is called when the parser finds a match.
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // 1. Extract the captured groups from the regex match.
    final String text = match.group(1)!;
    final String content = match.group(2)!;

    // 2. Parse the content string by splitting it. This is more robust than a complex regex.
    final parts = content.split(';');
    final dt = parts.isNotEmpty ? parts[0] : '';
    // Identify RRULE and reminder parts by their characteristics.
    final rrule =
        parts.firstWhere((p) => p.startsWith('RRULE:'), orElse: () => '');
    final reminder =
        parts.firstWhere((p) => !p.startsWith('RRULE:') && p != dt, orElse: () => '');

    bool isValid = true;
    if (DateTime.tryParse(dt) == null) {
      isValid = false;
    }
    if (reminder.isNotEmpty && _parseDuration(reminder) == null) {
      isValid = false;
    }

    // If the data is invalid, render it as plain text instead of a special element.
    // This prevents the app from crashing on bad data and avoids the infinite loop.
    if (!isValid) {
      // match.group(0)! is the entire matched string, e.g., "{event}[...](...)"
      parser.addNode(md.Text(match.group(0)!));
      return true;
    }
    
    // If valid, proceed to create the custom element.
    final element = md.Element.withTag('mevent');
    element.attributes['data-text'] = text;
    element.attributes['data-dt'] = dt;
    if (rrule.isNotEmpty) {
      element.attributes['data-rrule'] = rrule;
    }
    if (reminder.isNotEmpty) {
      element.attributes['data-reminder'] = reminder;
    }

    parser.addNode(element);
    return true;
  }
}

class LocationSyntax extends md.InlineSyntax {
  // -?            -> Optional minus sign
  // \d+           -> One or more digits
  // (\.\d+)?      -> An optional decimal part (e.g., ".123")
  // \s*,\s*       -> A comma, surrounded by optional whitespace
  // (repeat for the second number)
  LocationSyntax()
      : super(r'\{location\}\[([^\]]*)\]\((-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?)\)');

  /// This method is called when the parser finds a match.
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // 1. Extract the captured groups from the regex match.
    final String text = match.group(1)!;
    final String value = match.group(2)!;

    bool isValid = true;
    final parts = value.split(',');
    if (parts.length != 2) {
      isValid = false;
    } else {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat == null || lng == null) {
        isValid = false;
      } else {
        if (lat < -90.0 || lat > 90.0) isValid = false;
        if (lng < -180.0 || lng > 180.0) isValid = false;
      }
    }

    // If the coordinates are invalid, render the tag as plain text.
    if (!isValid) {
      parser.addNode(md.Text(match.group(0)!));
      return true;
    }
    
    // If valid, create the custom element.
    final element = md.Element.withTag('mlocation');
    element.attributes['data-text'] = text;
    element.attributes['data-value'] = value;

    parser.addNode(element);
    return true;
  }
}

class ImageSyntax extends md.InlineSyntax {
  ImageSyntax() : super(r'!\[(.*?)\]\((.*?)\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final String src = match.group(2)!;

    final element = md.Element.withTag('mimage');
    element.attributes['data-src'] = src;

    parser.addNode(element);
    return true;
  }
}

class MarkdownAstVisitor implements md.NodeVisitor {
  final List<Mention> mentions = [];
  final List<Event> events = [];
  final List<Location> locations = [];
  final List<String> images = [];

  @override
  bool visitElementBefore(md.Element element) {
    // We want to visit all children of every element, so we always return true.
    return true;
  }

  @override
  bool visitText(md.Text text) {
    // We are not analyzing plain text nodes, so we do nothing,
    // but we must return true to continue walking the tree.
    return true;
  }

  @override
  void visitElementAfter(md.Element element) {
    switch (element.tag) {
      case 'mlocation':
        final text = element.attributes['data-text']!;
        final value = element.attributes['data-value']!;
        final parts = value.split(',');
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        locations.add(Location(info: text, lat: lat, lng: lng));
        break;
      case 'mevent':
        final text = element.attributes['data-text']!;
        final dt = element.attributes['data-dt']!;
        final rrule = element.attributes['data-rrule'];
        final reminderString = element.attributes['data-reminder'];
        try {
          final time = DateTime.parse(dt);
          final reminderDuration = _parseDuration(reminderString);
          events.add(Event(
              info: text,
              time: time,
              rrule: rrule,
              reminder: reminderDuration));
        } catch (e) {
          print('Error parsing event date: $dt');
        }
        break;
      case 'mmention':
        final text = element.attributes['data-text']!;
        final value = element.attributes['data-value']!;
        mentions.add(Mention(info: text, path: value));
        break;
      case 'mimage':
        final src = element.attributes['data-src']!;
        images.add(src);
        break;
    }
  }
}

MarkdownAstVisitor analyzeMarkdown(String markdownContent) {
  final document = md.Document(
    encodeHtml: false,
    inlineSyntaxes: [
      LocationSyntax(),
      EventSyntax(),
      MentionSyntax(),
      ImageSyntax(),
    ],
    extensionSet: md.ExtensionSet.gitHubFlavored,
  );

  final lines = markdownContent.split(RegExp(r'(\r?\n)|(\r)'));
  final nodes = document.parseLines(lines);

  final visitor = MarkdownAstVisitor();
  for (final node in nodes) {
    node.accept(visitor);
  }

  return visitor;
}