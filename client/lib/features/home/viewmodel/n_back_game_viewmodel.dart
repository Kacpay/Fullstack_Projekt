import 'dart:math';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/features/auth/model/user_model.dart';
import 'package:client/features/home/model/game_result_model.dart';
import 'package:client/features/home/repositories/home_remote_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../model/n_back_sequence.dart';
import '../model/settings_model.dart';

final nBackGameRemoteViewModelProvider = Provider<NBackGameRemoteViewModel>((ref) {
  return NBackGameRemoteViewModel(
    ref.read(homeRemoteRepositoryProvider),
    ref.read(currentUserNotifierProvider),
  );
});

class NBackGameRemoteViewModel {
  final HomeRemoteRepository repo;
  final UserModel? user;

  NBackGameRemoteViewModel(this.repo, this.user);

  Future<String> saveOrUpdateResult(GameResultModel result) async {
    if (user == null) return 'Brak użytkownika';
    final addRes = await repo.addResult(result: result, token: user!.token);
    switch (addRes) {
      case Left(value: final failure):
        if (failure.message.contains('already exists') || failure.message.contains('istnieje')) {
          final updateRes = await repo.updateResult(result: result, token: user!.token);
          switch (updateRes) {
            case Left(value: final updateFailure):
              return 'Błąd aktualizacji: ${updateFailure.message}';
            case Right(value: final updated):
              return 'Wynik zaktualizowany: $updated';
          }
        } else {
          return 'Błąd dodawania: ${failure.message}';
        }
      case Right(value: final added):
        return 'Wynik dodany: $added';
    }
  }
}

class NBackGameViewModel {
  final int level;
  late final int sequenceLength;
  final List<String> possibleLetters = List.generate(26, (i) => String.fromCharCode(65 + i)); // A-Z
  final int gridSize = 9;

  late NBackSequence sequence;
  int currentStep = 0;
  int score = 0;

  NBackGameViewModel({this.level = 1}) {
    sequenceLength = 20 + level;
    generateSequence();
  }

  void generateSequence() {
    final rand = Random();
    List<String> letters = List.filled(sequenceLength, '');
    List<int> positions = List.filled(sequenceLength, 0);

    // Wypełnij pierwsze "level" losowo
    for (int i = 0; i < level; i++) {
      letters[i] = possibleLetters[rand.nextInt(possibleLetters.length)];
      positions[i] = rand.nextInt(gridSize);
    }

    // Od "level" generuj z 40% szansą zgodności z n-back
    for (int i = level; i < sequenceLength; i++) {
      // Litery
      if (rand.nextDouble() < 0.4) {
        letters[i] = letters[i - level];
      } else {
        // Unikaj przypadkowej zgodności
        String newLetter;
        do {
          newLetter = possibleLetters[rand.nextInt(possibleLetters.length)];
        } while (newLetter == letters[i - level]);
        letters[i] = newLetter;
      }
      // Pozycje
      if (rand.nextDouble() < 0.4) {
        positions[i] = positions[i - level];
      } else {
        int newPos;
        do {
          newPos = rand.nextInt(gridSize);
        } while (newPos == positions[i - level]);
        positions[i] = newPos;
      }
    }

    sequence = NBackSequence(
      letters: letters,
      positions: positions,
    );
    currentStep = 0;
    score = 0;
  }

  String get currentLetter => sequence.letters[currentStep];
  int get currentPosition => sequence.positions[currentStep];

  bool canCheckMatch() => currentStep >= level;

  void nextStep() {
    if (currentStep < sequenceLength - 1) {
      currentStep++;
    }
  }

  bool checkPositionMatch({required bool userClicked}) {
    if (!canCheckMatch()) return false;
    bool match = sequence.positions[currentStep] == sequence.positions[currentStep - level];
    if ((userClicked && match) || (!userClicked && !match)) {
      score++;
    }
    return match;
  }

  bool checkLetterMatch({required bool userClicked}) {
    if (!canCheckMatch()) return false;
    bool match = sequence.letters[currentStep] == sequence.letters[currentStep - level];
    if ((userClicked && match) || (!userClicked && !match)) {
      score++;
    }
    return match;
  }

  bool isFinished() => currentStep >= sequenceLength - 1;

  /// Aktualizuje poziom w zależności od wyniku.
  /// Zwraca nowy SettingsModel z odpowiednim currentLevel.
  SettingsModel updateLevel(SettingsModel settings) {
    int newLevel = settings.currentLevel;
    if (score >= 36) {
      newLevel += 1;
    } else if (score < 32 && newLevel > 1) {
      newLevel -= 1;
    }
    return settings.copyWith(currentLevel: newLevel);
  }
}