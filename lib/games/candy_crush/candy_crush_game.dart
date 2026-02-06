import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// CANDY CRUSH LOGIC
// -----------------------------------------------------------------------------

class Candy {
  String type;
  Color color;

  Candy(this.type, this.color);

  static List<Candy> getCandyTypes() {
    return [
      Candy('🍬', Colors.red),
      Candy('🍭', Colors.blue),
      Candy('🍪', Colors.green),
      Candy('🍫', Colors.brown),
      Candy('🍩', Colors.yellow),
      Candy('🧁', Colors.purple),
    ];
  }
}

class CandyCrushProvider extends ChangeNotifier {
  static const int boardWidth = 8;
  static const int boardHeight = 8;

  late List<List<Candy?>> _board;
  int _score = 0;
  bool _gameOver = false;
  int _movesLeft = 30;
  Candy? _selectedCandy;
  int? _selectedRow, _selectedCol;

  List<List<Candy?>> get board => _board;
  int get score => _score;
  bool get gameOver => _gameOver;
  int get movesLeft => _movesLeft;
  Candy? get selectedCandy => _selectedCandy;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;

  CandyCrushProvider() {
    _initializeBoard();
  }

  void _initializeBoard() {
    _board = List.generate(boardHeight, (_) => List.generate(boardWidth, (_) => null));
    _score = 0;
    _gameOver = false;
    _movesLeft = 30;
    _selectedCandy = null;
    _selectedRow = null;
    _selectedCol = null;

    _fillBoard();

    // Keep generating until no initial matches
    while (_findMatches().isNotEmpty) {
      _fillBoard();
    }
  }

