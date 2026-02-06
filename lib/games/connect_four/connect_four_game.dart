import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// CONNECT FOUR LOGIC
// -----------------------------------------------------------------------------

enum ConnectFourColor { empty, red, yellow }

class ConnectFourProvider extends ChangeNotifier {
  static const int columns = 7;
  static const int rows = 6;

  late List<List<ConnectFourColor>> _board;
  ConnectFourColor _currentPlayer = ConnectFourColor.red;
  bool _gameOver = false;
  ConnectFourColor _winner = ConnectFourColor.empty;
  bool _aiThinking = false;
  List<int>? _winningCells;

  List<List<ConnectFourColor>> get board => _board;
  ConnectFourColor get currentPlayer => _currentPlayer;
  bool get gameOver => _gameOver;
  ConnectFourColor get winner => _winner;
  bool get aiThinking => _aiThinking;
  List<int>? get winningCells => _winningCells;

  ConnectFourProvider() {
    _initializeBoard();
  }

  void _initializeBoard() {
    _board = List.generate(rows, (_) =>
      List.filled(columns, ConnectFourColor.empty)
    );
    _currentPlayer = ConnectFourColor.red;
    _gameOver = false;
    _winner = ConnectFourColor.empty;
    _aiThinking = false;
    _winningCells = null;
  }

  bool canDropInColumn(int col) {
    return _board[0][col] == ConnectFourColor.empty;
  }

  void dropPiece(int col) {
    if (_gameOver || _aiThinking || !canDropInColumn(col)) return;

    // Find the lowest empty row in this column
    for (int row = rows - 1; row >= 0; row--) {
      if (_board[row][col] == ConnectFourColor.empty) {
        _board[row][col] = _currentPlayer;
        _checkWin(row, col);
        _switchPlayer();

        if (!_gameOver && _currentPlayer == ConnectFourColor.yellow) {
          _makeAIMove();
        }
        notifyListeners();
        return;
      }
    }
  }

  void _switchPlayer() {
    if (!_gameOver) {
      _currentPlayer = _currentPlayer == ConnectFourColor.red
          ? ConnectFourColor.yellow
          : ConnectFourColor.red;
    }
  }

  void _checkWin(int lastRow, int lastCol) {
    ConnectFourColor player = _board[lastRow][lastCol];

    // Check all four directions
    List<List<int>> directions = [
      [0, 1],   // horizontal
      [1, 0],   // vertical
      [1, 1],   // diagonal \
      [1, -1],  // diagonal /
    ];

    for (List<int> dir in directions) {
      List<List<int>> line = _getLine(lastRow, lastCol, dir[0], dir[1]);
      if (line.length >= 4) {
        // Check if all pieces in this line are the same color
        bool allSame = true;
        for (List<int> cell in line) {
          if (_board[cell[0]][cell[1]] != player) {
            allSame = false;
            break;
          }
        }
        if (allSame) {
          _gameOver = true;
          _winner = player;
          _winningCells = line.expand((cell) => cell).toList();
          return;
        }
      }
    }

    // Check for draw
    bool boardFull = true;
    for (int col = 0; col < columns; col++) {
      if (_board[0][col] == ConnectFourColor.empty) {
        boardFull = false;
        break;
      }
    }
    if (boardFull) {
      _gameOver = true;
      _winner = ConnectFourColor.empty; // Draw
    }
  }

  List<List<int>> _getLine(int startRow, int startCol, int dRow, int dCol) {
    List<List<int>> line = [];

    // Go backwards from start
    int row = startRow - dRow;
    int col = startCol - dCol;
    while (row >= 0 && row < rows && col >= 0 && col < columns) {
      line.insert(0, [row, col]);
      row -= dRow;
      col -= dCol;
    }

    // Add start position
    line.add([startRow, startCol]);

    // Go forwards from start
    row = startRow + dRow;
    col = startCol + dCol;
    while (row >= 0 && row < rows && col >= 0 && col < columns) {
      line.add([row, col]);
      row += dRow;
      col += dCol;
    }

    return line;
  }

