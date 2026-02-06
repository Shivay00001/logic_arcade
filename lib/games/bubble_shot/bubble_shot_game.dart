import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

// -----------------------------------------------------------------------------
// BUBBLE SHOT LOGIC
// -----------------------------------------------------------------------------

class Bubble {
  double x, y;
  Color color;
  bool markedForRemoval = false;

  Bubble(this.x, this.y, this.color);

  Bubble copy() => Bubble(x, y, color)..markedForRemoval = markedForRemoval;
}

class BubbleShotProvider extends ChangeNotifier {
  static const int boardWidth = 8;
  static const int boardHeight = 12;
  static const double bubbleRadius = 20.0;

  late List<Bubble> _bubbles;
  Bubble? _currentBubble;
  Bubble? _nextBubble;
  double _aimAngle = 0.0;
  int _score = 0;
  bool _gameOver = false;
  bool _animating = false;

  List<Bubble> get bubbles => _bubbles;
  Bubble? get currentBubble => _currentBubble;
  Bubble? get nextBubble => _nextBubble;
  double get aimAngle => _aimAngle;
  int get score => _score;
  bool get gameOver => _gameOver;
  bool get animating => _animating;

  BubbleShotProvider() {
    _initializeGame();
  }

  void _initializeGame() {
    _bubbles = [];
    _score = 0;
    _gameOver = false;
    _animating = false;
    _aimAngle = 0.0;

    // Create initial bubbles
    _generateInitialBubbles();

    // Create shooter bubbles
    _createNewBubble();
  }

  void _generateInitialBubbles() {
    Random random = Random();
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];

    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < boardWidth; col++) {
        if (row % 2 == 1 && col == boardWidth - 1) continue; // Offset rows

        double x = col * bubbleRadius * 2 + bubbleRadius + (row % 2 == 1 ? bubbleRadius : 0);
        double y = row * bubbleRadius * 1.8 + 100;

        _bubbles.add(Bubble(x, y, colors[random.nextInt(colors.length)]));
      }
    }
  }

  void _createNewBubble() {
    Random random = Random();
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];

    _nextBubble = Bubble(200, 500, colors[random.nextInt(colors.length)]);
    _currentBubble = _nextBubble;
    _nextBubble = Bubble(350, 550, colors[random.nextInt(colors.length)]);
  }

  void updateAimAngle(double angle) {
    _aimAngle = angle.clamp(-1.4, 1.4); // Limit shooting angle
    notifyListeners();
  }

  void shootBubble() {
    if (_currentBubble == null || _animating || _gameOver) return;

    _animating = true;
    const double speed = 8.0;

    double vx = speed * sin(_aimAngle);
    double vy = -speed * cos(_aimAngle);

    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_currentBubble == null) {
        timer.cancel();
        return;
      }

      _currentBubble!.x += vx;
      _currentBubble!.y += vy;

      // Check wall collisions
      if (_currentBubble!.x <= bubbleRadius || _currentBubble!.x >= 400 - bubbleRadius) {
        vx = -vx;
        _currentBubble!.x = _currentBubble!.x.clamp(bubbleRadius, 400 - bubbleRadius);
      }

      // Check collision with existing bubbles
      Bubble? hitBubble = _checkBubbleCollision(_currentBubble!);
      if (hitBubble != null) {
        timer.cancel();
        _attachBubbleToGrid(hitBubble);
        return;
      }

      // Check if bubble went too high
      if (_currentBubble!.y < 50) {
        timer.cancel();
        _attachBubbleToTop();
        return;
      }

      notifyListeners();
    });
  }

  Bubble? _checkBubbleCollision(Bubble movingBubble) {
    for (Bubble bubble in _bubbles) {
      double distance = sqrt(pow(movingBubble.x - bubble.x, 2) + pow(movingBubble.y - bubble.y, 2));
      if (distance <= bubbleRadius * 2) {
        return bubble;
      }
    }
    return null;
  }

  void _attachBubbleToGrid(Bubble hitBubble) {
    if (_currentBubble == null) return;

    // Find the closest grid position to attach to
    double gridX = (hitBubble.x / (bubbleRadius * 2)).round() * bubbleRadius * 2 + bubbleRadius;
    double gridY = hitBubble.y - bubbleRadius * 1.8;

    // Ensure it doesn't go below the hit bubble
    gridY = max(gridY, hitBubble.y - bubbleRadius * 1.8);

    _currentBubble!.x = gridX;
    _currentBubble!.y = gridY;

    _bubbles.add(_currentBubble!);
    _currentBubble = null;

    // Check for matches
    _checkMatches(_bubbles.last);

    // Create new bubble
    _createNewBubble();
    _animating = false;

    // Check game over
    _checkGameOver();

    notifyListeners();
  }

  void _attachBubbleToTop() {
    if (_currentBubble == null) return;

    _currentBubble!.y = 80; // Top position
    _bubbles.add(_currentBubble!);
    _currentBubble = null;

    _createNewBubble();
    _animating = false;

    _checkGameOver();
    notifyListeners();
  }

  void _checkMatches(Bubble startBubble) {
    List<Bubble> connected = _findConnectedBubbles(startBubble, startBubble.color);
    if (connected.length >= 3) {
      // Remove bubbles
      for (Bubble bubble in connected) {
        bubble.markedForRemoval = true;
      }

      // Add score
      _score += connected.length * 10;

      // Remove marked bubbles after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        _bubbles.removeWhere((b) => b.markedForRemoval);
        _applyGravity();
        notifyListeners();
      });
    }
  }

  List<Bubble> _findConnectedBubbles(Bubble start, Color color) {
    List<Bubble> connected = [];
    Set<Bubble> visited = {};

    void dfs(Bubble current) {
      if (visited.contains(current) || current.color != color) return;
      visited.add(current);
      connected.add(current);

      for (Bubble neighbor in _getNeighbors(current)) {
        dfs(neighbor);
      }
    }

    dfs(start);
    return connected;
  }

  List<Bubble> _getNeighbors(Bubble bubble) {
    List<Bubble> neighbors = [];
    for (Bubble other in _bubbles) {
      if (other != bubble) {
        double distance = sqrt(pow(bubble.x - other.x, 2) + pow(bubble.y - other.y, 2));
        if (distance <= bubbleRadius * 2.1) {
          neighbors.add(other);
        }
      }
    }
    return neighbors;
  }

  void _applyGravity() {
    for (Bubble bubble in _bubbles) {
      if (!bubble.markedForRemoval) {
        // Check if bubble should fall
        bool hasSupport = false;
        for (Bubble other in _bubbles) {
          if (other != bubble && !other.markedForRemoval) {
            if (other.y > bubble.y && (bubble.x - other.x).abs() < bubbleRadius * 1.5) {
              hasSupport = true;
              break;
            }
          }
        }

        if (!hasSupport && bubble.y < 400) {
          bubble.y += bubbleRadius * 1.8;
        }
      }
    }
  }

  void _checkGameOver() {
    // Game over if bubbles reach the bottom
    for (Bubble bubble in _bubbles) {
      if (bubble.y > 450) {
        _gameOver = true;
        break;
      }
    }
  }

  void restart() {
    _initializeGame();
    notifyListeners();
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class BubbleShotGame extends StatelessWidget {
  const BubbleShotGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BubbleShotProvider(),
      child: const _BubbleShotGameContent(),
    );
  }
}

