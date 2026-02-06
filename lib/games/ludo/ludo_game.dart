import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:logic_arcade/services/ads_service.dart';
import 'package:logic_arcade/services/unlock_service.dart';

// -----------------------------------------------------------------------------
// LUDO MODES AND SETUP
// -----------------------------------------------------------------------------

enum GameMode { humanVsAi, humanVsHuman }

class LudoSetupScreen extends StatefulWidget {
  const LudoSetupScreen({super.key});

  @override
  State<LudoSetupScreen> createState() => _LudoSetupScreenState();
}

class _LudoSetupScreenState extends State<LudoSetupScreen> {
  int _playerCount = 4;
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _adsService.loadRewardedAd(() {
      UnlockService().unlockGame(UnlockService.ludo);
      setState(() {});
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LudoGame(mode: GameMode.humanVsAi, playerCount: 4),
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
          "Unlock Ludo AI",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Watch a short ad to unlock playing Ludo against the computer!",
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
        title: const Text("Ludo Setup", style: TextStyle(color: Colors.white)),
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
              subtitle: UnlockService().isGameUnlocked(UnlockService.ludo) ? "Play against computer" : "Watch ad to unlock",
              icon: UnlockService().isGameUnlocked(UnlockService.ludo) ? Icons.computer : Icons.lock,
              onPressed: () {
                if (UnlockService().isGameUnlocked(UnlockService.ludo)) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LudoGame(mode: GameMode.humanVsAi, playerCount: 4),
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
              subtitle: "$_playerCount player local game",
              icon: Icons.people,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LudoGame(mode: GameMode.humanVsHuman, playerCount: _playerCount),
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
// LUDO LOGIC
// -----------------------------------------------------------------------------

enum LudoColor { red, blue, green, yellow }

class LudoPiece {
  final LudoColor color;
  int position; // 0-56 for main path, negative for home area
  bool isHome = false;

  LudoPiece(this.color) : position = _getStartPosition(color);

  static int _getStartPosition(LudoColor color) {
    switch (color) {
      case LudoColor.red: return -1;
      case LudoColor.blue: return -2;
      case LudoColor.green: return -3;
      case LudoColor.yellow: return -4;
    }
  }

  LudoPiece copy() => LudoPiece(color)..position = position..isHome = isHome;
}

class LudoProvider extends ChangeNotifier {
  static const int boardSize = 15; // 15x15 board
  static const int homeStretchStart = 50; // When pieces enter home stretch

  late List<LudoPiece> _pieces;
  LudoColor _currentPlayer = LudoColor.red;
  int _diceValue = 1;
  bool _canRollDice = true;
  bool _gameOver = false;
  LudoColor? _winner;
  Map<LudoColor, int> _homePieces = {};
  final GameMode _gameMode;
  final int _playerCount;

  List<LudoPiece> get pieces => _pieces;
  LudoColor get currentPlayer => _currentPlayer;
  int get diceValue => _diceValue;
  bool get canRollDice => _canRollDice;
  bool get gameOver => _gameOver;
  LudoColor? get winner => _winner;
  Map<LudoColor, int> get homePieces => _homePieces;
  GameMode get gameMode => _gameMode;

  LudoProvider({required GameMode mode, int playerCount = 4}) : _gameMode = mode, _playerCount = playerCount {
    _initializeGame();
  }

  void _initializeGame() {
    _pieces = [];
    _homePieces = {};

    List<LudoColor> activeColors = [];
    if (_playerCount >= 2) activeColors.addAll([LudoColor.red, LudoColor.blue]);
    if (_playerCount >= 3) activeColors.add(LudoColor.green);
    if (_playerCount >= 4) activeColors.add(LudoColor.yellow);

    for (LudoColor color in activeColors) {
      _homePieces[color] = 0;
      // Create 4 pieces for each active color
      for (int i = 0; i < 4; i++) {
        _pieces.add(LudoPiece(color));
      }
    }

    _currentPlayer = LudoColor.red;
    _diceValue = 1;
    _canRollDice = true;
    _gameOver = false;
    _winner = null;
  }

  void rollDice() {
    if (!_canRollDice || _gameOver) return;

    _diceValue = Random().nextInt(6) + 1;
    _canRollDice = false;

    // Check if player has any valid moves
    bool hasValidMoves = _hasValidMoves();
    if (!hasValidMoves) {
      // Skip turn if no valid moves
      _nextPlayer();
    }

    notifyListeners();
  }

  bool _hasValidMoves() {
    List<LudoPiece> playerPieces = _pieces.where((p) => p.color == _currentPlayer && !p.isHome).toList();

    for (LudoPiece piece in playerPieces) {
      if (_canMovePiece(piece, _diceValue)) {
        return true;
      }
    }
    return false;
  }

  bool _canMovePiece(LudoPiece piece, int steps) {
    if (piece.isHome) return false;

    int newPosition = piece.position + steps;

    // Can't move if it would land on own piece (unless in safe zones)
    if (newPosition >= 0 && newPosition < 52) { // Main board
      for (LudoPiece other in _pieces) {
        if (other != piece && other.position == newPosition && other.color == piece.color) {
          return false; // Can't land on own piece
        }
      }
    }

    // Home stretch logic
    if (piece.position < homeStretchStart && newPosition >= homeStretchStart) {
      int homeStretchPos = newPosition - homeStretchStart;
      if (homeStretchPos > 5) return false; // Can't go beyond home
    }

    return true;
  }

  void movePiece(LudoPiece piece) {
    if (_canRollDice || piece.color != _currentPlayer || !_canMovePiece(piece, _diceValue)) {
      return;
    }

    int oldPosition = piece.position;
    piece.position += _diceValue;

    // Handle home stretch
    if (piece.position >= homeStretchStart) {
      int homeStretchPos = piece.position - homeStretchStart;
      if (homeStretchPos >= 6) {
        piece.isHome = true;
        _homePieces[piece.color] = (_homePieces[piece.color] ?? 0) + 1;

        // Check win condition
        if (_homePieces[piece.color] == 4) {
          _gameOver = true;
          _winner = piece.color;
        }
      }
    }

    // Handle capturing
    if (piece.position >= 0 && piece.position < 52 && !piece.isHome) {
      for (LudoPiece other in _pieces) {
        if (other != piece && other.position == piece.position && other.color != piece.color) {
          // Send piece back to start
          other.position = LudoPiece._getStartPosition(other.color);
        }
      }
    }

    // Check if rolled a 6 (extra turn)
    if (_diceValue == 6) {
      _canRollDice = true;
    } else {
      _nextPlayer();
    }

    notifyListeners();
  }

  void _nextPlayer() {
    List<LudoColor> activeColors = [];
    if (_playerCount >= 2) activeColors.addAll([LudoColor.red, LudoColor.blue]);
    if (_playerCount >= 3) activeColors.add(LudoColor.green);
    if (_playerCount >= 4) activeColors.add(LudoColor.yellow);

    int currentIndex = activeColors.indexOf(_currentPlayer);
    int nextIndex = (currentIndex + 1) % activeColors.length;
    _currentPlayer = activeColors[nextIndex];
    _canRollDice = true;
  }

  void restart() {
    _initializeGame();
    notifyListeners();
  }

  // Get board position for a piece
  Point<int> getPieceBoardPosition(LudoPiece piece) {
    if (piece.isHome) {
      // Position in home area
      int homeIndex = _homePieces[piece.color] ?? 0;
      switch (piece.color) {
        case LudoColor.red:
          return Point(2 + homeIndex, 2);
        case LudoColor.blue:
          return Point(2, 12 - homeIndex);
        case LudoColor.green:
          return Point(12 - homeIndex, 12);
        case LudoColor.yellow:
          return Point(12, 2 + homeIndex);
      }
    }

    if (piece.position < 0) {
      // Starting position
      switch (piece.color) {
        case LudoColor.red:
          return Point(1, 1);
        case LudoColor.blue:
          return Point(1, 13);
        case LudoColor.green:
          return Point(13, 13);
        case LudoColor.yellow:
          return Point(13, 1);
      }
    }

    // Main board path
    int pos = piece.position % 52;
    if (pos < 13) return Point(6, 1 + pos);
    if (pos < 26) return Point(6 + (pos - 12), 13);
    if (pos < 39) return Point(13, 13 - (pos - 25));
    return Point(13 - (pos - 38), 1);
  }

  Color getPlayerColor(LudoColor color) {
    switch (color) {
      case LudoColor.red: return Colors.red;
      case LudoColor.blue: return Colors.blue;
      case LudoColor.green: return Colors.green;
      case LudoColor.yellow: return Colors.yellow;
    }
  }

  List<LudoPiece> getPlayerPieces(LudoColor color) {
    return _pieces.where((p) => p.color == color).toList();
  }

  bool isValidMove(LudoPiece piece) {
    return !_canRollDice && piece.color == _currentPlayer && _canMovePiece(piece, _diceValue);
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class LudoGame extends StatelessWidget {
  final GameMode mode;
  final int playerCount;

  const LudoGame({super.key, required this.mode, this.playerCount = 4});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LudoProvider(mode: mode, playerCount: playerCount),
      child: const _LudoGameContent(),
    );
  }
}

class _LudoGameContent extends StatelessWidget {
  const _LudoGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LudoProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Ludo", style: GoogleFonts.outfit()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.restart,
          ),
        ],
      ),
      body: Column(
        children: [
          // Game status
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Current: ${provider.currentPlayer.toString().split('.').last}",
                  style: GoogleFonts.outfit(color: provider.getPlayerColor(provider.currentPlayer), fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Dice: ${provider.diceValue}",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: provider.canRollDice ? provider.rollDice : null,
                  child: const Text("Roll Dice"),
                ),
              ],
            ),
          ),