  void _makeAIMove() {
    if (_gameOver) return;

    _aiThinking = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      // Simple AI: try to win, block player, or play randomly
      int bestCol = _getBestMove();
      dropPiece(bestCol);
      _aiThinking = false;
      notifyListeners();
    });
  }

  int _getBestMove() {
    // First, check if AI can win immediately
    for (int col = 0; col < columns; col++) {
      if (canDropInColumn(col)) {
        int row = _getDropRow(col);
        _board[row][col] = ConnectFourColor.yellow;
        if (_wouldWin(row, col, ConnectFourColor.yellow)) {
          _board[row][col] = ConnectFourColor.empty;
          return col;
        }
        _board[row][col] = ConnectFourColor.empty;
      }
    }

    // Second, check if AI needs to block player
    for (int col = 0; col < columns; col++) {
      if (canDropInColumn(col)) {
        int row = _getDropRow(col);
        _board[row][col] = ConnectFourColor.red;
        if (_wouldWin(row, col, ConnectFourColor.red)) {
          _board[row][col] = ConnectFourColor.empty;
          return col;
        }
        _board[row][col] = ConnectFourColor.empty;
      }
    }

    // Otherwise, choose center columns first, then random
    List<int> preferredCols = [3, 2, 4, 1, 5, 0, 6];
    for (int col in preferredCols) {
      if (canDropInColumn(col)) {
        return col;
      }
    }

    // Fallback
    return Random().nextInt(columns);
  }

  int _getDropRow(int col) {
    for (int row = rows - 1; row >= 0; row--) {
      if (_board[row][col] == ConnectFourColor.empty) {
        return row;
      }
    }
    return -1;
  }

  bool _wouldWin(int row, int col, ConnectFourColor player) {
    // Simplified win check for AI
    int count = 1;

    // Horizontal
    for (int c = col - 1; c >= 0 && _board[row][c] == player; c--) count++;
    for (int c = col + 1; c < columns && _board[row][c] == player; c++) count++;
    if (count >= 4) return true;

    // Vertical
    count = 1;
    for (int r = row - 1; r >= 0 && _board[r][col] == player; r--) count++;
    for (int r = row + 1; r < rows && _board[r][col] == player; r++) count++;
    if (count >= 4) return true;

    return false; // Skip diagonal checks for simplicity
  }

  void restart() {
    _initializeBoard();
    notifyListeners();
  }

  Color getPieceColor(ConnectFourColor color) {
    switch (color) {
      case ConnectFourColor.red: return Colors.red;
      case ConnectFourColor.yellow: return Colors.yellow;
      default: return Colors.white;
    }
  }

  String getGameStatus() {
    if (_gameOver) {
      if (_winner == ConnectFourColor.empty) return "It's a Draw!";
      return "${_winner == ConnectFourColor.red ? "Red" : "Yellow"} Wins!";
    }
    return "${_currentPlayer == ConnectFourColor.red ? "Red" : "Yellow"} to move";
  }

  bool isWinningCell(int row, int col) {
    if (_winningCells == null) return false;
    for (int i = 0; i < _winningCells!.length; i += 2) {
      if (_winningCells![i] == row && _winningCells![i + 1] == col) {
        return true;
      }
    }
    return false;
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class ConnectFourGame extends StatelessWidget {
  const ConnectFourGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConnectFourProvider(),
      child: const _ConnectFourGameContent(),
    );
  }
}

class _ConnectFourGameContent extends StatelessWidget {
  const _ConnectFourGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectFourProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Connect Four", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                provider.getGameStatus(),
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
          // Column selectors (top)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (col) {
                bool canDrop = provider.canDropInColumn(col);
                return GestureDetector(
                  onTap: canDrop ? () => provider.dropPiece(col) : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: canDrop ? provider.getPieceColor(provider.currentPlayer) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
          ),

          // Game board
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 7/6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 42,
                      itemBuilder: (ctx, index) {
                        int row = index ~/ 7;
                        int col = index % 7;
                        ConnectFourColor pieceColor = provider.board[row][col];
                        bool isWinning = provider.isWinningCell(row, col);
                        return _ConnectFourCell(
                          color: provider.getPieceColor(pieceColor),
                          isWinning: isWinning,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Status and controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (provider.aiThinking)
                  const CircularProgressIndicator(),
                if (provider.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      provider.getGameStatus(),
                      style: GoogleFonts.outfit(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  "Tap the circles above columns to drop pieces.\nGet four in a row to win!\nYou play as Red, AI plays as Yellow.",
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectFourCell extends StatelessWidget {
  final Color color;
  final bool isWinning;

  const _ConnectFourCell({
    required this.color,
    required this.isWinning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isWinning ? Colors.white : Colors.black,
          width: isWinning ? 3 : 1,
        ),
        boxShadow: isWinning ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
    );
  }
}