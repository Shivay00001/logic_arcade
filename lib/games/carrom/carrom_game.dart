import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:logic_arcade/services/ads_service.dart';
import 'package:logic_arcade/services/unlock_service.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

// -----------------------------------------------------------------------------
// CARROM MODES AND SETUP
// -----------------------------------------------------------------------------

enum GameMode { humanVsAi, humanVsHuman }

class CarromSetupScreen extends StatefulWidget {
  const CarromSetupScreen({super.key});

  @override
  State<CarromSetupScreen> createState() => _CarromSetupScreenState();
}

class _CarromSetupScreenState extends State<CarromSetupScreen> {
  int _playerCount = 2;
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _adsService.loadRewardedAd(() {
      UnlockService().unlockGame(UnlockService.carrom);
      setState(() {});
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CarromGame(mode: GameMode.humanVsAi, playerCount: 2),
        ),
      );
    });
  }

  void _showUnlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF34495E),
        title: const Text(
          "Unlock Carrom AI",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Watch a short ad to unlock playing Carrom against the computer!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_adsService.isRewardedAdReady) {
                _adsService.showRewardedAd(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ad not ready. Please try again.")),
                );
              }
            },
            child: const Text("Watch Ad"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Carrom Setup", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Choose Game Mode",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),

            // Player count selector for Human vs Human
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF34495E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF3498DB), width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    "Number of Players (Human vs Human)",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: _playerCount > 2 ? () => setState(() => _playerCount--) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498DB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$_playerCount Players",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _playerCount < 4 ? () => setState(() => _playerCount++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _ModeButton(
              title: "Human vs AI",
              subtitle: UnlockService().isGameUnlocked(UnlockService.carrom) ? "Play against computer" : "Watch ad to unlock",
              icon: UnlockService().isGameUnlocked(UnlockService.carrom) ? Icons.computer : Icons.lock,
              onPressed: () {
                if (UnlockService().isGameUnlocked(UnlockService.carrom)) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => CarromGame(mode: GameMode.humanVsAi, playerCount: 2),
                    ),
                  );
                } else {
                  _showUnlockDialog(context);
                }
              },
            ),
            const SizedBox(height: 20),
            _ModeButton(
              title: "Human vs Human",
              subtitle: _playerCount == 2 ? "Two player local game" : "$_playerCount player local game",
              icon: Icons.people,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CarromGame(mode: GameMode.humanVsHuman, playerCount: _playerCount),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF34495E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3498DB), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF3498DB),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CARROM LOGIC
// -----------------------------------------------------------------------------

enum DiscColor { white, black, red, striker }

class Disc {
  double x, y;
  double vx = 0, vy = 0;
  DiscColor color;
  bool inPocket = false;

  Disc(this.x, this.y, this.color);

  void update() {
    x += vx;
    y += vy;

    // Apply friction
    vx *= 0.98;
    vy *= 0.98;

    // Stop if very slow
    if (vx.abs() < 0.1) vx = 0;
    if (vy.abs() < 0.1) vy = 0;
  }

  bool isMoving() => vx.abs() > 0.1 || vy.abs() > 0.1;
}

class CarromProvider extends ChangeNotifier {
  static const double boardSize = 300.0;
  static const double pocketRadius = 15.0;

  late List<Disc> _discs;
  Disc? _striker;
  bool _isAiming = false;
  Offset _aimStart = Offset.zero;
  Offset _aimEnd = Offset.zero;
  List<int> _playerScores = [];
  int _currentPlayerIndex = 0;
  bool _gameOver = false;
  final GameMode _gameMode;
  final int _playerCount;
  bool _aiThinking = false;

