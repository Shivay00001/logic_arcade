import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// GAME LOGIC / MODEL
// -----------------------------------------------------------------------------

class SlidingPuzzleProvider extends ChangeNotifier {
  static const int gridSize = 4;
  static const int totalTiles = gridSize * gridSize - 1; // 15 tiles + 1 empty space

  late List<List<int>> _grid;
  int _moves = 0;
  bool _gameComplete = false;
  int _emptyRow = gridSize - 1;
  int _emptyCol = gridSize - 1;

  List<List<int>> get grid => _grid;
  int get moves => _moves;
  bool get gameComplete => _gameComplete;
  int get emptyRow => _emptyRow;
  int get emptyCol => _emptyCol;

  SlidingPuzzleProvider() {
    _startNewGame();
  }

  void _startNewGame() {
    _grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    _moves = 0;
    _gameComplete = false;

    // Create solved state
    int number = 1;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (i == gridSize - 1 && j == gridSize - 1) {
          _grid[i][j] = 0; // Empty space
        } else {
          _grid[i][j] = number++;
        }
      }
    }

    _emptyRow = gridSize - 1;
    _emptyCol = gridSize - 1;

    // Shuffle the puzzle
    _shufflePuzzle();
    notifyListeners();
  }

  void _shufflePuzzle() {
    // Perform random valid moves to shuffle
    Random random = Random();
    for (int i = 0; i < 1000; i++) {
      List<Point<int>> possibleMoves = _getPossibleMoves();
      if (possibleMoves.isNotEmpty) {
        Point<int> move = possibleMoves[random.nextInt(possibleMoves.length)];
        _moveTile(move.x, move.y);
      }
    }
    _moves = 0; // Reset move counter after shuffling
  }

  List<Point<int>> _getPossibleMoves() {
    List<Point<int>> moves = [];

    // Check all four directions
    if (_emptyRow > 0) moves.add(Point(_emptyRow - 1, _emptyCol)); // Up
    if (_emptyRow < gridSize - 1) moves.add(Point(_emptyRow + 1, _emptyCol)); // Down
    if (_emptyCol > 0) moves.add(Point(_emptyRow, _emptyCol - 1)); // Left
    if (_emptyCol < gridSize - 1) moves.add(Point(_emptyRow, _emptyCol + 1)); // Right

    return moves;
  }

  void tryMove(int row, int col) {
    // Check if the tile is adjacent to empty space
    if ((row == _emptyRow && (col == _emptyCol - 1 || col == _emptyCol + 1)) ||
        (col == _emptyCol && (row == _emptyRow - 1 || row == _emptyRow + 1))) {
      _moveTile(row, col);
      _moves++;
      _checkCompletion();
      notifyListeners();
    }
  }

  void _moveTile(int row, int col) {
    // Swap with empty space
    _grid[_emptyRow][_emptyCol] = _grid[row][col];
    _grid[row][col] = 0;
    _emptyRow = row;
    _emptyCol = col;
  }

  void _checkCompletion() {
    int expectedNumber = 1;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (i == gridSize - 1 && j == gridSize - 1) {
          if (_grid[i][j] != 0) return; // Must be empty
        } else {
          if (_grid[i][j] != expectedNumber) return;
          expectedNumber++;
        }
      }
    }
    _gameComplete = true;
  }

  void restart() => _startNewGame();

  bool isTileMovable(int row, int col) {
    return (row == _emptyRow && (col == _emptyCol - 1 || col == _emptyCol + 1)) ||
           (col == _emptyCol && (row == _emptyRow - 1 || row == _emptyRow + 1));
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class SlidingPuzzleGame extends StatelessWidget {
  const SlidingPuzzleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SlidingPuzzleProvider(),
      child: const _SlidingPuzzleGameContent(),
    );
  }
}

class _SlidingPuzzleGameContent extends StatelessWidget {
  const _SlidingPuzzleGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SlidingPuzzleProvider>();

    if (provider.gameComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text("Puzzle Solved!", style: TextStyle(color: Colors.white)),
            content: Text("Completed in ${provider.moves} moves!", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  provider.restart();
                },
                child: const Text("New Puzzle"),
              )
            ],
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Sliding Puzzle", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "Moves: ${provider.moves}",
                style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.text),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.restart,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
              ),
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 16,
                itemBuilder: (ctx, index) {
                  int row = index ~/ 4;
                  int col = index % 4;
                  int number = provider.grid[row][col];
                  bool isMovable = provider.isTileMovable(row, col);

                  return _PuzzleTile(
                    number: number,
                    isMovable: isMovable,
                    onTap: () => provider.tryMove(row, col),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PuzzleTile extends StatelessWidget {
  final int number;
  final bool isMovable;
  final VoidCallback onTap;

  const _PuzzleTile({
    required this.number,
    required this.isMovable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (number == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isMovable ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMovable ? AppTheme.primary.withOpacity(0.5) : AppTheme.textSecondary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isMovable ? [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          "$number",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isMovable ? Colors.white : AppTheme.text,
          ),
        ),
      ),
    );
  }
}