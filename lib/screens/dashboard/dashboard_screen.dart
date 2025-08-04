import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                Icons.people,
                'Total accounts',
                '1,234',
                Colors.blue,
              ),
              _buildSummaryCard(
                Icons.bug_report,
                'Total bugs',
                '10',
                Colors.red,
              ),
              _buildSummaryCard(
                Icons.feedback,
                'Total feedbacks',
                '19',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent accounts and Pie Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent accounts table
              Expanded(flex: 2, child: _buildRecentAccounts()),
              const SizedBox(width: 24),
              // Bugs & feedbacks pie chart
              Expanded(child: _buildPieChart()),
            ],
          ),
          const SizedBox(height: 24),

          // Registration graph
          const Text(
            "Registration graph",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildBarChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    IconData icon,
    String label,
    String count,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAccounts() {
    final accounts = [
      {'name': 'minhnguyen', 'date': '26/06/2025'},
      {'name': 'john.smith', 'date': '26/06/2025'},
      {'name': 'michael.brown', 'date': '26/06/2025'},
      {'name': 'khanh.vo', 'date': '26/06/2025'},
    ];

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
                      Text("${index + 1}"),
                      Text(acc['name']!),
                      Text(acc['date']!),
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

  Widget _buildPieChart() {
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
                      value: 8,
                      color: Colors.red,
                      title: '8',
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value: 17,
                      color: Colors.yellow,
                      title: '17',
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value: 4,
                      color: Colors.green,
                      title: '4',
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

  Widget _buildBarChart() {
    final registrations = [103, 239, 192, 89, 312, 299]; // Jan - June
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

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
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      return Text(months[value.toInt()]);
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
}