  List<Disc> get discs => _discs;
  Disc? get striker => _striker;
  bool get isAiming => _isAiming;
  Offset get aimStart => _aimStart;
  Offset get aimEnd => _aimEnd;
  int get currentPlayerScore => _playerScores.length > _currentPlayerIndex ? _playerScores[_currentPlayerIndex] : 0;
  bool get isCurrentPlayerTurn => true; // Always true for now, logic handled elsewhere
  bool get gameOver => _gameOver;
  GameMode get gameMode => _gameMode;
  int get currentPlayerIndex => _currentPlayerIndex;
  List<int> get playerScores => _playerScores;
  bool get aiThinking => _aiThinking;
  int get playerCount => _playerCount;

  CarromProvider({required GameMode mode, int playerCount = 2}) : _gameMode = mode, _playerCount = playerCount {
    _initializeGame();
    _startGameLoop();
  }

  void _initializeGame() {
    _discs = [];
    _playerScores = List.filled(_playerCount, 0);
    _currentPlayerIndex = 0;
    _gameOver = false;
    _aiThinking = false;

    // Add striker
    _striker = Disc(boardSize / 2, boardSize - 30, DiscColor.striker);
    _discs.add(_striker!);

    // Distribute discs among players
    int totalDiscs = 18; // 18 regular discs + 1 queen
    int discsPerPlayer = totalDiscs ~/ _playerCount;
    int remainingDiscs = totalDiscs % _playerCount;

    List<DiscColor> playerColors = [DiscColor.white, DiscColor.black, DiscColor.red];
    if (_playerCount > 3) playerColors.add(DiscColor.striker); // Use striker color for 4th player

    int discIndex = 0;
    for (int player = 0; player < _playerCount; player++) {
      int playerDiscCount = discsPerPlayer + (player < remainingDiscs ? 1 : 0);

      for (int i = 0; i < playerDiscCount; i++) {
        double angle = (discIndex * 2 * pi) / 19; // 19 positions for even distribution
        double radius = 50 + (discIndex % 3) * 10; // Vary radius for better distribution
        double x = boardSize / 2 + cos(angle) * radius;
        double y = boardSize / 2 + sin(angle) * radius;
        _discs.add(Disc(x, y, playerColors[player % playerColors.length]));
        discIndex++;
      }
    }

    // Add red queen (special disc)
    _discs.add(Disc(boardSize / 2, boardSize / 2, DiscColor.red));
  }

  void startAiming(Offset position) {
    if (_isAnyDiscMoving() || _aiThinking) return;
    _isAiming = true;
    _aimStart = position;
    _aimEnd = position;
    notifyListeners();
  }

  void updateAim(Offset position) {
    if (!_isAiming) return;
    _aimEnd = position;
    notifyListeners();
  }

  void shoot() {
    if (!_isAiming || _striker == null) return;

    _isAiming = false;

    // Calculate velocity from aim
    double dx = _aimStart.dx - _aimEnd.dx;
    double dy = _aimStart.dy - _aimEnd.dy;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance > 0) {
      double speed = min(distance / 10, 15); // Max speed limit
      _striker!.vx = (dx / distance) * speed;
      _striker!.vy = (dy / distance) * speed;
    }

