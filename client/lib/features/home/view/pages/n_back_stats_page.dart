import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/model/game_result_model.dart';
import 'package:client/features/home/repositories/home_remote_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fpdart/fpdart.dart';

class NBackStatsPage extends ConsumerStatefulWidget {
  const NBackStatsPage({super.key});

  @override
  ConsumerState<NBackStatsPage> createState() => _NBackStatsPageState();
}

class _NBackStatsPageState extends ConsumerState<NBackStatsPage> {
  late Future<List<GameResultModel>> _recentResultsFuture;

  @override
  void initState() {
    super.initState();
    _recentResultsFuture = _fetchRecentResults();
  }

  Future<List<GameResultModel>> _fetchRecentResults() async {
    final user = ref.read(currentUserNotifierProvider);
    if (user == null) return [];
    final repo = ref.read(homeRemoteRepositoryProvider);
    final res = await repo.getRecentResults(token: user.token);
    switch (res) {
      case Left():
        return [];
      case Right(value: final list):
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Last Results', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<GameResultModel>>(
        future: _recentResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(
              child: Text('No data to display.', style: TextStyle(color: Colors.white)),
            );
          }
          results.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Last 5 Results',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        enabled: false,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.transparent,
                          tooltipPadding: EdgeInsets.zero,
                          tooltipMargin: 0,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final value = (results[group.x.toInt()].level * 10 + results[group.x.toInt()].score);
                            return BarTooltipItem(
                              '$value',
                              TextStyle(
                                color: Pallete.gradient1,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ),
                      gridData: FlGridData(show: true, drawHorizontalLine: true, horizontalInterval: 10, getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.white12, strokeWidth: 1);
                      }),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: Colors.white24),
                          bottom: BorderSide(color: Colors.white24),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= results.length) return const SizedBox();
                              final date = results[idx].submittedAt;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${date.day}.${date.month}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      minY: 0,
                      maxY: results
                              .map((e) => e.level * 10 + e.score)
                              .fold<double>(0, (prev, e) => e > prev ? e.toDouble() : prev) +
                          5,
                      barGroups: [
                        for (int i = 0; i < results.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: (results[i].level * 10 + results[i].score).toDouble(),
                                color: Pallete.gradient1,
                                width: 24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                            showingTooltipIndicators: [0],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final r = results[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Pallete.gradient2,
                          child: Text(
                            '${r.score}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'Level: ${r.level}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Date: ${r.submittedAt.day}.${r.submittedAt.month}.${r.submittedAt.year}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}