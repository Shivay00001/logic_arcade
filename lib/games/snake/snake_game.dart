import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

// -----------------------------------------------------------------------------
// GAME LOGIC / MODEL
// -----------------------------------------------------------------------------

enum Direction { up, down, left, right }

class SnakeProvider extends ChangeNotifier {
  static const int gridSize = 20;
  static const int initialSpeed = 300; // milliseconds

  late List<List<int>> _grid;
  late List<Point<int>> _snake;
  late Point<int> _food;
  Direction _direction = Direction.right;
  Direction _nextDirection = Direction.right;
  int _score = 0;
  bool _gameOver = false;
  bool _paused = false;
  Timer? _gameTimer;
  int _speed = initialSpeed;

  List<List<int>> get grid => _grid;
  List<Point<int>> get snake => _snake;
  Point<int> get food => _food;
  int get score => _score;
  bool get gameOver => _gameOver;
  bool get paused => _paused;

  SnakeProvider() {
    _startNewGame();
  }

  void _startNewGame() {
    _grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    _snake = [Point(gridSize ~/ 2, gridSize ~/ 2)];
    _direction = Direction.right;
    _nextDirection = Direction.right;
    _score = 0;
    _gameOver = false;
    _paused = false;
    _speed = initialSpeed;
    _placeFood();
    _updateGrid();
    _startGameLoop();
  }

  void _placeFood() {
    Random random = Random();
    do {
      _food = Point(random.nextInt(gridSize), random.nextInt(gridSize));
    } while (_snake.contains(_food));
  }

  void _updateGrid() {
    // Clear grid
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        _grid[i][j] = 0;
      }
    }

    // Place snake (1 = snake body, 2 = snake head)
    for (int i = 0; i < _snake.length; i++) {
      int value = (i == 0) ? 2 : 1; // Head = 2, body = 1
      if (_snake[i].x >= 0 && _snake[i].x < gridSize &&
          _snake[i].y >= 0 && _snake[i].y < gridSize) {
        _grid[_snake[i].x][_snake[i].y] = value;
      }
    }

    // Place food (3 = food)
    if (_food.x >= 0 && _food.x < gridSize &&
        _food.y >= 0 && _food.y < gridSize) {
      _grid[_food.x][_food.y] = 3;
    }
  }

  void changeDirection(Direction newDirection) {
    // Prevent reversing into self
    if ((_direction == Direction.up && newDirection == Direction.down) ||
        (_direction == Direction.down && newDirection == Direction.up) ||
        (_direction == Direction.left && newDirection == Direction.right) ||
        (_direction == Direction.right && newDirection == Direction.left)) {
      return;
    }
    _nextDirection = newDirection;
  }

  void _moveSnake() {
    _direction = _nextDirection;

    Point<int> head = _snake.first;
    Point<int> newHead;

    switch (_direction) {
      case Direction.up:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.down:
        newHead = Point(head.x + 1, head.y);
        break;
      case Direction.left:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.right:
        newHead = Point(head.x, head.y + 1);
        break;
    }

    // Check wall collision
    if (newHead.x < 0 || newHead.x >= gridSize ||
        newHead.y < 0 || newHead.y >= gridSize) {
      _gameOver = true;
      _gameTimer?.cancel();
      notifyListeners();
      return;
    }

    // Check self collision
    if (_snake.contains(newHead)) {
      _gameOver = true;
      _gameTimer?.cancel();
      notifyListeners();
      return;
    }

    _snake.insert(0, newHead);

    // Check food collision
    if (newHead == _food) {
      _score += 10;
      _placeFood();
      // Increase speed every 50 points
      if (_score % 50 == 0 && _speed > 100) {
        _speed -= 20;
        _gameTimer?.cancel();
        _startGameLoop();
      }
    } else {
      _snake.removeLast();
    }

    _updateGrid();
    notifyListeners();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(Duration(milliseconds: _speed), (timer) {
      if (!_paused && !_gameOver) {
        _moveSnake();
      }
    });
  }

  void togglePause() {
    _paused = !_paused;
    notifyListeners();
  }

  void restart() {
    _gameTimer?.cancel();
    _startNewGame();
  }
}

// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class SnakeGame extends StatelessWidget {
  const SnakeGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SnakeProvider(),
      child: const _SnakeGameContent(),
    );
  }
}

class _SnakeGameContent extends StatefulWidget {
  const _SnakeGameContent();

  @override
  State<_SnakeGameContent> createState() => _SnakeGameContentState();
}

class _SnakeGameContentState extends State<_SnakeGameContent> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SnakeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Snake", style: GoogleFonts.outfit()),
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
      body: Column(
        children: [
          // Game board
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (provider.gameOver || provider.paused) return;
                      double velocity = details.primaryVelocity ?? 0;
                      if (velocity < -500) { // Swipe up
                        provider.changeDirection(Direction.up);
                      } else if (velocity > 500) { // Swipe down
                        provider.changeDirection(Direction.down);
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      if (provider.gameOver || provider.paused) return;
                      double velocity = details.primaryVelocity ?? 0;
                      if (velocity < -500) { // Swipe left
                        provider.changeDirection(Direction.left);
                      } else if (velocity > 500) { // Swipe right
                        provider.changeDirection(Direction.right);
                      }
                    },
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
                          crossAxisCount: SnakeProvider.gridSize,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                        ),
                        itemCount: SnakeProvider.gridSize * SnakeProvider.gridSize,
                        itemBuilder: (ctx, index) {
                          int row = index ~/ SnakeProvider.gridSize;
                          int col = index % SnakeProvider.gridSize;
                          int cellType = provider.grid[row][col];
                          return _SnakeCell(cellType: cellType);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Touch/Swipe controls
                Text(
                  "Swipe on the game board to control the snake:\n↑ Swipe up  ↓ Swipe down  ← Swipe left  → Swipe right",
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                if (provider.gameOver) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Game Over! Tap refresh to play again.",
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                if (provider.paused && !provider.gameOver) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Paused - Tap play to continue",
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Handle keyboard input for desktop
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final provider = context.read<SnakeProvider>();
      if (provider.gameOver || provider.paused) return false;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.keyW:
          provider.changeDirection(Direction.up);
          return true;
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.keyS:
          provider.changeDirection(Direction.down);
          return true;
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          provider.changeDirection(Direction.left);
          return true;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          provider.changeDirection(Direction.right);
          return true;
        case LogicalKeyboardKey.space:
          provider.togglePause();
          return true;
      }
    }
    return false;
  }
}

class _SnakeCell extends StatelessWidget {
  final int cellType;

  const _SnakeCell({required this.cellType});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (cellType) {
      case 0: // Empty
        color = Colors.grey[900]!;
        break;
      case 1: // Snake body
        color = AppTheme.primary;
        break;
      case 2: // Snake head
        color = AppTheme.primary.withOpacity(0.8);
        break;
      case 3: // Food
        color = AppTheme.secondary;
        break;
      default:
        color = Colors.grey[900]!;
    }

    return Container(
      color: color,
      child: cellType == 3 ? const Center(
        child: SizedBox(
          width: 6,
          height: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ) : null,
    );
  }
}