          // Game board
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Board grid (simplified visualization)
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 15,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                          ),
                          itemCount: 225,
                          itemBuilder: (ctx, index) {
                            int row = index ~/ 15;
                            int col = index % 15;
                            return Container(
                              color: _getSquareColor(row, col),
                            );
                          },
                        ),

                        // Pieces
                        ...provider.pieces.map((piece) {
                          Point<int> pos = provider.getPieceBoardPosition(piece);
                          return Positioned(
                            left: pos.x * (MediaQuery.of(context).size.width / 15),
                            top: pos.y * (MediaQuery.of(context).size.width / 15),
                            child: GestureDetector(
                              onTap: provider.isValidMove(piece) ? () => provider.movePiece(piece) : null,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: provider.getPlayerColor(piece.color),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: provider.isValidMove(piece) ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 8,
                                    ),
                                  ] : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Home counters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: provider.homePieces.keys.map((color) {
                return Column(
                  children: [
                    Text(
                      "${color.toString().split('.').last}",
                      style: GoogleFonts.outfit(color: provider.getPlayerColor(color)),
                    ),
                    Text(
                      "Home: ${provider.homePieces[color]}/4",
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          if (provider.gameOver)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "${provider.winner?.toString().split('.').last} Wins!",
                style: GoogleFonts.outfit(
                  color: Colors.greenAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getSquareColor(int row, int col) {
    // Home areas
    if (row >= 0 && row <= 5 && col >= 0 && col <= 5) return Colors.red[200]!;
    if (row >= 0 && row <= 5 && col >= 9 && col <= 14) return Colors.blue[200]!;
    if (row >= 9 && row <= 14 && col >= 0 && col <= 5) return Colors.yellow[200]!;
    if (row >= 9 && row <= 14 && col >= 9 && col <= 14) return Colors.green[200]!;

    // Main path
    if (row == 7 && col >= 1 && col <= 13) return Colors.white.withOpacity(0.3);
    if (col == 7 && row >= 1 && row <= 13) return Colors.white.withOpacity(0.3);

    return Colors.green[700]!;
  }
}