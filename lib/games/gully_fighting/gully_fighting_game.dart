import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// GULLY FIGHTING LOGIC
// -----------------------------------------------------------------------------

enum EntityType { player, enemy, gun, empty }

class Entity {
  EntityType type;
  bool isAlive;

  Entity(this.type, {this.isAlive = true});

  String get symbol {
    switch (type) {
      case EntityType.player: return isAlive ? '🧑' : '💀';
      case EntityType.enemy: return isAlive ? '👤' : '💀';
      case EntityType.gun: return '🔫';
      case EntityType.empty: return '';
    }
  }

  Color get color {
    switch (type) {
      case EntityType.player: return isAlive ? Colors.blue : Colors.grey;
      case EntityType.enemy: return isAlive ? Colors.red : Colors.grey;
      case EntityType.gun: return Colors.black;
      case EntityType.empty: return Colors.transparent;
    }
  }
}

class GullyFightingProvider extends ChangeNotifier {
  static const int gridSize = 8;
  late List<List<Entity>> _board;
  int _playerX = 0, _playerY = 0;
  bool _hasGun = false;
  int _enemiesLeft = 0;
  bool _gameOver = false;
  bool _playerWon = false;
  String _message = "Find the gun!";

  List<List<Entity>> get board => _board;
  bool get hasGun => _hasGun;
  int get enemiesLeft => _enemiesLeft;
  bool get gameOver => _gameOver;
  bool get playerWon => _playerWon;
  String get message => _message;

  GullyFightingProvider() {
    _initializeGame();
  }

  void _initializeGame() {
    _board = List.generate(gridSize, (_) =>
      List.generate(gridSize, (_) => Entity(EntityType.empty))
    );

    // Place player
    _playerX = 0;
    _playerY = 0;
    _board[_playerY][_playerX] = Entity(EntityType.player);

    // Place gun randomly
    Random random = Random();
    int gunX, gunY;
    do {
      gunX = random.nextInt(gridSize);
      gunY = random.nextInt(gridSize);
    } while (gunX == _playerX && gunY == _playerY);

    _board[gunY][gunX] = Entity(EntityType.gun);

    // Place enemies
    _enemiesLeft = 3;
    for (int i = 0; i < _enemiesLeft; i++) {
      int enemyX, enemyY;
      do {
        enemyX = random.nextInt(gridSize);
        enemyY = random.nextInt(gridSize);
      } while ((_board[enemyY][enemyX].type != EntityType.empty) ||
               (enemyX == _playerX && enemyY == _playerY));

      _board[enemyY][enemyX] = Entity(EntityType.enemy);
    }

    _hasGun = false;
    _gameOver = false;
    _playerWon = false;
    _message = "Find the gun!";
    notifyListeners();
  }

  void movePlayer(int dx, int dy) {
    if (_gameOver) return;

    int newX = _playerX + dx;
    int newY = _playerY + dy;

    if (newX < 0 || newX >= gridSize || newY < 0 || newY >= gridSize) {
      return; // Out of bounds
    }

    // Move player
    _board[_playerY][_playerX] = Entity(EntityType.empty);
    _playerX = newX;
    _playerY = newY;

    // Check what's at new position
    Entity currentEntity = _board[_playerY][_playerX];

    if (currentEntity.type == EntityType.gun) {
      _hasGun = true;
      _message = "You found the gun! Now eliminate all enemies!";
    } else if (currentEntity.type == EntityType.enemy) {
      if (_hasGun) {
        // Eliminate enemy
        currentEntity.isAlive = false;
        _enemiesLeft--;
        _message = "Enemy eliminated! ${_enemiesLeft} enemies left.";

        if (_enemiesLeft == 0) {
          _gameOver = true;
          _playerWon = true;
          _message = "Victory! All enemies eliminated!";
        }
      } else {
        // Player dies
        _gameOver = true;
        _playerWon = false;
        _message = "You were killed! Find the gun first.";
        _board[_playerY][_playerX] = Entity(EntityType.player);
        _board[_playerY][_playerX].isAlive = false;
        return;
      }
    }

    // Place player at new position
    _board[_playerY][_playerX] = Entity(EntityType.player);

    // Move enemies if player has gun
    if (_hasGun) {
      _moveEnemies();
    }

    notifyListeners();
  }

  void _moveEnemies() {
    // Simple enemy AI: move towards player
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (_board[y][x].type == EntityType.enemy && _board[y][x].isAlive) {
          _moveSingleEnemy(x, y);
        }
      }
    }
  }

  void _moveSingleEnemy(int enemyX, int enemyY) {
    int dx = (_playerX - enemyX).sign;
    int dy = (_playerY - enemyY).sign;

    // Try to move towards player
    List<List<int>> possibleMoves = [
      [dx, dy], // diagonal
      [dx, 0],  // horizontal
      [0, dy],  // vertical
    ];

    for (List<int> move in possibleMoves) {
      int newX = enemyX + move[0];
      int newY = enemyY + move[1];

      if (newX >= 0 && newX < gridSize && newY >= 0 && newY < gridSize) {
        Entity targetEntity = _board[newY][newX];

        if (targetEntity.type == EntityType.empty) {
          // Move enemy
          _board[newY][newX] = _board[enemyY][enemyX];
          _board[enemyY][enemyX] = Entity(EntityType.empty);
          break;
        } else if (targetEntity.type == EntityType.player && !targetEntity.isAlive) {
          // Attack dead player? Skip
          continue;
        }
      }
    }
  }

  void restart() {
    _initializeGame();
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class GullyFightingGame extends StatelessWidget {
  const GullyFightingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GullyFightingProvider(),
      child: const _GullyFightingGameContent(),
    );
  }
}

class _GullyFightingGameContent extends StatelessWidget {
  const _GullyFightingGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GullyFightingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Gully Fighting", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  provider.hasGun ? Icons.gavel : Icons.search,
                  color: provider.hasGun ? Colors.red : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Enemies: ${provider.enemiesLeft}",
                  style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.text),
                ),
              ],
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
                      borderRadius: BorderRadius.circular(8),
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
                        Entity entity = provider.board[row][col];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              entity.symbol,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Message
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              provider.message,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppTheme.text,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Directional pad
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Stack(
                    children: [
                      // Up
                      Positioned(
                        top: 20,
                        left: 80,
                        right: 80,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up, size: 40),
                          onPressed: () => provider.movePlayer(0, -1),
                        ),
                      ),
                      // Down
                      Positioned(
                        bottom: 20,
                        left: 80,
                        right: 80,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 40),
                          onPressed: () => provider.movePlayer(0, 1),
                        ),
                      ),
                      // Left
                      Positioned(
                        left: 20,
                        top: 80,
                        bottom: 80,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_left, size: 40),
                          onPressed: () => provider.movePlayer(-1, 0),
                        ),
                      ),
                      // Right
                      Positioned(
                        right: 20,
                        top: 80,
                        bottom: 80,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right, size: 40),
                          onPressed: () => provider.movePlayer(1, 0),
                        ),
                      ),
                      // Center indicator
                      Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Text(
                  "Use the directional pad to move.\nFind the 🔫 gun first, then eliminate all 👤 enemies!",
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