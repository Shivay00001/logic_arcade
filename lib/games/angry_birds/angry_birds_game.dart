import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

// -----------------------------------------------------------------------------
// ANGRY BIRDS LOGIC
// -----------------------------------------------------------------------------

class Bird {
  double x, y;
  double vx = 0, vy = 0;
  bool launched = false;
  bool active = true;

  Bird(this.x, this.y);

  void update() {
    if (!launched || !active) return;

    x += vx;
    y += vy;
    vy += 0.5; // Gravity

    // Apply air resistance
    vx *= 0.99;
    vy *= 0.99;

    // Deactivate if out of bounds
    if (x < -50 || x > 450 || y > 600) {
      active = false;
    }
  }

  void launch(double power, double angle) {
    vx = power * cos(angle);
    vy = power * sin(angle);
    launched = true;
  }
}

class Pig {
  double x, y;
  bool alive = true;
  int hits = 0;

  Pig(this.x, this.y);

  void hit() {
    hits++;
    if (hits >= 2) {
      alive = false;
    }
  }
}

class Block {
  double x, y;
  double width, height;
  bool destroyed = false;
  int hits = 0;

  Block(this.x, this.y, this.width, this.height);

  void hit() {
    hits++;
    if (hits >= 2) {
      destroyed = true;
    }
  }

  Rect getRect() => Rect.fromLTWH(x, y, width, height);
}

class AngryBirdsProvider extends ChangeNotifier {
  late Bird _bird;
  late List<Pig> _pigs;
  late List<Block> _blocks;
  double _aimAngle = 0.0;
  double _aimPower = 0.0;
  bool _aiming = false;
  int _score = 0;
  int _birdsLeft = 3;
  bool _gameOver = false;
  bool _levelComplete = false;

  Bird get bird => _bird;
  List<Pig> get pigs => _pigs;
  List<Block> get blocks => _blocks;
  double get aimAngle => _aimAngle;
  double get aimPower => _aimPower;
  bool get aiming => _aiming;
  int get score => _score;
  int get birdsLeft => _birdsLeft;
  bool get gameOver => _gameOver;
  bool get levelComplete => _levelComplete;

  AngryBirdsProvider() {
    _initializeLevel();
    _startGameLoop();
  }

  void _initializeLevel() {
    _bird = Bird(100, 400);
    _pigs = [
      Pig(300, 450),
      Pig(350, 450),
      Pig(325, 400),
    ];
    _blocks = [
      Block(280, 480, 40, 20),
      Block(320, 480, 40, 20),
      Block(360, 480, 40, 20),
      Block(300, 440, 20, 40),
      Block(340, 440, 20, 40),
      Block(320, 400, 40, 20),
    ];

    _score = 0;
    _birdsLeft = 3;
    _gameOver = false;
    _levelComplete = false;
  }

  void startAiming(double angle, double power) {
    if (_bird.launched || _gameOver || _levelComplete) return;

    _aiming = true;
    _aimAngle = angle;
    _aimPower = power.clamp(5.0, 15.0);
  }

  void launchBird() {
    if (!_aiming || _bird.launched) return;

    _aiming = false;
    _bird.launch(_aimPower, _aimAngle);
  }