    notifyListeners();
  }

  void _startGameLoop() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_gameOver) {
        _updatePhysics();
        notifyListeners();
      }
    });
  }

  void _updatePhysics() {
    // Update all discs
    for (Disc disc in _discs) {
      if (!disc.inPocket) {
        disc.update();
        _handleWallCollisions(disc);
      }
    }

    // Handle disc collisions
    for (int i = 0; i < _discs.length; i++) {
      for (int j = i + 1; j < _discs.length; j++) {
        _handleDiscCollision(_discs[i], _discs[j]);
      }
    }

    // Check for pockets
    for (Disc disc in _discs) {
      if (!disc.inPocket) {
        _checkPocket(disc);
      }
    }

    // Check if all discs stopped moving
    if (!_isAnyDiscMoving() && !_isAiming) {
      _handleTurnEnd();
    }
  }

  void _handleWallCollisions(Disc disc) {
    if (disc.x - 10 < 0) {
      disc.x = 10;
      disc.vx = -disc.vx * 0.8;
    } else if (disc.x + 10 > boardSize) {
      disc.x = boardSize - 10;
      disc.vx = -disc.vx * 0.8;
    }

    if (disc.y - 10 < 0) {
      disc.y = 10;
      disc.vy = -disc.vy * 0.8;
    } else if (disc.y + 10 > boardSize) {
      disc.y = boardSize - 10;
      disc.vy = -disc.vy * 0.8;
    }
  }

  void _handleDiscCollision(Disc d1, Disc d2) {
    double dx = d2.x - d1.x;
    double dy = d2.y - d1.y;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance < 20) { // Disc diameter
      // Separate discs
      double overlap = 20 - distance;
      double separationX = (dx / distance) * overlap / 2;
      double separationY = (dy / distance) * overlap / 2;

      d1.x -= separationX;
      d1.y -= separationY;
      d2.x += separationX;
      d2.y += separationY;

      // Exchange velocities (simplified)
      double tempVx = d1.vx;
      double tempVy = d1.vy;
      d1.vx = d2.vx * 0.8;
      d1.vy = d2.vy * 0.8;
      d2.vx = tempVx * 0.8;
      d2.vy = tempVy * 0.8;
    }
  }

  void _checkPocket(Disc disc) {
    // Check corners
    List<Offset> pockets = [
      const Offset(0, 0),
      Offset(boardSize, 0),
      Offset(0, boardSize),
      Offset(boardSize, boardSize),
    ];

    for (Offset pocket in pockets) {
      double distance = sqrt(pow(disc.x - pocket.dx, 2) + pow(disc.y - pocket.dy, 2));
      if (distance < pocketRadius) {
        disc.inPocket = true;
        disc.vx = 0;
        disc.vy = 0;

        // Update scores - map disc colors to player indices
        int playerIndex = _getPlayerIndexForColor(disc.color);
        if (playerIndex >= 0 && playerIndex < _playerScores.length) {
          _playerScores[playerIndex]++;
        }

        break;
      }
    }
  }

  int _getPlayerIndexForColor(DiscColor color) {
    // Map disc colors to player indices
    switch (color) {
      case DiscColor.white: return 0;
      case DiscColor.black: return _playerCount > 1 ? 1 : 0;
      case DiscColor.red: return _playerCount > 2 ? 2 : 0;
      case DiscColor.striker: return _playerCount > 3 ? 3 : 0;
    }
  }

  void _handleTurnEnd() {
    // Check win conditions - player needs to pocket all their discs
    int targetScore = (_discs.length - 1) ~/ _playerCount; // -1 for striker, divided among players

    for (int i = 0; i < _playerScores.length; i++) {
      if (_playerScores[i] >= targetScore) {
        _gameOver = true;
        return;
      }
    }

    // Switch to next player
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _playerCount;

    // AI turn for human vs AI mode
    if (_gameMode == GameMode.humanVsAi && _currentPlayerIndex != 0) { // Assuming player 0 is human
      _makeAIMove();
    }
  }

  void _makeAIMove() {
    _aiThinking = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      // Simple AI: aim at nearest disc
      if (_striker != null) {
        Disc? target = _findNearestDisc();
        if (target != null) {
          double dx = target.x - _striker!.x;
          double dy = target.y - _striker!.y;
          double distance = sqrt(dx * dx + dy * dy);

          if (distance > 0) {
            double speed = 10;
            _striker!.vx = (dx / distance) * speed;
            _striker!.vy = (dy / distance) * speed;
          }
        }
      }

      _aiThinking = false;
      notifyListeners();
    });
  }

  Disc? _findNearestDisc() {
    if (_striker == null) return null;

    Disc? nearest;
    double minDistance = double.infinity;

    for (Disc disc in _discs) {
      if (disc != _striker && !disc.inPocket) {
        double distance = sqrt(pow(disc.x - _striker!.x, 2) + pow(disc.y - _striker!.y, 2));
        if (distance < minDistance) {
          minDistance = distance;
          nearest = disc;
        }
      }
    }

    return nearest;
  }

  bool _isAnyDiscMoving() {
    return _discs.any((disc) => disc.isMoving());
  }

  void reset() {
    _initializeGame();
    notifyListeners();
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class CarromGame extends StatelessWidget {
  final GameMode mode;
  final int playerCount;

  const CarromGame({super.key, required this.mode, this.playerCount = 2});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarromProvider(mode: mode, playerCount: playerCount),
      child: const _CarromGameContent(),
    );
  }
}

