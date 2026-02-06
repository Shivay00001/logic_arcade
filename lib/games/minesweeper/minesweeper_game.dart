import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// MINESWEEPER LOGIC
// -----------------------------------------------------------------------------

enum CellState { hidden, revealed, flagged }

class MinesweeperCell {
  bool hasMine = false;
  int adjacentMines = 0;
  CellState state = CellState.hidden;

  MinesweeperCell();
}

class MinesweeperProvider extends ChangeNotifier {
  static const int boardSize = 9;
  static const int mineCount = 10;

  late List<List<MinesweeperCell>> _board;
  bool _gameOver = false;
  bool _gameWon = false;
  int _flagCount = 0;
  int _revealedCount = 0;
  bool _firstClick = true;
  int _timeElapsed = 0;
  bool _timerRunning = false;

  List<List<MinesweeperCell>> get board => _board;
  bool get gameOver => _gameOver;
  bool get gameWon => _gameWon;
  int get flagCount => _flagCount;
  int get timeElapsed => _timeElapsed;
  int get remainingMines => mineCount - _flagCount;

  MinesweeperProvider() {
    _initializeBoard();
  }

  void _initializeBoard() {
    _board = List.generate(boardSize, (_) =>
      List.generate(boardSize, (_) => MinesweeperCell())
    );
    _gameOver = false;
    _gameWon = false;
    _flagCount = 0;
    _revealedCount = 0;
    _firstClick = true;
    _timeElapsed = 0;
    _timerRunning = false;
  }

  void _placeMines(int excludeRow, int excludeCol) {
    Random random = Random();
    int minesPlaced = 0;

    while (minesPlaced < mineCount) {
      int row = random.nextInt(boardSize);
      int col = random.nextInt(boardSize);

      // Don't place mine on first click or adjacent cells
      if ((row - excludeRow).abs() <= 1 && (col - excludeCol).abs() <= 1) continue;
      if (_board[row][col].hasMine) continue;

      _board[row][col].hasMine = true;
      minesPlaced++;
    }

    _calculateAdjacentMines();
  }

  void _calculateAdjacentMines() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (!_board[row][col].hasMine) {
          int count = 0;
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              int nr = row + dr;
              int nc = col + dc;
              if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize &&
                  _board[nr][nc].hasMine) {
                count++;
              }
            }
          }
          _board[row][col].adjacentMines = count;
        }
      }
    }
  }

  void revealCell(int row, int col) {
    if (_gameOver || _board[row][col].state != CellState.hidden) return;

    if (_firstClick) {
      _placeMines(row, col);
      _firstClick = false;
      _startTimer();
    }

    _board[row][col].state = CellState.revealed;
    _revealedCount++;

    if (_board[row][col].hasMine) {
      _gameOver = true;
      _timerRunning = false;
      _revealAllMines();
      notifyListeners();
      return;
    }

    // Auto-reveal empty areas
    if (_board[row][col].adjacentMines == 0) {
      _floodReveal(row, col);
    }

    _checkWinCondition();
    notifyListeners();
  }

  void _floodReveal(int row, int col) {
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        int nr = row + dr;
        int nc = col + dc;
        if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize &&
            _board[nr][nc].state == CellState.hidden) {
          _board[nr][nc].state = CellState.revealed;
          _revealedCount++;
          if (_board[nr][nc].adjacentMines == 0) {
            _floodReveal(nr, nc);
          }
        }
      }
    }
  }

  void toggleFlag(int row, int col) {
    if (_gameOver || _board[row][col].state == CellState.revealed) return;

    if (_board[row][col].state == CellState.flagged) {
      _board[row][col].state = CellState.hidden;
      _flagCount--;
    } else {
      _board[row][col].state = CellState.flagged;
      _flagCount++;
    }
    notifyListeners();
  }

  void _revealAllMines() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (_board[row][col].hasMine && _board[row][col].state != CellState.flagged) {
          _board[row][col].state = CellState.revealed;
        }
      }
    }
  }

  void _checkWinCondition() {
    if (_revealedCount == boardSize * boardSize - mineCount) {
      _gameWon = true;
      _gameOver = true;
      _timerRunning = false;
    }
  }

  void _startTimer() {
    _timerRunning = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_timerRunning) {
        _timeElapsed++;
        notifyListeners();
      }
      return _timerRunning;
    });
  }

  void restart() {
    _initializeBoard();
    notifyListeners();
  }

  String getGameStatus() {
    if (_gameWon) return "You Win! 🎉";
    if (_gameOver) return "Game Over 💥";
    return "Mines: ${remainingMines}";
  }

  Color getCellColor(MinesweeperCell cell) {
    if (cell.state == CellState.flagged) return Colors.red;
    if (cell.state == CellState.revealed) {
      if (cell.hasMine) return Colors.red[900]!;
      return Colors.grey[300]!;
    }
    return Colors.grey[500]!;
  }

  String getCellText(MinesweeperCell cell) {
    if (cell.state == CellState.flagged) return "🚩";
    if (cell.state == CellState.revealed) {
      if (cell.hasMine) return "💣";
      if (cell.adjacentMines > 0) return cell.adjacentMines.toString();
    }
    return "";
  }

  Color getTextColor(int number) {
    List<Color> colors = [
      Colors.blue, Colors.green, Colors.red, Colors.purple,
      Colors.brown, Colors.teal, Colors.black, Colors.grey
    ];
    return colors[number - 1];
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class MinesweeperGame extends StatelessWidget {
  const MinesweeperGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MinesweeperProvider(),
      child: const _MinesweeperGameContent(),
    );
  }
}

class _MinesweeperGameContent extends StatelessWidget {
  const _MinesweeperGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MinesweeperProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Minesweeper", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "${provider.getGameStatus()} | Time: ${provider.timeElapsed}s",
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
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 9,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: 81,
                      itemBuilder: (ctx, index) {
                        int row = index ~/ 9;
                        int col = index % 9;
                        MinesweeperCell cell = provider.board[row][col];
                        return _MineCell(
                          cell: cell,
                          color: provider.getCellColor(cell),
                          text: provider.getCellText(cell),
                          textColor: cell.adjacentMines > 0 ? provider.getTextColor(cell.adjacentMines) : Colors.black,
                          onTap: () => provider.revealCell(row, col),
                          onLongPress: () => provider.toggleFlag(row, col),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Tap to reveal cells, long press to flag mines.\nReveal all safe cells to win!",
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MineCell extends StatelessWidget {
  final MinesweeperCell cell;
  final Color color;
  final String text;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MineCell({
    required this.cell,
    required this.color,
    required this.text,
    required this.textColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black26, width: 1),
          boxShadow: cell.state == CellState.hidden ? [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}