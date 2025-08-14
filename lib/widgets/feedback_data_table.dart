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
    return Column(
      children: [
        _buildHeader(context),
        const Divider(height: 1, thickness: 1),

        if(feedbackItems.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0), 
            child: Center(child: Text("No feedback items found."))
          )
        else 
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feedbackItems.length,
            itemBuilder: (context, index) {
              final item = feedbackItems[index];
              return _FeedbackDataRow(
                item: item,
                onNavigate: () => _navigateToDetails(context, item.id),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey[200],
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('User\'s email', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 5,
            child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context, int feedbackId) {
    context.read<FeedbackProvider>().viewFeedback(feedbackId);
  }
}

class _FeedbackDataRow extends StatefulWidget {
  final FeedbackItem item;
  final VoidCallback onNavigate;

  const _FeedbackDataRow({
    required this.item,
    required this.onNavigate,
  });

  @override
  State<_FeedbackDataRow> createState() => _FeedbackDataRowState();
}

class _FeedbackDataRowState extends State<_FeedbackDataRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onNavigate,
      onHover: (hovering) => setState(() => _isHovering = hovering),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: _isHovering ? Colors.grey[200] : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(widget.item.userEmail, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 5,
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    TextSpan(text: widget.item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: ' - ${widget.item.text.replaceAll('\n', ' ')}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(DateFormat.yMMMd().format(widget.item.sendDate)),
            ),
          ],
        ),
      ),
    );
  }
}