  void _fillBoard() {
    List<Candy> candyTypes = Candy.getCandyTypes();
    Random random = Random();

    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        _board[row][col] = candyTypes[random.nextInt(candyTypes.length)];
      }
    }
  }

  void selectCandy(int row, int col) {
    if (_gameOver) return;

    if (_selectedCandy == null) {
      // Select candy
      _selectedCandy = _board[row][col];
      _selectedRow = row;
      _selectedCol = col;
    } else if (_selectedRow == row && _selectedCol == col) {
      // Deselect
      _selectedCandy = null;
      _selectedRow = null;
      _selectedCol = null;
    } else if (_isAdjacent(_selectedRow!, _selectedCol!, row, col)) {
      // Try to swap
      _swapCandies(_selectedRow!, _selectedCol!, row, col);
      _movesLeft--;

      // Check for matches after swap
      List<List<int>> matches = _findMatches();
      if (matches.isNotEmpty) {
        _removeMatches(matches);
        _applyGravity();
        _fillEmptySpaces();

        // Check for new matches
        while (_findMatches().isNotEmpty) {
          matches = _findMatches();
          _removeMatches(matches);
          _applyGravity();
          _fillEmptySpaces();
        }
      } else {
        // Invalid move, swap back
        _swapCandies(_selectedRow!, _selectedCol!, row, col);
        _movesLeft++; // Don't count invalid moves
      }

      _selectedCandy = null;
      _selectedRow = null;
      _selectedCol = null;

      // Check game over
      if (_movesLeft <= 0 || !_hasValidMoves()) {
        _gameOver = true;
      }
    } else {
      // Select new candy
      _selectedCandy = _board[row][col];
      _selectedRow = row;
      _selectedCol = col;
    }

    notifyListeners();
  }

  bool _isAdjacent(int r1, int c1, int r2, int c2) {
    return ((r1 == r2 && (c1 - c2).abs() == 1) || (c1 == c2 && (r1 - r2).abs() == 1));
  }

  void _swapCandies(int r1, int c1, int r2, int c2) {
    Candy? temp = _board[r1][c1];
    _board[r1][c1] = _board[r2][c2];
    _board[r2][c2] = temp;
  }

  List<List<int>> _findMatches() {
    List<List<int>> matches = [];

    // Check horizontal matches
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth - 2; col++) {
        if (_board[row][col] != null &&
            _board[row][col]!.type == _board[row][col + 1]?.type &&
            _board[row][col]!.type == _board[row][col + 2]?.type) {
          matches.add([row, col]);
          matches.add([row, col + 1]);
          matches.add([row, col + 2]);
        }
      }
    }

    // Check vertical matches
    for (int col = 0; col < boardWidth; col++) {
      for (int row = 0; row < boardHeight - 2; row++) {
        if (_board[row][col] != null &&
            _board[row][col]!.type == _board[row + 1][col]?.type &&
            _board[row][col]!.type == _board[row + 2][col]?.type) {
          matches.add([row, col]);
          matches.add([row + 1, col]);
          matches.add([row + 2, col]);
        }
      }
    }

    // Remove duplicates
    Set<String> uniqueMatches = {};
    List<List<int>> uniqueMatchesList = [];
    for (List<int> match in matches) {
      String key = '${match[0]},${match[1]}';
      if (!uniqueMatches.contains(key)) {
        uniqueMatches.add(key);
        uniqueMatchesList.add(match);
      }
    }

    return uniqueMatchesList;
  }

  void _removeMatches(List<List<int>> matches) {
    for (List<int> match in matches) {
      _board[match[0]][match[1]] = null;
    }
    _score += matches.length * 10;
  }

  void _applyGravity() {
    for (int col = 0; col < boardWidth; col++) {
      List<Candy?> column = [];
      for (int row = boardHeight - 1; row >= 0; row--) {
        if (_board[row][col] != null) {
          column.add(_board[row][col]);
        }
      }

      // Clear column
      for (int row = 0; row < boardHeight; row++) {
        _board[row][col] = null;
      }

      // Place candies at bottom
      for (int i = 0; i < column.length; i++) {
        _board[boardHeight - 1 - i][col] = column[i];
      }
    }
  }

  void _fillEmptySpaces() {
    List<Candy> candyTypes = Candy.getCandyTypes();
    Random random = Random();

    for (int col = 0; col < boardWidth; col++) {
      for (int row = 0; row < boardHeight; row++) {
        if (_board[row][col] == null) {
          _board[row][col] = candyTypes[random.nextInt(candyTypes.length)];
        }
      }
    }
  }

  bool _hasValidMoves() {
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        // Try swapping with adjacent candies
        List<List<int>> adjacent = [
          [row, col + 1],
          [row, col - 1],
          [row + 1, col],
          [row - 1, col],
        ];

        for (List<int> adj in adjacent) {
          int adjRow = adj[0];
          int adjCol = adj[1];

          if (adjRow >= 0 && adjRow < boardHeight && adjCol >= 0 && adjCol < boardWidth) {
            // Try swap
            _swapCandies(row, col, adjRow, adjCol);
            bool hasMatch = _findMatches().isNotEmpty;
            _swapCandies(row, col, adjRow, adjCol); // Swap back

            if (hasMatch) return true;
          }
        }
      }
    }
    return false;
  }

  void restart() {
    _initializeBoard();
    notifyListeners();
  }

  bool isSelected(int row, int col) {
    return _selectedRow == row && _selectedCol == col;
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class CandyCrushGame extends StatelessWidget {
  const CandyCrushGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CandyCrushProvider(),
      child: const _CandyCrushGameContent(),
    );
  }
}

class _CandyCrushGameContent extends StatelessWidget {
  const _CandyCrushGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CandyCrushProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Candy Crush", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "Score: ${provider.score} | Moves: ${provider.movesLeft}",
                style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.text),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.restart,
          ),
        ],
      ),
      body: Column(
        children: [
          // Game board
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: 64,
                      itemBuilder: (ctx, index) {
                        int row = index ~/ 8;
                        int col = index % 8;
                        Candy? candy = provider.board[row][col];
                        bool isSelected = provider.isSelected(row, col);
                        return _CandyCell(
                          candy: candy,
                          isSelected: isSelected,
                          onTap: () => provider.selectCandy(row, col),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Tap candies to select, then tap adjacent candy to swap.\nCreate lines of 3+ matching candies to score points!",
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (provider.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      "Game Over! Final Score: ${provider.score}",
                      style: GoogleFonts.outfit(
                        color: Colors.pinkAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandyCell extends StatelessWidget {
  final Candy? candy;
  final bool isSelected;
  final VoidCallback onTap;

  const _CandyCell({
    required this.candy,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppTheme.primary, width: 3) : null,
        ),
        child: candy != null ? Center(
          child: Text(
            candy!.type,
            style: const TextStyle(fontSize: 24),
          ),
        ) : null,
      ),
    );
  }
}