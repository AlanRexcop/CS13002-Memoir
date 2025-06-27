import 'package:markdown/markdown.dart' as md;
import 'package:memoir/models/location_model.dart';
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/mention_model.dart';

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

class CalendarSyntax extends md.InlineSyntax {
  // \d{4}         -> Exactly four digits (Year)
  // -             -> A literal hyphen
  // \d{2}         -> Exactly two digits (Month, Day, Hour, etc.)
  // \s+           -> One or more whitespace characters
  // :             -> A literal colon
  // (?:...)       -> Optional section
  CalendarSyntax() : super(r'\{calendar\}\[([^\]]*)\]\((\d{4}-\d{2}-\d{2}(?: \d{2}:\d{2}:\d{2})?)\)');

  /// This method is called when the parser finds a match.
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // 1. Extract the captured groups from the regex match.
    final String text = match.group(1)!;
    final String value = match.group(2)!;

    // 2. Create a custom md.Element to represent this in the AST.
    final element = md.Element.withTag('mcalendar');
    
    // 3. Store our parsed data as attributes on the element.
    // for "visitor" ability to retrieve the data later.
    element.attributes['data-text'] = text;
    element.attributes['data-value'] = value;

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
  LocationSyntax() : super(r'\{location\}\[([^\]]*)\]\((-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?)\)');

  /// This method is called when the parser finds a match.
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // 1. Extract the captured groups from the regex match.
    final String text = match.group(1)!;
    final String value = match.group(2)!;

    // 2. Create a custom md.Element to represent this in the AST.
    final element = md.Element.withTag('mlocation');
    
    // 3. Store our parsed data as attributes on the element.
    // for "visitor" ability to retrieve the data later.
    element.attributes['data-text'] = text;
    element.attributes['data-value'] = value;

    parser.addNode(element);
    return true;
  }
}

class MarkdownAstVisitor implements md.NodeVisitor {
  final List<Mention> mentions = [];
  final List<Event> events = [];
  final List<Location> locations = [];
  
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
      case 'mcalendar':
        final text = element.attributes['data-text']!;
        final value = element.attributes['data-value']!;
        final time = DateTime.parse(value);
        events.add(Event(info: text, time: time));
        break;
      case 'mmention':
        final text = element.attributes['data-text']!;
        final value = element.attributes['data-value']!;
        mentions.add(Mention(info: text, path: value));
        break;
    }
  }
}

MarkdownAstVisitor analyzeMarkdown(String markdownContent) {
  final document = md.Document(
    encodeHtml: false,
    inlineSyntaxes: [
      LocationSyntax(),
      CalendarSyntax(),
      MentionSyntax(),
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