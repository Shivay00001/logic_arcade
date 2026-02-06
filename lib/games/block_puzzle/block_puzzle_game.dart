import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

// -----------------------------------------------------------------------------
// BLOCK PUZZLE LOGIC
// -----------------------------------------------------------------------------

class Block {
  List<List<int>> shape;
  Color color;
  int x, y;

  Block(this.shape, this.color, this.x, this.y);

  Block copy() => Block(List.from(shape.map((row) => List.from(row))), color, x, y);

  int get width => shape[0].length;
  int get height => shape.length;
}

class BlockPuzzleProvider extends ChangeNotifier {
  static const int boardWidth = 10;
  static const int boardHeight = 20;
  static const int previewSize = 4;

  late List<List<Color?>> _board;
  Block? _currentBlock;
  Block? _nextBlock;
  int _score = 0;
  bool _gameOver = false;
  bool _paused = false;
  Timer? _gameTimer;
  int _speed = 500; // milliseconds

  List<List<Color?>> get board => _board;
  Block? get currentBlock => _currentBlock;
  Block? get nextBlock => _nextBlock;
  int get score => _score;
  bool get gameOver => _gameOver;
  bool get paused => _paused;

  BlockPuzzleProvider() {
    _initializeGame();
  }

  void _initializeGame() {
    _board = List.generate(boardHeight, (_) => List.filled(boardWidth, null));
    _score = 0;
    _gameOver = false;
    _paused = false;
    _speed = 500;
    _spawnNewBlock();
    _startGameLoop();
  }

  void _spawnNewBlock() {
    _currentBlock = _nextBlock ?? _generateRandomBlock();
    _nextBlock = _generateRandomBlock();

    // Position at top center
    _currentBlock!.x = (boardWidth - _currentBlock!.width) ~/ 2;
    _currentBlock!.y = 0;

    if (_checkCollision(_currentBlock!)) {
      _gameOver = true;
      _gameTimer?.cancel();
    }

    notifyListeners();
  }

  Block _generateRandomBlock() {
    List<List<List<int>>> shapes = [
      // I
      [[1, 1, 1, 1]],
      // O
      [[1, 1], [1, 1]],
      // T
      [[0, 1, 0], [1, 1, 1]],
      // S
      [[0, 1, 1], [1, 1, 0]],
      // Z
      [[1, 1, 0], [0, 1, 1]],
      // J
      [[1, 0, 0], [1, 1, 1]],
      // L
      [[0, 0, 1], [1, 1, 1]],
    ];

    List<Color> colors = [
      Colors.cyan, Colors.yellow, Colors.purple, Colors.green,
      Colors.red, Colors.blue, Colors.orange
    ];

    int index = Random().nextInt(shapes.length);
    return Block(shapes[index], colors[index], 0, 0);
  }

