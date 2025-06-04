import 'dart:convert';
import 'package:client/core/constants/server_constants.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/features/home/model/game_result_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_remote_repository.g.dart';

@riverpod
HomeRemoteRepository homeRemoteRepository(HomeRemoteRepositoryRef ref) {
  return HomeRemoteRepository();
}

class HomeRemoteRepository {
  Future<Either<AppFailure, GameResultModel>> addResult({
    required GameResultModel result,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstants.serverURL}/nback/'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'score': result.score,
          'level': result.level,
          'submitted_at': result.submittedAt.toUtc().toIso8601String(),
        }),
      );
      if (response.statusCode != 201) {
        final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail'] ?? 'Błąd dodawania wyniku'));
      }
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Right(GameResultModel.fromMap(resBodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, GameResultModel>> updateResult({
    required GameResultModel result,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ServerConstants.serverURL}/nback/'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'score': result.score,
          'level': result.level,
          'submitted_at': result.submittedAt.toUtc().toIso8601String(),
        }),
      );
      if (response.statusCode != 200) {
        final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail'] ?? 'Błąd aktualizacji wyniku'));
      }
      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Right(GameResultModel.fromMap(resBodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<GameResultModel>>> getRecentResults({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/nback/recent'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      if (response.statusCode != 200) {
        final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail'] ?? 'Błąd pobierania wyników'));
      }
      final resBodyList = jsonDecode(response.body) as List<dynamic>;
      final results = resBodyList
          .map((e) => GameResultModel.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(results);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

// Pobierz wyniki dla konkretnego użytkownika do porównania

  Future<Either<AppFailure, List<GameResultModel>>> getRecentResultsByUsername({
    required String username,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/nback/recent/$username'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      if (response.statusCode != 200) {
        final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail'] ?? 'Błąd pobierania wyników'));
      }
      final resBodyList = jsonDecode(response.body) as List<dynamic>;
      final results = resBodyList
          .map((e) => GameResultModel.fromMap(e as Map<String, dynamic>))
          .toList();
      return Right(results);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}