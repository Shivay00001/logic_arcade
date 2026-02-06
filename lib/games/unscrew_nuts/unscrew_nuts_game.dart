import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// UNSCREW NUTS LOGIC
// -----------------------------------------------------------------------------

class Nut {
  int size;
  Color color;
  bool isScrewed = false;

  Nut(this.size, this.color);

  String get symbol => isScrewed ? '🔩' : '🔧';
}

class Bolt {
  int size;
  Color color;
  bool isPlaced = false;

  Bolt(this.size, this.color);

  String get symbol => isPlaced ? '🔩' : '⚙️';
}

class UnscrewNutsProvider extends ChangeNotifier {
  static const int boardSize = 5;

  late List<List<Nut?>> _board;
  late List<Bolt> _availableBolts;
  int _score = 0;
  int _movesLeft = 20;
  bool _gameOver = false;
  bool _levelComplete = false;
  Bolt? _selectedBolt;

  List<List<Nut?>> get board => _board;
  List<Bolt> get availableBolts => _availableBolts;
  int get score => _score;
  int get movesLeft => _movesLeft;
  bool get gameOver => _gameOver;
  bool get levelComplete => _levelComplete;
  Bolt? get selectedBolt => _selectedBolt;

  UnscrewNutsProvider() {
    _initializeGame();
  }

  void _initializeGame() {
    _board = List.generate(boardSize, (_) => List.generate(boardSize, (_) => null));
    _availableBolts = [];
    _score = 0;
    _movesLeft = 20;
    _gameOver = false;
    _levelComplete = false;
    _selectedBolt = null;

    // Create nuts on board
    Random random = Random();
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (random.nextDouble() < 0.7) { // 70% chance of having a nut
          int size = random.nextInt(3) + 1; // Size 1-3
          Color color = colors[random.nextInt(colors.length)];
          _board[row][col] = Nut(size, color);
          _board[row][col]!.isScrewed = true;
        }
      }
    }

    // Create bolts to place
    for (int i = 0; i < 8; i++) {
      int size = random.nextInt(3) + 1;
      Color color = colors[random.nextInt(colors.length)];
      _availableBolts.add(Bolt(size, color));
    }
  }

  void selectBolt(Bolt bolt) {
    if (_gameOver || _levelComplete) return;
    _selectedBolt = bolt;
    notifyListeners();
  }

  void placeBolt(int row, int col) {
    if (_selectedBolt == null || _board[row][col] == null) return;
    if (!_selectedBolt!.isPlaced) return;

    Nut nut = _board[row][col]!;
    if (nut.size == _selectedBolt!.size && nut.color == _selectedBolt!.color) {
      // Correct match!
      nut.isScrewed = false;
      _selectedBolt!.isPlaced = false;
      _score += 50;
      _availableBolts.remove(_selectedBolt);
      _selectedBolt = null;

      _checkLevelComplete();
    } else {
      // Wrong match
      _movesLeft--;
      if (_movesLeft <= 0) {
        _gameOver = true;
      }
    }

    notifyListeners();
  }

  void _checkLevelComplete() {
    bool allUnscrewed = true;
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (_board[row][col] != null && _board[row][col]!.isScrewed) {
          allUnscrewed = false;
          break;
        }
      }
      if (!allUnscrewed) break;
    }

    if (allUnscrewed) {
      _levelComplete = true;
      _score += 200; // Bonus for completing level
    }
  }

  void restart() {
    _initializeGame();
    notifyListeners();
  }

  bool canPlaceBolt(int row, int col) {
    if (_selectedBolt == null || _board[row][col] == null) return false;
    return !_selectedBolt!.isPlaced;
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class UnscrewNutsGame extends StatelessWidget {
  const UnscrewNutsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UnscrewNutsProvider(),
      child: const _UnscrewNutsGameContent(),
    );
  }
}

class _UnscrewNutsGameContent extends StatelessWidget {
  const _UnscrewNutsGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UnscrewNutsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Unscrew Nuts", style: GoogleFonts.outfit()),
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
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: 25,
                      itemBuilder: (ctx, index) {
                        int row = index ~/ 5;
                        int col = index % 5;
                        Nut? nut = provider.board[row][col];
                        bool canPlace = provider.canPlaceBolt(row, col);
                        return _NutCell(
                          nut: nut,
                          canPlace: canPlace,
                          onTap: () => provider.placeBolt(row, col),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Available bolts
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.availableBolts.length,
              itemBuilder: (ctx, index) {
                Bolt bolt = provider.availableBolts[index];
                bool isSelected = provider.selectedBolt == bolt;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => provider.selectBolt(bolt),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.grey[700],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            bolt.symbol,
                            style: const TextStyle(fontSize: 24),
                          ),
                          Container(
                            width: 20,
                            height: 8,
                            decoration: BoxDecoration(
                              color: bolt.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Select a bolt, then tap the matching nut (same size & color) to unscrew it.\nUnscrew all nuts to win!",
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (provider.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      "Game Over! Final Score: ${provider.score}",
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (provider.levelComplete)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      "Level Complete! Score: ${provider.score}",
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

class _NutCell extends StatelessWidget {
  final Nut? nut;
  final bool canPlace;
  final VoidCallback onTap;

  const _NutCell({
    required this.nut,
    required this.canPlace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: nut != null ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: canPlace ? AppTheme.secondary.withOpacity(0.3) : Colors.grey[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: nut != null ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nut!.symbol,
              style: const TextStyle(fontSize: 20),
            ),
            Container(
              width: 16,
              height: 6,
              decoration: BoxDecoration(
                color: nut!.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ) : null,
      ),
    );
  }
}