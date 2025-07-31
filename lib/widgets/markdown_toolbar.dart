// C:\dev\memoir\lib\widgets\markdown_toolbar.dart
import 'package:flutter/material.dart';

// enum to represent all possible actions from the toolbar
enum MarkdownAction {
  image,
  table,
  link,
  hr,
  bold,
  italic,
  strikethrough,
  inlineCode,
  codeBlock,
  h1,
  h2,
  h3,
  checkbox,
  ul,
  ol,
  quote,
  mention,
  location,
  event,
}

class MarkdownToolbar extends StatelessWidget {
  // callback to notify the parent about which action was selected
  final void Function(MarkdownAction) onAction;

  const MarkdownToolbar({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    // A list of all menu items, mapping UI to a specific MarkdownAction
    final List<({String label, IconData icon, MarkdownAction action})> menuItems =
        [
      (
        label: 'Mention',
        icon: Icons.alternate_email,
        action: MarkdownAction.mention
      ),
      (
        label: 'Image',
        icon: Icons.image_outlined,
        action: MarkdownAction.image
      ),
      (
        label: 'Location',
        icon: Icons.add_location_alt_outlined,
        action: MarkdownAction.location
      ),
      (label: 'Event', icon: Icons.event, action: MarkdownAction.event),
      (
        label: 'Table',
        icon: Icons.table_chart_outlined,
        action: MarkdownAction.table
      ),
      (label: 'Link', icon: Icons.link, action: MarkdownAction.link),
      (label: 'Divider', icon: Icons.horizontal_rule, action: MarkdownAction.hr),
      (label: 'Bold', icon: Icons.format_bold, action: MarkdownAction.bold),
      (
        label: 'Italic',
        icon: Icons.format_italic,
        action: MarkdownAction.italic
      ),
      (
        label: 'Strikethrough',
        icon: Icons.format_strikethrough,
        action: MarkdownAction.strikethrough
      ),
      (
        label: 'Inline Code',
        icon: Icons.code,
        action: MarkdownAction.inlineCode
      ),
      (
        label: 'Code Block',
        icon: Icons.data_object,
        action: MarkdownAction.codeBlock
      ),
      (label: 'Header 1', icon: Icons.looks_one_outlined, action: MarkdownAction.h1),
      (label: 'Header 2', icon: Icons.looks_two_outlined, action: MarkdownAction.h2),
      (label: 'Header 3', icon: Icons.looks_3_outlined, action: MarkdownAction.h3),
      (
        label: 'Checkbox',
        icon: Icons.check_box_outlined,
        action: MarkdownAction.checkbox
      ),
      (
        label: 'Bullet List',
        icon: Icons.format_list_bulleted,
        action: MarkdownAction.ul
      ),
      (
        label: 'Num List',
        icon: Icons.format_list_numbered,
        action: MarkdownAction.ol
      ),
      (
        label: 'Blockquote',
        icon: Icons.format_quote,
        action: MarkdownAction.quote
      ),
    ];

    return SafeArea(
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return InkWell(
            onTap: () {
              // Close the bottom sheet and notify the parent of the chosen action
              Navigator.of(context).pop();
              onAction(item.action);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 28, color: Theme.of(context).colorScheme.primary,),
                const SizedBox(height: 4),
                Text(item.label,
                    style: const TextStyle(fontSize: 15),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }
}