class _BubbleShotGameContent extends StatelessWidget {
  const _BubbleShotGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BubbleShotProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Bubble Shot", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "Score: ${provider.score}",
                style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.text),
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
          // Game area
          Container(
            width: double.infinity,
            height: 600,
            color: Colors.black,
            child: Stack(
              children: [
                // Background grid
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue[900]!, Colors.blue[700]!],
                    ),
                  ),
                ),

                // Bubbles
                ...provider.bubbles.map((bubble) => Positioned(
                  left: bubble.x - 20,
                  top: bubble.y - 20,
                  child: AnimatedOpacity(
                    opacity: bubble.markedForRemoval ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bubble.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: bubble.color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),

                // Current bubble
                if (provider.currentBubble != null)
                  Positioned(
                    left: provider.currentBubble!.x - 20,
                    top: provider.currentBubble!.y - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: provider.currentBubble!.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Aim line
                if (provider.currentBubble != null && !provider.animating)
                  CustomPaint(
                    painter: AimLinePainter(
                      startX: 200,
                      startY: 500,
                      angle: provider.aimAngle,
                    ),
                  ),
              ],
            ),
          ),

          // Shooter controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Next bubble preview
                if (provider.nextBubble != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Next: "),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: provider.nextBubble!.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: provider.animating || provider.gameOver ? null : () => provider.shootBubble(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text("SHOOT"),
                    ),
                  ],
                ),

                // Aim controls
                if (!provider.animating && !provider.gameOver)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left, size: 32),
                          onPressed: () => provider.updateAimAngle(provider.aimAngle - 0.1),
                        ),
                        Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.center,
                            widthFactor: (provider.aimAngle + 1.4) / 2.8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right, size: 32),
                          onPressed: () => provider.updateAimAngle(provider.aimAngle + 0.1),
                        ),
                      ],
                    ),
                  ),

                if (provider.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      "Game Over! Score: ${provider.score}",
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

class AimLinePainter extends CustomPainter {
  final double startX, startY, angle;

  AimLinePainter({
    required this.startX,
    required this.startY,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double endX = startX + 100 * sin(angle);
    double endY = startY - 100 * cos(angle);

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

    // Arrow head
    double arrowSize = 8;
    double angle1 = angle - pi / 6;
    double angle2 = angle + pi / 6;

    canvas.drawLine(
      Offset(endX, endY),
      Offset(endX - arrowSize * sin(angle1), endY + arrowSize * cos(angle1)),
      paint,
    );
    canvas.drawLine(
      Offset(endX, endY),
      Offset(endX - arrowSize * sin(angle2), endY + arrowSize * cos(angle2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}