class _CarromGameContent extends StatelessWidget {
  const _CarromGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarromProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Carrom", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              provider.playerCount == 2
                  ? "P1: ${provider.playerScores[0]} | P2: ${provider.playerScores[1]}"
                  : "Current: P${provider.currentPlayerIndex + 1}",
              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.text),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // Game board
          Expanded(
            child: Center(
              child: GestureDetector(
                onPanStart: (details) {
                  if (provider.gameMode == GameMode.humanVsHuman || provider.currentPlayerIndex == 0) {
                    provider.startAiming(details.localPosition);
                  }
                },
                onPanUpdate: (details) {
                  provider.updateAim(details.localPosition);
                },
                onPanEnd: (details) {
                  provider.shoot();
                },
                child: Container(
                  width: CarromProvider.boardSize,
                  height: CarromProvider.boardSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513), // Brown board
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Board markings
                      CustomPaint(
                        painter: CarromBoardPainter(),
                        size: const Size(CarromProvider.boardSize, CarromProvider.boardSize),
                      ),

                      // Discs
                      ...provider.discs.map((disc) {
                        if (disc.inPocket) return const SizedBox.shrink();

                        Color discColor;
                        switch (disc.color) {
                          case DiscColor.white:
                            discColor = Colors.white;
                            break;
                          case DiscColor.black:
                            discColor = Colors.black;
                            break;
                          case DiscColor.red:
                            discColor = Colors.red;
                            break;
                          case DiscColor.striker:
                            // Striker color indicates current player
                            List<Color> playerColors = [Colors.white, Colors.black, Colors.red, Colors.blue];
                            discColor = playerColors[provider.currentPlayerIndex % playerColors.length];
                            break;
                        }

                        return Positioned(
                          left: disc.x - 10,
                          top: disc.y - 10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: discColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Aim line
                      if (provider.isAiming)
                        CustomPaint(
                          painter: AimLinePainter(
                            startX: provider.aimStart.dx,
                            startY: provider.aimStart.dy,
                            endX: provider.aimEnd.dx,
                            endY: provider.aimEnd.dy,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  provider.gameOver
                      ? "Player ${provider.playerScores.indexOf(provider.playerScores.reduce((a, b) => a > b ? a : b)) + 1} Wins!"
                      : "Player ${provider.currentPlayerIndex + 1} to play${provider.aiThinking ? ' (AI thinking...)' : ''}",
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Tap and drag to aim, release to shoot.\nPocket all your discs to win!",
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

class CarromBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 30, paint);

    // Corner pockets (visual)
    final pocketPaint = Paint()..color = Colors.black;
    List<Offset> pockets = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    for (Offset pocket in pockets) {
      canvas.drawCircle(pocket, CarromProvider.pocketRadius, pocketPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AimLinePainter extends CustomPainter {
  final double startX, startY, endX, endY;

  AimLinePainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

    // Arrow head
    double dx = endX - startX;
    double dy = endY - startY;
    double angle = atan2(dy, dx);

    double arrowSize = 10;
    double arrowAngle = pi / 6;

    Offset arrowPoint1 = Offset(
      endX - arrowSize * cos(angle - arrowAngle),
      endY - arrowSize * sin(angle - arrowAngle),
    );
    Offset arrowPoint2 = Offset(
      endX - arrowSize * cos(angle + arrowAngle),
      endY - arrowSize * sin(angle + arrowAngle),
    );

    canvas.drawLine(Offset(endX, endY), arrowPoint1, paint);
    canvas.drawLine(Offset(endX, endY), arrowPoint2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}