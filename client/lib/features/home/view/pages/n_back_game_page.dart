import 'dart:async';
import 'package:client/features/home/model/settings_model.dart';
import 'package:flutter/material.dart';
import '../../viewmodel/n_back_game_viewmodel.dart';
import '../../model/today_best_result_storage.dart';
import '../../model/game_result_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/providers/current_user_notifier.dart';

class NBackGamePage extends ConsumerStatefulWidget {
  const NBackGamePage({super.key});

  @override
  ConsumerState<NBackGamePage> createState() => _NBackGamePageState();
}

class _NBackGamePageState extends ConsumerState<NBackGamePage> {
  NBackGameViewModel? viewModel;
  Timer? _timer;

  // Śledzenie kliknięć użytkownika w danym kroku
  bool positionClicked = false;
  bool letterClicked = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final settings = await SettingsModel.load();
    debugPrint('Ładowany poziom: ${settings.currentLevel}');
    setState(() {
      viewModel = NBackGameViewModel(level: settings.currentLevel);
    });
    _startStepTimer();
  }

  void _startStepTimer() {
    _timer?.cancel();
    _resetClicks();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _evaluateStep();
      if (!viewModel!.isFinished()) {
        setState(() {
          viewModel!.nextStep();
          _resetClicks();
        });
      } else {
        _timer?.cancel();
        _showEndDialog();
      }
    });
  }

  void _resetClicks() {
    positionClicked = false;
    letterClicked = false;
  }

  void _handlePositionMatch() {
    if (!positionClicked && viewModel!.canCheckMatch()) {
      setState(() {
        viewModel!.checkPositionMatch(userClicked: true);
        positionClicked = true;
      });
    }
  }

  void _handleLetterMatch() {
    if (!letterClicked && viewModel!.canCheckMatch()) {
      setState(() {
        viewModel!.checkLetterMatch(userClicked: true);
        letterClicked = true;
      });
    }
  }

  // Sprawdzenie punktów na koniec kroku (jeśli użytkownik nie kliknął)
  void _evaluateStep() {
    if (viewModel!.canCheckMatch()) {
      if (!positionClicked) {
        viewModel!.checkPositionMatch(userClicked: false);
      }
      if (!letterClicked) {
        viewModel!.checkLetterMatch(userClicked: false);
      }
    }
  }

  void _showEndDialog() async {
    // Pobierz userId jeśli dostępny (przez Riverpod)
    final user = ref.read(currentUserNotifierProvider);
    final userId = user?.id ?? 'local';

    final result = GameResultModel(
      userId: userId,
      score: viewModel!.score,
      submittedAt: DateTime.now(),
      level: viewModel!.level,
    );
    // Testowanie i zapis wyniku
    final wasSaved = await saveTodayBestResult(result);
    if (wasSaved) {
      debugPrint(
        'Dodano wynik: userId=${result.userId}, score=${result.score}, level=${result.level}, submittedAt=${result.submittedAt.toIso8601String()}'
      );
    } else {
      final todayBest = await getTodayBestResult();
      debugPrint(
        'Wynik NIE został zapisany (nie był lepszy niż dzisiejszy najlepszy: '
        'level=${todayBest?.level}, score=${todayBest?.score}).'
      );
    }

    // --- AKTUALIZACJA POZIOMU ---
    // Załaduj aktualne ustawienia
    // Przykład z domyślnym SettingsModel:
    SettingsModel currentSettings = SettingsModel(currentLevel: viewModel!.level);
    final updatedSettings = viewModel!.updateLevel(currentSettings);
    debugPrint('Aktualny poziom po grze: ${updatedSettings.currentLevel}');

    await SettingsModel.save(updatedSettings);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Koniec gry'),
        content: Text('Twój wynik: ${viewModel!.score}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initGame();
            },
            child: const Text('Zagraj ponownie'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual N-Back Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                viewModel!.generateSequence();
                _resetClicks();
                _startStepTimer();
              });
            },
            tooltip: 'Nowa gra',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Level: ${viewModel!.level}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: GridView.builder(
                itemCount: viewModel!.gridSize,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  bool isActive = index == viewModel!.currentPosition;
                  return Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              viewModel!.currentLetter,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (viewModel!.canCheckMatch() && !positionClicked) ? _handlePositionMatch : null,
                      child: const Text(
                        'Position Match',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (viewModel!.canCheckMatch() && !letterClicked) ? _handleLetterMatch : null,
                      child: const Text(
                        'Letter Match',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Score: ${viewModel!.score}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              'Krok: ${viewModel!.currentStep + 1} / ${viewModel!.sequenceLength}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
