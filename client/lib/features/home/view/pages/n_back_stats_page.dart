import 'package:client/core/providers/current_user_notifier.dart';
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
      appBar: AppBar(title: const Text('Ostatnie wyniki')),
      body: FutureBuilder<List<GameResultModel>>(
        future: _recentResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(child: Text('Brak wyników do wyświetlenia.'));
          }
          results.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Ostatnie 5 wyników',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
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
                                child: Text('${date.day}.${date.month}'),
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
                                color: Theme.of(context).colorScheme.primary,
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
                        leading: CircleAvatar(child: Text('${r.score}')),
                        title: Text('Poziom: ${r.level}'),
                        subtitle: Text('Data: ${r.submittedAt.day}.${r.submittedAt.month}.${r.submittedAt.year}'),
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