  bool _checkCollision(Block block) {
    for (int y = 0; y < block.height; y++) {
      for (int x = 0; x < block.width; x++) {
        if (block.shape[y][x] == 1) {
          int boardX = block.x + x;
          int boardY = block.y + y;

          if (boardX < 0 || boardX >= boardWidth || boardY >= boardHeight) {
            return true;
          }

          if (boardY >= 0 && _board[boardY][boardX] != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _placeBlock() {
    if (_currentBlock == null) return;

    // Place block on board
    for (int y = 0; y < _currentBlock!.height; y++) {
      for (int x = 0; x < _currentBlock!.width; x++) {
        if (_currentBlock!.shape[y][x] == 1) {
          int boardX = _currentBlock!.x + x;
          int boardY = _currentBlock!.y + y;
          if (boardY >= 0) {
            _board[boardY][boardX] = _currentBlock!.color;
          }
        }
      }
    }

    // Check for completed lines
    _clearLines();

    // Spawn next block
    _spawnNewBlock();
  }

  void _clearLines() {
    int linesCleared = 0;

    for (int y = boardHeight - 1; y >= 0; y--) {
      bool lineFull = true;
      for (int x = 0; x < boardWidth; x++) {
        if (_board[y][x] == null) {
          lineFull = false;
          break;
        }
      }

      if (lineFull) {
        // Clear line
        for (int yy = y; yy > 0; yy--) {
          _board[yy] = List.from(_board[yy - 1]);
        }
        _board[0] = List.filled(boardWidth, null);
        linesCleared++;
        y++; // Check same line again
      }
    }

    if (linesCleared > 0) {
      _score += linesCleared * linesCleared * 100;
      // Increase speed
      if (_speed > 100) {
        _speed -= 10;
        _gameTimer?.cancel();
        _startGameLoop();
      }
    }
  }

  void moveLeft() {
    if (_currentBlock == null || _gameOver || _paused) return;

    _currentBlock!.x--;
    if (_checkCollision(_currentBlock!)) {
      _currentBlock!.x++;
    } else {
      notifyListeners();
    }
  }

  void moveRight() {
    if (_currentBlock == null || _gameOver || _paused) return;

    _currentBlock!.x++;
    if (_checkCollision(_currentBlock!)) {
      _currentBlock!.x--;
    } else {
      notifyListeners();
    }
  }

  void rotate() {
    if (_currentBlock == null || _gameOver || _paused) return;

    // Simple rotation (transpose + reverse rows)
    List<List<int>> rotated = List.generate(
      _currentBlock!.shape[0].length,
      (i) => List.generate(_currentBlock!.shape.length, (j) => 0)
    );

    for (int y = 0; y < _currentBlock!.shape.length; y++) {
      for (int x = 0; x < _currentBlock!.shape[0].length; x++) {
        rotated[x][_currentBlock!.shape.length - 1 - y] = _currentBlock!.shape[y][x];
      }
    }

    Block testBlock = Block(rotated, _currentBlock!.color, _currentBlock!.x, _currentBlock!.y);

    if (!_checkCollision(testBlock)) {
      _currentBlock!.shape = rotated;
      notifyListeners();
    }
  }

  void drop() {
    if (_currentBlock == null || _gameOver || _paused) return;

    _currentBlock!.y++;
    if (_checkCollision(_currentBlock!)) {
      _currentBlock!.y--;
      _placeBlock();
    }
    notifyListeners();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(Duration(milliseconds: _speed), (timer) {
      if (!_paused && !_gameOver) {
        drop();
      }
    });
  }

  void togglePause() {
    _paused = !_paused;
    notifyListeners();
  }

  void restart() {
    _gameTimer?.cancel();
    _initializeGame();
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class BlockPuzzleGame extends StatelessWidget {
  const BlockPuzzleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BlockPuzzleProvider(),
      child: const _BlockPuzzleGameContent(),
    );
  }
}

class _BlockPuzzleGameContent extends StatelessWidget {
  const _BlockPuzzleGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlockPuzzleProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Block Puzzle", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "Score: ${provider.score}",
                style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.text),
              ),
            ),
          ),
          IconButton(
            icon: Icon(provider.paused ? Icons.play_arrow : Icons.pause),
            onPressed: provider.gameOver ? null : provider.togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.restart,
          ),
        ],
      ),
      body: Row(
        children: [
          // Game board
          Expanded(
            flex: 3,
            child: Center(
              child: AspectRatio(
                aspectRatio: BlockPuzzleProvider.boardWidth / BlockPuzzleProvider.boardHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: BlockPuzzleProvider.boardWidth,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                    ),
                    itemCount: BlockPuzzleProvider.boardWidth * BlockPuzzleProvider.boardHeight,
                    itemBuilder: (ctx, index) {
                      int row = index ~/ BlockPuzzleProvider.boardWidth;
                      int col = index % BlockPuzzleProvider.boardWidth;

                      Color? cellColor = provider.board[row][col];

                      // Draw current block
                      if (provider.currentBlock != null) {
                        int blockX = col - provider.currentBlock!.x;
                        int blockY = row - provider.currentBlock!.y;

                        if (blockX >= 0 && blockX < provider.currentBlock!.width &&
                            blockY >= 0 && blockY < provider.currentBlock!.height &&
                            provider.currentBlock!.shape[blockY][blockX] == 1) {
                          cellColor = provider.currentBlock!.color;
                        }
                      }

                      return Container(
                        color: cellColor ?? Colors.grey[900],
                        child: cellColor != null ? Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: cellColor.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ) : null,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Side panel
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Next block preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text("Next", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (provider.nextBlock != null)
                          SizedBox(
                            height: 80,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                              ),
                              itemCount: 16,
                              itemBuilder: (ctx, index) {
                                int row = index ~/ 4;
                                int col = index % 4;

                                bool hasBlock = row < provider.nextBlock!.height &&
                                               col < provider.nextBlock!.width &&
                                               provider.nextBlock!.shape[row][col] == 1;

                                return Container(
                                  color: hasBlock ? provider.nextBlock!.color : Colors.transparent,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Controls
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ControlButton(Icons.arrow_left, provider.moveLeft),
                            const SizedBox(width: 10),
                            _ControlButton(Icons.rotate_right, provider.rotate),
                            const SizedBox(width: 10),
                            _ControlButton(Icons.arrow_right, provider.moveRight),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _ControlButton(Icons.arrow_downward, provider.drop, size: 60),
                      ],
                    ),
                  ),

                  if (provider.gameOver)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        "Game Over!\nScore: ${provider.score}",
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (provider.paused && !provider.gameOver)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        "Paused",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _ControlButton(this.icon, this.onPressed, {this.size = 50});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Icon(icon, size: size * 0.6),
      ),
    );
  }
}