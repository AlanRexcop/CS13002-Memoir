import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../providers/feedback_provider.dart';
import '../../providers/user_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch initial data without causing a rebuild in initState
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
      Provider.of<FeedbackProvider>(context, listen: false).fetchFeedback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, FeedbackProvider>(
      builder: (context, userProvider, feedbackProvider, child) {
        if (userProvider.isLoading || feedbackProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- Data processing for widgets ---

        // Summary Cards Data
        final totalAccounts = userProvider.users.length;
        final totalBugs = feedbackProvider.feedbackItems
            .where((fb) => fb.tag == 'bug')
            .length;
        final totalFeedbacks = feedbackProvider.feedbackItems
            .where((fb) => fb.tag == 'feedback')
            .length;

        // Recent Accounts Data
        final recentAccounts = List<UserProfile>.from(userProvider.users);
        recentAccounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Pie Chart Data
        final unresolvedBugs = feedbackProvider.feedbackItems
            .where((fb) => fb.tag == 'bug' && fb.status == 'unresolved')
            .length;
        final unreadFeedbacks = feedbackProvider.feedbackItems
            .where((fb) => fb.tag == 'feedback' && fb.status == 'unresolved')
            .length;
        final resolvedAndRead = feedbackProvider.feedbackItems
            .where((fb) => fb.status == 'resolved')
            .length;
        
        // Bar Chart Data
        final registrationData = _generateRegistrationData(userProvider.users);


        return LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 900; // breakpoint
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  if (isMobile)
                    Column(
                      children: [
                        _buildSummaryCard(
                          assetPath: 'assets/icons/accounts.png',
                          title: 'Total accounts',
                          count: totalAccounts.toString(),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          assetPath: 'assets/icons/bugs.png',
                          title: 'Total bugs',
                          count: totalBugs.toString(),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          assetPath: 'assets/icons/feedbacks.png',
                          title: 'Total feedbacks',
                          count: totalFeedbacks.toString(),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            assetPath: 'assets/icons/accounts.png',
                            title: 'Total accounts',
                            count: totalAccounts.toString(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildSummaryCard(
                            assetPath: 'assets/icons/bugs.png',
                            title: 'Total bugs',
                            count: totalBugs.toString(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildSummaryCard(
                            assetPath: 'assets/icons/feedbacks.png',
                            title: 'Total feedbacks',
                            count: totalFeedbacks.toString(),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Recent accounts and Pie Chart
                  if (isMobile)
                    Column(
                      children: [
                        _buildRecentAccounts(recentAccounts.take(4).toList()),
                        const SizedBox(height: 24),
                        _buildPieChart(
                            unresolvedBugs, unreadFeedbacks, resolvedAndRead),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildRecentAccounts(
                              recentAccounts.take(4).toList()),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                            child: _buildPieChart(unresolvedBugs,
                                unreadFeedbacks, resolvedAndRead)),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Registration graph
                  const Text(
                    "Registration graph",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBarChart(
                    registrationData['labels'] as List<String>,
                    registrationData['data'] as List<int>,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Widget build methods ---

  Widget _buildSummaryCard({
    required String assetPath,
    required String title,
    required String count,
  }) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.7),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 108,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                width: 75,
                height: 75,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 23,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAccounts(List<UserProfile> accounts) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent registered accounts",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(30),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(100),
              },
              children: [
                const TableRow(
                  children: [
                    Text("No.", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "Account name",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Created at",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ...accounts.asMap().entries.map((entry) {
                  int index = entry.key;
                  final acc = entry.value;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("${index + 1}"),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(acc.username),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(formatter.format(acc.createdAt)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    int unresolvedBugs,
    int unreadFeedbacks,
    int resolvedAndRead,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Bugs and Feedbacks",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: unresolvedBugs.toDouble(),
                      color: Colors.red,
                      title: unresolvedBugs.toString(),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value: unreadFeedbacks.toDouble(),
                      color: Colors.yellow,
                      title: unreadFeedbacks.toString(),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value: resolvedAndRead.toDouble(),
                      color: Colors.green,
                      title: resolvedAndRead.toString(),
                      radius: 40,
                    ),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: const [
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Colors.red),
                    SizedBox(width: 8),
                    Text("Unresolved bugs"),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Colors.yellow),
                    SizedBox(width: 8),
                    Text("Unread feedbacks"),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Colors.green),
                    SizedBox(width: 8),
                    Text("Resolved and read"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<String> months, List<int> registrations) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: List.generate(
                registrations.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: registrations[i].toDouble(),
                      color: Colors.blue,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      if (value.toInt() < months.length) {
                        return Text(months[value.toInt()]);
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  /// --- Helper method to process registration data for the bar chart ---
  Map<String, dynamic> _generateRegistrationData(List<UserProfile> users) {
    final List<String> monthLabels = [];
    final List<int> registrationCounts = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthLabel = DateFormat.MMM().format(targetDate);
      monthLabels.add(monthLabel);

      final count = users.where((user) {
        return user.createdAt.year == targetDate.year &&
            user.createdAt.month == targetDate.month;
      }).length;
      registrationCounts.add(count);
    }
    return {'labels': monthLabels, 'data': registrationCounts};
  }
}