  void _startGameLoop() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_gameOver && !_levelComplete) {
        _updatePhysics();
        notifyListeners();
      }
    });
  }

  void _updatePhysics() {
    _bird.update();

    // Check collisions with blocks
    for (Block block in _blocks) {
      if (!block.destroyed && _checkCollision(_bird, block.getRect())) {
        block.hit();
        _bird.active = false;
        _score += 10;
        break;
      }
    }

    // Check collisions with pigs
    for (Pig pig in _pigs) {
      if (pig.alive && _checkCollision(_bird, Rect.fromLTWH(pig.x - 15, pig.y - 15, 30, 30))) {
        pig.hit();
        _bird.active = false;
        _score += 50;
        break;
      }
    }

    // Check if bird stopped moving
    if (!_bird.active && _bird.launched) {
      _birdsLeft--;
      if (_birdsLeft <= 0) {
        _gameOver = true;
      } else {
        // Reset bird for next shot
        _bird = Bird(100, 400);
      }

      _checkLevelComplete();
    }
  }

  bool _checkCollision(Bird bird, Rect rect) {
    return bird.x >= rect.left && bird.x <= rect.right &&
           bird.y >= rect.top && bird.y <= rect.bottom;
  }

  void _checkLevelComplete() {
    bool allPigsDead = _pigs.every((pig) => !pig.alive);
    if (allPigsDead) {
      _levelComplete = true;
      _score += 100; // Bonus for completing level
    }
  }

  void restart() {
    _initializeLevel();
    notifyListeners();
  }

  bool isPigAlive(int index) => _pigs[index].alive;
  bool isBlockDestroyed(int index) => _blocks[index].destroyed;
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class AngryBirdsGame extends StatelessWidget {
  const AngryBirdsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AngryBirdsProvider(),
      child: const _AngryBirdsGameContent(),
    );
  }
}

class _AngryBirdsGameContent extends StatelessWidget {
  const _AngryBirdsGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AngryBirdsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Angry Birds", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "Score: ${provider.score} | Birds: ${provider.birdsLeft}",
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
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF87CEEB), Color(0xFF98FB98)],
              ),
            ),
          ),

          // Ground
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              color: Color(0xFF8B4513),
            ),
          ),

          // Slingshot base
          Positioned(
            left: 80,
            bottom: 50,
            child: Container(
              width: 20,
              height: 100,
              color: Colors.brown,
            ),
          ),

          // Slingshot arm
          Positioned(
            left: 85,
            bottom: 130,
            child: Container(
              width: 10,
              height: 50,
              color: Colors.brown,
              transform: Matrix4.rotationZ(-0.3),
              transformAlignment: Alignment.bottomCenter,
            ),
          ),

          // Blocks
          ...List.generate(provider.blocks.length, (index) {
            Block block = provider.blocks[index];
            return Positioned(
              left: block.x,
              top: block.y,
              child: Container(
                width: block.width,
                height: block.height,
                color: provider.isBlockDestroyed(index) ? Colors.transparent : Colors.brown,
                child: provider.isBlockDestroyed(index) ? null : Container(
                  margin: const EdgeInsets.all(2),
                  color: Colors.brown[300],
                ),
              ),
            );
          }),

          // Pigs
          ...List.generate(provider.pigs.length, (index) {
            Pig pig = provider.pigs[index];
            return Positioned(
              left: pig.x - 15,
              top: pig.y - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: provider.isPigAlive(index) ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: provider.isPigAlive(index) ? const Center(
                  child: Text('🐷', style: TextStyle(fontSize: 16)),
                ) : null,
              ),
            );
          }),

          // Bird
          Positioned(
            left: provider.bird.x - 15,
            top: provider.bird.y - 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🐦', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),

          // Aiming controls
          if (!provider.bird.launched && !provider.gameOver && !provider.levelComplete)
            Positioned(
              bottom: 100,
              left: 20,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => provider.startAiming(-0.5, 12.0),
                    child: const Text("Light Shot"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => provider.startAiming(-0.3, 14.0),
                    child: const Text("Medium Shot"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => provider.startAiming(-0.1, 15.0),
                    child: const Text("Power Shot"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: provider.launchBird,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text("LAUNCH!"),
                  ),
                ],
              ),
            ),

          // Game status
          if (provider.gameOver || provider.levelComplete)
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.levelComplete ? "Level Complete!" : "Game Over!",
                      style: GoogleFonts.outfit(
                        color: provider.levelComplete ? Colors.green : Colors.red,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Final Score: ${provider.score}",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: provider.restart,
                      child: const Text("Play Again"),
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