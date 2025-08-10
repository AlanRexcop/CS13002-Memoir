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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 175),
                child: _buildSummaryCard(
                  assetPath: 'assets/icons/accounts.png',
                  title: 'Total accounts',
                  count: '1,234', // dữ liệu cần lấy từ db
                ),
              ),
              _buildSummaryCard(
                assetPath: 'assets/icons/bugs.png',
                title: 'Total bugs',
                count: '10', // dữ liệu cần lấy từ db
              ),
              Padding(
                padding: const EdgeInsets.only(left: 175),
                child: _buildSummaryCard(
                  assetPath: 'assets/icons/feedbacks.png',
                  title: 'Total feedbacks',
                  count: '19', // dữ liệu cần lấy từ db
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent accounts and Pie Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentAccounts()),
              const SizedBox(width: 24),
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
        width: 316,
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
                // để text chiếm hết phần còn lại và căn phải
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
                        fontWeight: FontWeight.bold, // in đậm hơn
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
    final registrations = [103, 239, 192, 89, 312, 299];
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
