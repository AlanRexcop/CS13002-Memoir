// lib/screens/dashboard/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/feedback_item.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/feedback_data_table.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch data when the screen is first loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<FeedbackProvider>().feedbackItems.isEmpty) {
        context.read<FeedbackProvider>().fetchFeedback();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // The AppBar is used to hold the TabBar and align it with the content
        toolbarHeight: 0, // No visible toolbar
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Bugs'),
            Tab(text: 'Feedbacks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedbackListView(tag: 'bugs'),
          _FeedbackListView(tag: 'feedback'),
        ],
      ),
    );
  }
}

// A helper widget to display the content for each tab.
class _FeedbackListView extends StatelessWidget {
  final String tag;
  const _FeedbackListView({required this.tag});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedbackProvider>();
    final List<String> statusOptions = [
      'unresolved',
      'resolved',
      'in_progress',
      'closed',
    ];

    // Filter items based on the current tab's tag and the selected status
    final List<FeedbackItem> filteredItems = provider.feedbackItems.where((item) {
      bool tagMatch = item.tag?.toLowerCase() == tag;

      bool statusMatch;
      if (provider.selectedStatus == 'unresolved') {
        // 'unresolved' is a special filter for 'pending' or 'in_progress'
        statusMatch = item.status == 'pending' || item.status == 'in_progress';
      } else {
        statusMatch = item.status == provider.selectedStatus;
      }

      return tagMatch && statusMatch;
    }).toList();

    int unresolvedCount = provider.feedbackItems
        .where(
          (item) =>
              (item.tag?.toLowerCase() == tag) &&
              (item.status == 'pending' || item.status == 'in_progress'),
        )
        .length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count and filter
          Row(
            children: [
              Text('Number of unresolved ${tag}s: $unresolvedCount'),
              const Spacer(),
              const Text('Status: '),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: provider.selectedStatus,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      provider.setStatusFilter(newValue);
                    }
                  },
                  items: statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  underline: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main data table
          Expanded(
            child: provider.isLoading && filteredItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                ? Center(child: Text('Error: ${provider.error}'))
                : filteredItems.isEmpty
                ? Center(child: Text('No matching ${tag}s found.'))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView(
                        children: [
                          FeedbackDataTable(feedbackItems: filteredItems),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
