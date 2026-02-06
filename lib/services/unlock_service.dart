import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnlockService extends ChangeNotifier {
  static final UnlockService _instance = UnlockService._internal();
  factory UnlockService() => _instance;
  UnlockService._internal();

  // Game identifiers for unlocks
  static const String ticTacToe = 'tic_tac_toe';
  static const String chess = 'chess';
  static const String checkers = 'checkers';
  static const String ludo = 'ludo';
  static const String carrom = 'carrom';
  static const String minesweeper = 'minesweeper';
  static const String connectFour = 'connect_four';

  Map<String, bool> _gameUnlocks = {};

  bool isGameUnlocked(String gameId) => _gameUnlocks[gameId] ?? false;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // List of games that have AI/single-player modes
    List<String> gamesWithAI = [
      ticTacToe,
      chess,
      checkers,
      ludo,
      carrom,
      minesweeper,
      connectFour,
    ];

    for (String gameId in gamesWithAI) {
      _gameUnlocks[gameId] = prefs.getBool('${gameId}_unlocked') ?? false;
    }

    notifyListeners();
  }

  Future<void> unlockGame(String gameId) async {
    _gameUnlocks[gameId] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${gameId}_unlocked', true);
    notifyListeners();
  }
}