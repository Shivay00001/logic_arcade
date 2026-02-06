import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:logic_arcade/services/ads_service.dart';
import 'package:logic_arcade/services/unlock_service.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------------------------
// TIC TAC TOE MODES AND SETUP
// -----------------------------------------------------------------------------

enum GameMode { humanVsAi, humanVsHuman }

class TicTacToeSetupScreen extends StatefulWidget {
  const TicTacToeSetupScreen({super.key});

  @override
  State<TicTacToeSetupScreen> createState() => _TicTacToeSetupScreenState();
}

class _TicTacToeSetupScreenState extends State<TicTacToeSetupScreen> {
  int _playerCount = 2;
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _adsService.loadRewardedAd(() {
      UnlockService().unlockGame(UnlockService.ticTacToe);
      setState(() {});
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TicTacToeGame(mode: GameMode.humanVsAi, playerCount: 2),
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
          "Unlock Tic-Tac-Toe AI",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Watch a short ad to unlock playing Tic-Tac-Toe against the computer!",
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
        title: const Text("Tic Tac Toe Setup", style: TextStyle(color: Colors.white)),
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
              subtitle: UnlockService().isGameUnlocked(UnlockService.ticTacToe) ? "Play against computer" : "Watch ad to unlock",
              icon: UnlockService().isGameUnlocked(UnlockService.ticTacToe) ? Icons.computer : Icons.lock,
              onPressed: () {
                if (UnlockService().isGameUnlocked(UnlockService.ticTacToe)) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => TicTacToeGame(mode: GameMode.humanVsAi, playerCount: 2),
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
                  builder: (context) => TicTacToeGame(mode: GameMode.humanVsHuman, playerCount: _playerCount),
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

class TicTacToeGame extends StatelessWidget {
  final GameMode mode;
  final int playerCount;

  const TicTacToeGame({super.key, required this.mode, this.playerCount = 2});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TicTacToeProvider(mode: mode, playerCount: playerCount),
      child: const _TicTacToeContent(),
    );
  }
}

class TicTacToeProvider extends ChangeNotifier {
  List<String> _board = List.filled(9, '');
  int _currentPlayerIndex = 0;
  String _winner = '';
  List<int> _winningLine = [];
  bool _isDraw = false;
  final GameMode _gameMode;
  final int _playerCount;
  final List<String> _playerSymbols = ['X', 'O', '△', '□'];

  List<String> get board => _board;
  int get currentPlayerIndex => _currentPlayerIndex;
  String get currentPlayerSymbol => _playerSymbols[_currentPlayerIndex % _playerSymbols.length];
  String get winner => _winner;
  List<int> get winningLine => _winningLine;
  bool get isDraw => _isDraw;
  bool get gameOver => _winner.isNotEmpty || _isDraw;
  GameMode get gameMode => _gameMode;
  int get playerCount => _playerCount;

  TicTacToeProvider({required GameMode mode, int playerCount = 2})
      : _gameMode = mode,
        _playerCount = playerCount;

  void handleTap(int index) {
    if (_board[index].isNotEmpty || _winner.isNotEmpty || _isDraw) return;

    _board[index] = currentPlayerSymbol;
    _checkWin();

    if (_winner.isEmpty && !_board.contains('')) {
      _isDraw = true;
    }

    if (_winner.isEmpty && !_isDraw) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _playerCount;

      // AI move if in Human vs AI mode and it's AI's turn (AI is player 1)
      if (_gameMode == GameMode.humanVsAi && _currentPlayerIndex == 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _makeAIMove();
        });
      }
    }

    notifyListeners();
  }

  void _checkWin() {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (var pattern in winPatterns) {
      if (_board[pattern[0]].isNotEmpty &&
          _board[pattern[0]] == _board[pattern[1]] &&
          _board[pattern[0]] == _board[pattern[2]]) {
        _winner = _board[pattern[0]];
        _winningLine = pattern;
        return;
      }
    }
  }

  void _makeAIMove() {
    if (gameOver) return;

    // Simple AI: try to win, block opponents, or take center/corners
    int bestMove = _findBestMove();
    if (bestMove != -1) {
      handleTap(bestMove);
    }
  }

  int _findBestMove() {
    String aiSymbol = _playerSymbols[1]; // AI is always player 1

    // 1. Try to win
    for (int i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        _board[i] = aiSymbol;
        if (_checkWinForPlayer(aiSymbol)) {
          _board[i] = '';
          return i;
        }
        _board[i] = '';
      }
    }

    // 2. Try to block any opponent
    for (int opponent = 0; opponent < _playerCount; opponent++) {
      if (opponent != 1) { // Don't block self
        String opponentSymbol = _playerSymbols[opponent];
        for (int i = 0; i < 9; i++) {
          if (_board[i].isEmpty) {
            _board[i] = opponentSymbol;
            if (_checkWinForPlayer(opponentSymbol)) {
              _board[i] = '';
              return i;
            }
            _board[i] = '';
          }
        }
      }
    }

    // 3. Take center if available
    if (_board[4].isEmpty) return 4;

    // 4. Take corners
    List<int> corners = [0, 2, 6, 8];
    for (int corner in corners) {
      if (_board[corner].isEmpty) return corner;
    }

    // 5. Take any available spot
    for (int i = 0; i < 9; i++) {
      if (_board[i].isEmpty) return i;
    }

    return -1; // No moves available
  }

  bool _checkWinForPlayer(String player) {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (var pattern in winPatterns) {
      if (_board[pattern[0]] == player &&
          _board[pattern[1]] == player &&
          _board[pattern[2]] == player) {
        return true;
      }
    }
    return false;
  }

  void reset() {
    _board = List.filled(9, '');
    _currentPlayerIndex = 0;
    _winner = '';
    _winningLine = [];
    _isDraw = false;
    notifyListeners();
  }
}

class _TicTacToeContent extends StatelessWidget {
  const _TicTacToeContent();

  Color _getPlayerColor(String mark) {
    switch (mark) {
      case 'X': return AppTheme.primary;
      case 'O': return AppTheme.secondary;
      case '△': return Colors.green;
      case '□': return Colors.purple;
      default: return AppTheme.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicTacToeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("Tic-Tac-Toe", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.reset,
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            provider.gameOver
                ? (provider.isDraw ? "It's a Draw!" : "Player ${provider.winner} Wins!")
                : "Player ${provider.currentPlayerIndex + 1} (${provider.currentPlayerSymbol})'s Turn",
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: provider.gameOver ? AppTheme.accent : AppTheme.text,
            ),
          ).animate(target: provider.gameOver ? 1 : 0).scale(),
          
          const SizedBox(height: 48),

          AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final mark = provider.board[index];
                  final isWinningCell = provider.winningLine.contains(index);
                  
                  return GestureDetector(
                    onTap: () => provider.handleTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isWinningCell 
                           ? AppTheme.accent.withOpacity(0.2) 
                           : AppTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: isWinningCell 
                           ? Border.all(color: AppTheme.accent, width: 2)
                           : null,
                      ),
                      alignment: Alignment.center,
                        child: Text(
                          mark,
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: _getPlayerColor(mark),
                          ),
                        ).animate(target: mark.isNotEmpty ? 1 : 0).scale(duration: 200.ms),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
