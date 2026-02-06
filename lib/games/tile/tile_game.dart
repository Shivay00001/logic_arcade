import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class TileGame extends StatelessWidget {
  const TileGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TileGameProvider(),
      child: const _TileGameContent(),
    );
  }
}

class TileGameProvider extends ChangeNotifier {
  List<List<int>> _grid = [];
  int _score = 0;
  int _bestScore = 0;
  bool _gameOver = false;
  
  int get score => _score;
  int get bestScore => _bestScore;
  List<List<int>> get grid => _grid;
  bool get gameOver => _gameOver;

  TileGameProvider() {
    _startNewGame();
  }

  void _startNewGame() {
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _score = 0;
    _gameOver = false;
    _spawnTile();
    _spawnTile();
    notifyListeners();
  }
  
  void restart() => _startNewGame();

  void _spawnTile() {
    List<Point<int>> emptySpots = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) emptySpots.add(Point(r, c));
      }
    }
    
    if (emptySpots.isNotEmpty) {
      final randomPoint = emptySpots[Random().nextInt(emptySpots.length)];
      _grid[randomPoint.x][randomPoint.y] = Random().nextDouble() < 0.9 ? 2 : 4;
    }
  }

  // Input Handling
  void handleSwipe(SwipeDirection direction) {
    if (_gameOver) return;
    
    bool moved = false;
    
    if (direction == SwipeDirection.left) {
      moved = _moveLeft();
    } else if (direction == SwipeDirection.right) {
      moved = _moveRight();
    } else if (direction == SwipeDirection.up) {
      moved = _moveUp();
    } else if (direction == SwipeDirection.down) {
      moved = _moveDown();
    }
    
    if (moved) {
      _spawnTile();
      if (_checkGameOver()) {
        _gameOver = true;
      }
      notifyListeners();
    }
  }
  
  bool _moveLeft() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> newRow = _mergeRow(_grid[r]);
      if (!_listsEqual(newRow, _grid[r])) {
        _grid[r] = newRow;
        moved = true;
      }
    }
    return moved;
  }
  
  bool _moveRight() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> reversed = _grid[r].reversed.toList();
      List<int> newRow = _mergeRow(reversed);
      List<int> finalRow = newRow.reversed.toList();
      if (!_listsEqual(finalRow, _grid[r])) {
        _grid[r] = finalRow;
        moved = true;
      }
    }
    return moved;
  }

  bool _moveUp() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [_grid[0][c], _grid[1][c], _grid[2][c], _grid[3][c]];
      List<int> newCol = _mergeRow(col);
      for (int r = 0; r < 4; r++) {
        if (_grid[r][c] != newCol[r]) {
          _grid[r][c] = newCol[r];
          moved = true;
        }
      }
    }
    return moved;
  }
  
  bool _moveDown() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [_grid[3][c], _grid[2][c], _grid[1][c], _grid[0][c]];
      List<int> newCol = _mergeRow(col);
      // newCol is Bottom->Top now
      // Re-assign correctly
      // r=3 <- newCol[0]
      // r=2 <- newCol[1]
      // r=1 <- newCol[2]
      // r=0 <- newCol[3]
      for (int i = 0; i < 4; i++) {
        int r = 3 - i;
        if (_grid[r][c] != newCol[i]) {
          _grid[r][c] = newCol[i];
          moved = true;
        }
      }
    }
    return moved;
  }

  List<int> _mergeRow(List<int> row) {
    // 1. Remove zeros
    List<int> nonZero = row.where((v) => v != 0).toList();
    
    // 2. Merge adjacent
    for (int i = 0; i < nonZero.length - 1; i++) {
      if (nonZero[i] == nonZero[i+1]) {
        nonZero[i] *= 2;
        _score += nonZero[i];
        if (_score > _bestScore) _bestScore = _score;
        nonZero.removeAt(i+1);
      }
    }
    
    // 3. Pad with zeros
    while (nonZero.length < 4) {
      nonZero.add(0);
    }
    return nonZero;
  }

  bool _listsEqual(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
    return true;
  }
  
  bool _checkGameOver() {
    // Check for zeros
    for(var r in _grid) if(r.contains(0)) return false;
    
    // Check for mergeable neighbors
    for (int r=0; r<4; r++) {
      for (int c=0; c<4; c++) {
        int val = _grid[r][c];
        // Check right
        if (c < 3 && _grid[r][c+1] == val) return false;
        // Check down
        if (r < 3 && _grid[r+1][c] == val) return false;
      }
    }
    return true;
  }
}

enum SwipeDirection { up, down, left, right }

class _TileGameContent extends StatelessWidget {
  const _TileGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TileGameProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("2048 Logic", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.restart,
          ),
        ],
      ),
      body: Column(
        children: [
          // Score Board
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreCard(label: "SCORE", score: provider.score),
                _ScoreCard(label: "BEST", score: provider.bestScore),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    provider.handleSwipe(SwipeDirection.up);
                  } else if (details.primaryVelocity! > 0) {
                    provider.handleSwipe(SwipeDirection.down);
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    provider.handleSwipe(SwipeDirection.left);
                  } else if (details.primaryVelocity! > 0) {
                    provider.handleSwipe(SwipeDirection.right);
                  }
                },
                child: KeyboardListener(
                  focusNode: FocusNode()..requestFocus(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                       if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                         provider.handleSwipe(SwipeDirection.up);
                       } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                         provider.handleSwipe(SwipeDirection.down);
                       } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                         provider.handleSwipe(SwipeDirection.left);
                       } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                         provider.handleSwipe(SwipeDirection.right);
                       }
                    }
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 16,
                        itemBuilder: (ctx, index) {
                          int r = index ~/ 4;
                          int c = index % 4;
                          int value = provider.grid[r][c];
                          return _TileWidget(value: value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          if (provider.gameOver)
             Padding(
               padding: const EdgeInsets.only(bottom: 24),
               child: Text("GAME OVER", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
             ),

          const SizedBox(height: 50), // Ad space buffer
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;
  const _ScoreCard({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          Text("$score", style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TileWidget extends StatelessWidget {
  final int value;
  const _TileWidget({required this.value});

  Color _getTileColor(int val) {
    switch (val) {
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFF3C3A32);
    }
  }

  Color _getTextColor(int val) {
    if (val <= 4) return const Color(0xFF776E65);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _getTileColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$value",
        style: GoogleFonts.outfit(
          fontSize: value > 512 ? 24 : 32,
          fontWeight: FontWeight.bold,
          color: _getTextColor(value),
        ),
      ),
    ); // No animation for now to keep it simple, but could add .animate().scale()
  }
}
