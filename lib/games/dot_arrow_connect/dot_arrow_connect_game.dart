import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// DOT ARROW CONNECT LOGIC
// -----------------------------------------------------------------------------

class DotArrowProvider extends ChangeNotifier {
  static const int gridSize = 6;
  static const int maxConnections = 4;

  late List<List<Dot?>> _grid;
  late List<List<bool>> _connections;
  int _score = 0;
  bool _gameOver = false;
  int _movesLeft = 20;
  Dot? _selectedDot;
  List<Point<int>> _currentPath = [];

  List<List<Dot?>> get grid => _grid;
  List<List<bool>> get connections => _connections;
  int get score => _score;
  bool get gameOver => _gameOver;
  int get movesLeft => _movesLeft;
  Dot? get selectedDot => _selectedDot;
  List<Point<int>> get currentPath => _currentPath;

  DotArrowProvider() {
    _initializeGame();
  }

  void _initializeGame() {
    _grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
    _connections = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
    _score = 0;
    _gameOver = false;
    _movesLeft = 20;
    _selectedDot = null;
    _currentPath = [];
    _generateDots();
  }

  void _generateDots() {
    Random random = Random();
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (random.nextDouble() < 0.6) { // 60% chance of having a dot
          _grid[row][col] = Dot(Point(row, col), colors[random.nextInt(colors.length)]);
        }
      }
    }
  }

  void selectDot(int row, int col) {
    if (_gameOver) return;

    Dot? dot = _grid[row][col];
    if (dot == null) return;

    if (_selectedDot == null) {
      // Select first dot
      _selectedDot = dot;
      _currentPath = [dot.position];
    } else if (_selectedDot == dot) {
      // Deselect if same dot clicked
      _selectedDot = null;
      _currentPath = [];
    } else if (_canConnect(_selectedDot!.position, Point(row, col))) {
      // Add to path
      _currentPath.add(Point(row, col));

      // Check if path is complete (4+ dots)
      if (_currentPath.length >= maxConnections) {
        _completeConnection();
      }
    } else {
      // Start new path
      _selectedDot = dot;
      _currentPath = [dot.position];
    }

    notifyListeners();
  }

  bool _canConnect(Point<int> from, Point<int> to) {
    // Must be adjacent (up, down, left, right)
    int dx = (to.x - from.x).abs();
    int dy = (to.y - from.y).abs();

    if ((dx == 1 && dy == 0) || (dx == 0 && dy == 1)) {
      // Check if target has a dot and same color
      Dot? targetDot = _grid[to.x][to.y];
      return targetDot != null && targetDot.color == _selectedDot!.color && !_currentPath.contains(to);
    }

    return false;
  }

  void _completeConnection() {
    if (_currentPath.length < maxConnections) return;

    // Remove connected dots
    for (Point<int> pos in _currentPath) {
      _grid[pos.x][pos.y] = null;
    }

    // Add score
    _score += _currentPath.length * 10;

    // Drop colors from above
    _dropColors();

    // Generate new dots at top
    _generateNewDots();

    // Reset selection
    _selectedDot = null;
    _currentPath = [];
    _movesLeft--;

    // Check game over
    if (_movesLeft <= 0) {
      _gameOver = true;
    }

    notifyListeners();
  }

  void _dropColors() {
    for (int col = 0; col < gridSize; col++) {
      List<Dot?> column = [];
      for (int row = gridSize - 1; row >= 0; row--) {
        if (_grid[row][col] != null) {
          column.add(_grid[row][col]);
        }
      }

      // Clear column
      for (int row = 0; row < gridSize; row++) {
        _grid[row][col] = null;
      }

      // Place dots at bottom
      for (int i = 0; i < column.length; i++) {
        _grid[gridSize - 1 - i][col] = column[i];
      }
    }
  }

  void _generateNewDots() {
    Random random = Random();
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];

    for (int col = 0; col < gridSize; col++) {
      if (_grid[0][col] == null) {
        _grid[0][col] = Dot(Point(0, col), colors[random.nextInt(colors.length)]);
      }
    }
  }

  void restart() {
    _initializeGame();
    notifyListeners();
  }
}

class Dot {
  Point<int> position;
  Color color;

  Dot(this.position, this.color);
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class DotArrowConnectGame extends StatelessWidget {
  const DotArrowConnectGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DotArrowProvider(),
      child: const _DotArrowGameContent(),
    );
  }
}

class _DotArrowGameContent extends StatelessWidget {
  const _DotArrowGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DotArrowProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Dot Arrow Connect", style: GoogleFonts.outfit()),
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
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: 36,
                      itemBuilder: (ctx, index) {
                        int row = index ~/ 6;
                        int col = index % 6;
                        Dot? dot = provider.grid[row][col];
                        bool isInPath = provider.currentPath.contains(Point(row, col));
                        return _DotCell(
                          dot: dot,
                          isInPath: isInPath,
                          onTap: () => provider.selectDot(row, col),
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
                  "Connect 4+ dots of the same color by tapping adjacent dots.\nConnected dots will disappear and colors will drop!",
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (provider.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      "Game Over! Final Score: ${provider.score}",
                      style: GoogleFonts.outfit(
                        color: Colors.greenAccent,
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

class _DotCell extends StatelessWidget {
  final Dot? dot;
  final bool isInPath;
  final VoidCallback onTap;

  const _DotCell({
    required this.dot,
    required this.isInPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isInPath ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: dot != null ? Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: dot!.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: dot!.color.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ) : null,
      ),
    );
  }
}