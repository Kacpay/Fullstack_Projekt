import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../viewmodel/n_back_game_viewmodel.dart';
import '../../model/game_result_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/features/home/repositories/home_local_repository.dart';
import 'package:client/core/theme/app_pallete.dart';

class NBackGamePage extends ConsumerStatefulWidget {
  const NBackGamePage({super.key});

  @override
  ConsumerState<NBackGamePage> createState() => _NBackGamePageState();
}

class _NBackGamePageState extends ConsumerState<NBackGamePage> {
  NBackGameViewModel? viewModel;
  Timer? _timer;
  final FlutterTts _tts = FlutterTts(); // Dodaj TTS

  // Śledzenie kliknięć użytkownika w danym kroku
  bool positionClicked = false;
  bool letterClicked = false;

  final homeRepo = HomeLocalRepository();

  @override
  void initState() {
    super.initState();
    _initGame();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // Dodaj wywołanie TTS przy każdej zmianie litery
  void _speakCurrentLetter() {
    final letter = viewModel?.currentLetter;
    if (letter != null && letter.isNotEmpty) {
      _tts.stop();
      _tts.speak(letter);
    }
  }

  Future<void> _initGame() async {
    final settings = await homeRepo.loadSettings();
    debugPrint('Ładowany poziom: ${settings.currentLevel}');
    setState(() {
      viewModel = NBackGameViewModel(level: settings.currentLevel);
    });
    _speakCurrentLetter(); // Odtwórz dźwięk pierwszej litery
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
        _speakCurrentLetter(); // Odtwórz dźwięk nowej litery
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
    final wasSaved = await homeRepo.saveTodayBestResult(result);
    if (wasSaved) {
      debugPrint(
        'Dodano wynik: userId=${result.userId}, score=${result.score}, level=${result.level}, submittedAt=${result.submittedAt.toIso8601String()}'
      );
    } else {
      final todayBest = await homeRepo.getTodayBestResult();
      debugPrint(
        'Wynik NIE został zapisany (nie był lepszy niż dzisiejszy najlepszy: '
        'level=${todayBest?.level}, score=${todayBest?.score}).'
      );
    }

    // --- AKTUALIZACJA POZIOMU ---
    // Załaduj aktualne ustawienia
    final currentSettings = await homeRepo.loadSettings();
    final updatedSettings = viewModel!.updateLevel(currentSettings);
    debugPrint('Aktualny poziom po grze: ${updatedSettings.currentLevel}');

    await homeRepo.saveSettings(updatedSettings);

    final remoteViewModel = ref.read(nBackGameRemoteViewModelProvider);
    final msg = await remoteViewModel.saveOrUpdateResult(result);
    debugPrint(msg);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session Ended'),
        content: Text('Score: ${viewModel!.score}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Level: ${viewModel!.level}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                          ? Pallete.gradient2.withOpacity(0.7)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              viewModel!.currentLetter,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.gradient1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: (viewModel!.canCheckMatch() && !positionClicked) ? _handlePositionMatch : null,
                      child: const Text(
                        'Position Match',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.gradient1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: (viewModel!.canCheckMatch() && !letterClicked) ? _handleLetterMatch : null,
                      child: const Text(
                        'Letter Match',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Score: ${viewModel!.score}',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Step: ${viewModel!.currentStep + 1} / ${viewModel!.sequenceLength}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
