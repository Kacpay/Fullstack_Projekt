import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/model/game_result_model.dart';
import 'package:client/features/home/repositories/home_remote_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fpdart/fpdart.dart';

// Strona statystyk N-Back, wyświetla wykres i listę wyników
class NBackStatsPage extends ConsumerStatefulWidget {
  const NBackStatsPage({super.key});

  @override
  ConsumerState<NBackStatsPage> createState() => _NBackStatsPageState();
}

class _NBackStatsPageState extends ConsumerState<NBackStatsPage> {
  // Przechowuje przyszłe wyniki do wyświetlenia
  late Future<List<GameResultModel>> _recentResultsFuture;
  // Kontroler pola tekstowego do porównania użytkownika
  final TextEditingController _usernameController = TextEditingController();

  List<GameResultModel>? _otherUserResults;
  String? _otherUserError;
  bool _isLoadingOther = false;

  @override
  void initState() {
    super.initState();
    // Pobierz wyniki po uruchomieniu strony
    _recentResultsFuture = _fetchRecentResults();
  }

  // Pobiera ostatnie wyniki zalogowanego użytkownika
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

  Future<void> _fetchOtherUserResults() async {
    setState(() {
      _isLoadingOther = true;
      _otherUserResults = null;
      _otherUserError = null;
    });
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _otherUserError = 'Enter username';
        _isLoadingOther = false;
      });
      return;
    }
    final user = ref.read(currentUserNotifierProvider);
    if (user == null) {
      setState(() {
        _otherUserError = 'Not logged in';
        _isLoadingOther = false;
      });
      return;
    }
    final repo = ref.read(homeRemoteRepositoryProvider);
    final res = await repo.getRecentResultsByUsername(username: username, token: user.token);
    setState(() {
      _isLoadingOther = false;
      switch (res) {
        case Left(value: final failure):
          _otherUserError = failure.message;
          _otherUserResults = null;
        case Right(value: final list):
          _otherUserResults = list;
          _otherUserError = null;
      }
    });
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
      body: Column(
        children: [
          // Główna część strony - wyniki i wykres
          Expanded(
            child: FutureBuilder<List<GameResultModel>>(
              future: _recentResultsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  // Pokazuje loader podczas ładowania danych
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  // Komunikat, gdy brak danych
                  return const Center(
                    child: Text('No data to display.', style: TextStyle(color: Colors.white)),
                  );
                }
                // Sortowanie wyników po dacie
                results.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nagłówek
                        const Text(
                          'Last 5 Results',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        // Wykres słupkowy z wynikami
                        SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              barTouchData: BarTouchData(
                                enabled: false,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: Colors.black87,
                                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  tooltipMargin: 8,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final idx = group.x.toInt();
                                    final value = (results[idx].level * 10 + results[idx].score);
                                    String? otherValue;
                                    String? otherUsername = _usernameController.text.trim();
                                    if (_otherUserResults != null && idx < _otherUserResults!.length) {
                                      otherValue = (_otherUserResults![idx].level * 10 + _otherUserResults![idx].score).toString();
                                    }
                                    String tooltip = 'You: $value';
                                    if (otherValue != null && otherUsername.isNotEmpty) {
                                      tooltip += '\n$otherUsername: $otherValue';
                                    }
                                    return BarTooltipItem(
                                      tooltip,
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                horizontalInterval: 10,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(color: Colors.white12, strokeWidth: 1);
                                }
                              ),
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
                                      // Podpisy pod słupkami (dzień.miesiąc)
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
                              // Maksymalna wartość osi Y na podstawie wyników
                              maxY: [
                                ...results.map((e) => e.level * 10 + e.score),
                                ...?_otherUserResults?.map((e) => e.level * 10 + e.score)
                              ].fold<double>(0, (prev, e) => e > prev ? e.toDouble() : prev) + 5,
                              // Dane do słupków wykresu
                              barGroups: [
                                for (int i = 0; i < results.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: (results[i].level * 10 + results[i].score).toDouble(),
                                        color: Pallete.gradient1,
                                        width: 18,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      if (_otherUserResults != null && i < _otherUserResults!.length)
                                        BarChartRodData(
                                          toY: (_otherUserResults![i].level * 10 + _otherUserResults![i].score).toDouble(),
                                          color: Pallete.blueColor,
                                          width: 12,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                    ],
                                    showingTooltipIndicators: [0],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Pole tekstowe do wpisania nazwy użytkownika do porównania (na razie bez logiki)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter username to compare',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: _isLoadingOther ? null : _fetchOtherUserResults,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Pallete.gradient2,
                            ),
                            child: _isLoadingOther
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Show user results', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        if (_otherUserError != null)
                          Text(_otherUserError!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 16),
                        // Dwie kolumny z wynikami użytkowników w jednym widgecie
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kolumna zalogowanego użytkownika
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your results',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  ...results.map((r) => Card(
                                        color: Colors.white10,
                                        child: ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundColor: Pallete.gradient2,
                                            child: Text(
                                              '${r.score}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'Level: ${r.level}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          subtitle: Text(
                                            'Date: ${r.submittedAt.day}.${r.submittedAt.month}.${r.submittedAt.year}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Kolumna porównywanego użytkownika
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _usernameController.text.trim().isEmpty
                                        ? 'Compared user'
                                        : _usernameController.text.trim(),
                                    style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_otherUserResults != null && _otherUserResults!.isNotEmpty)
                                    ..._otherUserResults!.map((r) => Card(
                                          color: Colors.blueGrey.shade900,
                                          child: ListTile(
                                            dense: true,
                                            leading: CircleAvatar(
                                              backgroundColor: Pallete.blueColor,
                                              child: Text(
                                                '${r.score}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              'Level: ${r.level}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            subtitle: Text(
                                              'Date: ${r.submittedAt.day}.${r.submittedAt.month}.${r.submittedAt.year}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ),
                                        ))
                                  else
                                    const Text('No data', style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}