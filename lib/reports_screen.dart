import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').where('members', arrayContains: user?.uid).snapshots(),
      builder: (context, projSnap) {
        if (!projSnap.hasData) return const Center(child: CircularProgressIndicator());
        final projects = projSnap.data!.docs;
        
        return FutureBuilder<Map<String, int>>(
          future: _getTaskCountsByStatus(projects),
          builder: (context, taskCountsSnap) {
            final taskCounts = taskCountsSnap.data ?? {'Not started': 0, 'In progress': 0, 'Completed': 0};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E0854))),
                  const SizedBox(height: 20),
                  
                  _buildTopGraphs(projects, taskCounts),
                  const SizedBox(height: 16),

                  _buildTaskProgressOverTimeCard(user?.uid),

                  const SizedBox(height: 32),
                  const Text('ACTIVE PROJECTS PERFORMANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  
                  _buildProjectReportList(projects.where((p) => p.get('status') != 'Completed').toList()),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<Map<String, int>> _getTaskCountsByStatus(List<QueryDocumentSnapshot> projects) async {
    Map<String, int> counts = {'Not started': 0, 'In progress': 0, 'Completed': 0};
    for (var pDoc in projects) {
      final status = pDoc.get('status') ?? 'Not started';
      final taskSnap = await FirebaseFirestore.instance.collection('tasks').where('project_id', isEqualTo: pDoc.id).get();
      counts[status] = (counts[status] ?? 0) + taskSnap.docs.length;
    }
    return counts;
  }

  Widget _buildTopGraphs(List<QueryDocumentSnapshot> projects, Map<String, int> taskCounts) {
    final Map<String, int> statusCounts = {
      'Not started': projects.where((p) => p.get('status') == 'Not started').length,
      'In progress': projects.where((p) => p.get('status') == 'In progress').length,
      'Completed': projects.where((p) => p.get('status') == 'Completed').length,
    };

    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E2E4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total projects - By project statuses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final labels = ['Not Start', 'In Progress', 'Complete'];
                            if (val.toInt() < 0 || val.toInt() >= labels.length) return const SizedBox();
                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text(labels[val.toInt()], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)));
                          }
                        ),
                      ),
                    ),
                    barGroups: statusCounts.entries.map((e) {
                      int idx = statusCounts.keys.toList().indexOf(e.key);
                      return BarChartGroupData(
                        x: idx, 
                        barRods: [
                          BarChartRodData(
                            toY: e.value.toDouble(), 
                            color: const Color(0xFF4B89FF), 
                            width: 32, 
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                        showingTooltipIndicators: [0],
                      );
                    }).toList(),
                    barTouchData: BarTouchData(
                      enabled: false,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.transparent,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String status = statusCounts.keys.toList()[group.x.toInt()];
                          int tCount = taskCounts[status] ?? 0;
                          return BarTooltipItem(
                            '$tCount tasks',
                            const TextStyle(color: Color(0xFF4B89FF), fontWeight: FontWeight.bold, fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E2E4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Task Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Row(children: [
                _Legend(color: Colors.green, label: 'Done'),
                SizedBox(width: 12),
                _Legend(color: Color(0xFF4B89FF), label: 'Pending'),
              ]),
              const SizedBox(height: 24),
              _buildTaskDistributionBars(projects),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDistributionBars(List<QueryDocumentSnapshot> projects) {
    return Column(
      children: ['Not started', 'In progress', 'Completed'].map((status) {
        final statusProject = projects.where((p) => p.get('status') == status).toList();
        double totalProg = 0;
        if (statusProject.isNotEmpty) {
          totalProg = statusProject.map((p) => p.get('progress') ?? 0.0).reduce((a, b) => a + b) / statusProject.length;
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              SizedBox(width: 70, child: Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: totalProg / 100, minHeight: 12, backgroundColor: const Color(0xFF4B89FF).withValues(alpha: 0.2), color: Colors.green),
                ),
              ),
              const SizedBox(width: 8),
              Text('${totalProg.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectReportList(List<QueryDocumentSnapshot> projects) {
    if (projects.isEmpty) return const Center(child: Text('No active projects to report.', style: TextStyle(color: Colors.grey)));
    
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final pDoc = projects[index];
        final p = pDoc.data() as Map<String, dynamic>;
        final double prog = p['progress']?.toDouble() ?? 0.0;
        final String leaderId = p['team_leader_id'] ?? '';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E2E4))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p['project_name'] ?? 'Project', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildReportRow('Project leader:', leaderId, isUser: true),
                    _buildReportRow('Project status:', p['status'] ?? 'Active'),
                    _buildReportRow('Project priority:', p['priority'] ?? 'Medium'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildPieProgress(prog),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value, {bool isUser = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: isUser
                ? _UserMiniInfo(uid: value)
                : Text(
                    value,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieProgress(double progress) {
    return SizedBox(
      width: 80, height: 80,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0, centerSpaceRadius: 0,
          sections: [
            PieChartSectionData(value: progress, color: Colors.green, radius: 40, showTitle: false),
            PieChartSectionData(value: 100 - progress, color: const Color(0xFF4B89FF), radius: 40, showTitle: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskProgressOverTimeCard(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('submissions')
          .where('user_id', isEqualTo: uid)
          .where('approval_status', isEqualTo: 'Approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;

        Map<DateTime, int> dailyCounts = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['review_date'] != null) {
            DateTime fullDate = (data['review_date'] as Timestamp).toDate();
            DateTime dayOnly = DateTime(fullDate.year, fullDate.month, fullDate.day);
            dailyCounts[dayOnly] = (dailyCounts[dayOnly] ?? 0) + 1;
          }
        }

        List<DateTime> sortedDates = dailyCounts.keys.toList()..sort();
        
        List<FlSpot> spots = [];
        double maxCount = 5;

        if (sortedDates.isEmpty) {
          spots = [const FlSpot(0, 0)];
        } else {
          for (int i = 0; i < sortedDates.length; i++) {
            double count = dailyCounts[sortedDates[i]]!.toDouble();
            spots.add(FlSpot(i.toDouble(), count));
            if (count > maxCount) maxCount = count;
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF3EEFC), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.show_chart_rounded, color: Color(0xFF4B0AAA), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task Progress Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Daily count of your approved tasks.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  _Legend(color: Color(0xFF4B0AAA), label: 'Tasks Approved'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxCount + 1,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                      getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ),
                        axisNameWidget: const Text('Number of Tasks', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        axisNameSize: 20,
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (val, meta) {
                            int idx = val.toInt();
                            if (idx >= 0 && idx < sortedDates.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(DateFormat('d MMM').format(sortedDates[idx]), style: const TextStyle(color: Colors.grey, fontSize: 9)),
                              );
                            }
                            return const SizedBox();
                          }
                        ),
                        axisNameWidget: const Text('Date', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        axisNameSize: 20,
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade400, width: 1.5),
                        left: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF4B0AAA),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: const Color(0xFF4B0AAA).withValues(alpha: 0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _UserMiniInfo extends StatelessWidget {
  final String uid;
  const _UserMiniInfo({required this.uid});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String name = data?['name'] ?? 'Unknown';
        final String pic = data?['profile_picture'] ?? '';
        ImageProvider? img = pic.isNotEmpty ? (pic.startsWith('assets') ? AssetImage(pic) : NetworkImage(pic)) as ImageProvider : null;
        return Row(
          children: [
            CircleAvatar(radius: 8, backgroundImage: img, child: img == null ? const Icon(Icons.person, size: 8) : null),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
