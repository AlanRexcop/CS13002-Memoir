// lib/widgets/feedback_data_table.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/feedback_item.dart';
import '../providers/feedback_provider.dart';

class FeedbackDataTable extends StatelessWidget {
  final List<FeedbackItem> feedbackItems;
  const FeedbackDataTable({super.key, required this.feedbackItems});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
      dataRowColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.hovered)) {
          return Theme.of(context).colorScheme.primary.withOpacity(0.08);
        }
        return null; // Use default
      }),
      columnSpacing: 30,
      columns: const [
        DataColumn(label: Text("User's gmail", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: feedbackItems.map((item) {
        return DataRow(
          // The whole row is now clickable to navigate to details.
          onSelectChanged: (_) {
            context.read<FeedbackProvider>().viewFeedback(item.id);
          },
          cells: [
            DataCell(Text(item.userEmail)),
            DataCell(
              // Show the title in bold with a text snippet below it.
              SizedBox(
                width: 450, // Give the title column a fixed width
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      TextSpan(text: item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: ' - ${item.text.replaceAll('\n', ' ')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            DataCell(Text(DateFormat('dd/MM/yyyy').format(item.sendDate))),
          ],
        );
      }).toList(),
    );
  }
}