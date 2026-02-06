import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:logic_arcade/services/ads_service.dart';
import 'package:logic_arcade/services/unlock_service.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// CHECKERS MODES AND SETUP
// -----------------------------------------------------------------------------

enum GameMode { humanVsAi, humanVsHuman }

class CheckersSetupScreen extends StatefulWidget {
  const CheckersSetupScreen({super.key});

  @override
  State<CheckersSetupScreen> createState() => _CheckersSetupScreenState();
}

class _CheckersSetupScreenState extends State<CheckersSetupScreen> {
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _adsService.loadRewardedAd(() {
      UnlockService().unlockGame(UnlockService.checkers);
      setState(() {});
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CheckersGame(mode: GameMode.humanVsAi),
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
          "Unlock Checkers AI",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Watch a short ad to unlock playing Checkers against the computer!",
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
        title: const Text("Checkers Setup", style: TextStyle(color: Colors.white)),
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
            _ModeButton(
              title: "Human vs AI",
              subtitle: UnlockService().isGameUnlocked(UnlockService.checkers) ? "Play against computer" : "Watch ad to unlock",
              icon: UnlockService().isGameUnlocked(UnlockService.checkers) ? Icons.computer : Icons.lock,
              onPressed: () {
                if (UnlockService().isGameUnlocked(UnlockService.checkers)) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => CheckersGame(mode: GameMode.humanVsAi),
                    ),
                  );
                } else {
                  _showUnlockDialog(context);
                }
              },
            ),
            const SizedBox(height: 30),
            _ModeButton(
              title: "Human vs Human",
              subtitle: "Two player local game",
              icon: Icons.people,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CheckersGame(mode: GameMode.humanVsHuman),
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
// CHECKERS LOGIC
// -----------------------------------------------------------------------------

enum CheckerColor { red, black }
enum PieceType2 { regular, king }

class CheckerPiece {
  final CheckerColor color;
  PieceType2 type;

  CheckerPiece(this.color, [this.type = PieceType2.regular]);

  String get symbol {
    if (type == PieceType2.king) {
      return color == CheckerColor.red ? '♔' : '♚';
    }
    return color == CheckerColor.red ? '♟' : '♙';
  }

  CheckerPiece copy() => CheckerPiece(color, type);
}

class CheckersProvider extends ChangeNotifier {
  static const int boardSize = 8;
  late List<List<CheckerPiece?>> _board;
  CheckerColor _currentTurn = CheckerColor.red;
  CheckerPiece? _selectedPiece;
  int? _selectedRow, _selectedCol;
  bool _gameOver = false;
  String _gameStatus = 'Red to move';
  bool _aiThinking = false;
  List<List<int>>? _possibleMoves;
  final GameMode _gameMode;

  List<List<CheckerPiece?>> get board => _board;
  CheckerColor get currentTurn => _currentTurn;
  CheckerPiece? get selectedPiece => _selectedPiece;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  bool get gameOver => _gameOver;
  String get gameStatus => _gameStatus;
  bool get aiThinking => _aiThinking;
  List<List<int>>? get possibleMoves => _possibleMoves;
  GameMode get gameMode => _gameMode;

  CheckersProvider({GameMode mode = GameMode.humanVsAi}) : _gameMode = mode {
    _initializeBoard();
  }

  void _initializeBoard() {
    _board = List.generate(boardSize, (_) => List<CheckerPiece?>.filled(boardSize, null));

    // Place red pieces (top 3 rows)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < boardSize; col++) {
        if ((row + col) % 2 == 1) {
          _board[row][col] = CheckerPiece(CheckerColor.red);
        }
      }
    }

    // Place black pieces (bottom 3 rows)
    for (int row = 5; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if ((row + col) % 2 == 1) {
          _board[row][col] = CheckerPiece(CheckerColor.black);
        }
      }
    }

    _currentTurn = CheckerColor.red;
    _selectedPiece = null;
    _selectedRow = null;
    _selectedCol = null;
    _gameOver = false;
    _gameStatus = 'Red to move';
    _aiThinking = false;
    _possibleMoves = null;
  }

  void selectSquare(int row, int col) {
    if (_gameOver || _aiThinking) return;

    // Only select on dark squares
    if ((row + col) % 2 == 0) return;

    // If selecting own piece
    if (_board[row][col]?.color == _currentTurn) {
      _selectedPiece = _board[row][col];
      _selectedRow = row;
      _selectedCol = col;
      _possibleMoves = _getPossibleMoves(row, col);
      notifyListeners();
      return;
    }

    // If moving to empty square
    if (_selectedPiece != null && _selectedRow != null && _selectedCol != null) {
      if (_isValidMove(_selectedRow!, _selectedCol!, row, col)) {
        _makeMove(_selectedRow!, _selectedCol!, row, col);
        _selectedPiece = null;
        _selectedRow = null;
        _selectedCol = null;
        _possibleMoves = null;

        if (_currentTurn == CheckerColor.black) {
          _makeAIMove();
        }
      } else {
        _selectedPiece = null;
        _selectedRow = null;
        _selectedCol = null;
        _possibleMoves = null;
      }
      notifyListeners();
    }
  }

  List<List<int>> _getPossibleMoves(int row, int col) {
    List<List<int>> moves = [];
    CheckerPiece? piece = _board[row][col];
    if (piece == null) return moves;

    int direction = piece.color == CheckerColor.red ? 1 : -1;

    // Regular moves
    if (piece.type == PieceType2.regular) {
      // Forward diagonals
      for (int dCol = -1; dCol <= 1; dCol += 2) {
        int newRow = row + direction;
        int newCol = col + dCol;
        if (_isValidSquare(newRow, newCol) && _board[newRow][newCol] == null) {
          moves.add([newRow, newCol]);
        }
      }
    } else {
      // King moves - all 4 diagonals
      for (int dRow = -1; dRow <= 1; dRow += 2) {
        for (int dCol = -1; dCol <= 1; dCol += 2) {
          int newRow = row + dRow;
          int newCol = col + dCol;
          if (_isValidSquare(newRow, newCol) && _board[newRow][newCol] == null) {
            moves.add([newRow, newCol]);
          }
        }
      }
    }

    // Jump moves (mandatory if available)
    List<List<int>> jumps = _getJumpMoves(row, col);
    if (jumps.isNotEmpty) {
      return jumps; // Only return jumps if available
    }

    return moves;
  }

  List<List<int>> _getJumpMoves(int row, int col) {
    List<List<int>> jumps = [];
    CheckerPiece? piece = _board[row][col];
    if (piece == null) return jumps;

    int direction = piece.color == CheckerColor.red ? 1 : -1;
    CheckerColor opponent = piece.color == CheckerColor.red ? CheckerColor.black : CheckerColor.red;

    // Check all possible jump directions
    List<List<int>> directions = [];
    if (piece.type == PieceType2.regular) {
      directions = [[direction, -1], [direction, 1]];
    } else {
      directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
    }

    for (List<int> dir in directions) {
      int jumpRow = row + dir[0];
      int jumpCol = col + dir[1];
      int landRow = row + 2 * dir[0];
      int landCol = col + 2 * dir[1];

      if (_isValidSquare(jumpRow, jumpCol) && _isValidSquare(landRow, landCol) &&
          _board[jumpRow][jumpCol]?.color == opponent &&
          _board[landRow][landCol] == null) {
        jumps.add([landRow, landCol]);
      }
    }

    return jumps;
  }

  bool _isValidMove(int fromRow, int fromCol, int toRow, int toCol) {
    // Must be diagonal move
    int rowDiff = (toRow - fromRow).abs();
    int colDiff = (toCol - fromCol).abs();

    if (rowDiff != colDiff || rowDiff == 0) return false;

    // Check if it's a jump
    if (rowDiff == 2) {
      int jumpedRow = fromRow + (toRow - fromRow) ~/ 2;
      int jumpedCol = fromCol + (toCol - fromCol) ~/ 2;
      CheckerPiece? jumpedPiece = _board[jumpedRow][jumpedCol];
      if (jumpedPiece == null || jumpedPiece.color == _board[fromRow][fromCol]?.color) {
        return false;
      }
    } else if (rowDiff != 1) {
      return false;
    }

    return true;
  }

  void _makeMove(int fromRow, int fromCol, int toRow, int toCol) {
    CheckerPiece? piece = _board[fromRow][fromCol];
    if (piece == null) return;

    // Handle jumping
    int rowDiff = (toRow - fromRow).abs();
    if (rowDiff == 2) {
      int jumpedRow = fromRow + (toRow - fromRow) ~/ 2;
      int jumpedCol = fromCol + (toCol - fromCol) ~/ 2;
      _board[jumpedRow][jumpedCol] = null; // Remove jumped piece
    }

    // Move piece
    _board[toRow][toCol] = piece.copy();
    _board[fromRow][fromCol] = null;

    // Check for king promotion
    if (piece.type == PieceType2.regular) {
      if ((piece.color == CheckerColor.red && toRow == boardSize - 1) ||
          (piece.color == CheckerColor.black && toRow == 0)) {
        _board[toRow][toCol]!.type = PieceType2.king;
      }
    }

    // Switch turns
    _currentTurn = _currentTurn == CheckerColor.red ? CheckerColor.black : CheckerColor.red;
    _updateGameStatus();

    // Check for game over
    if (_getAllPossibleMoves().isEmpty) {
      _gameOver = true;
      _gameStatus = '${_currentTurn == CheckerColor.red ? "Black" : "Red"} wins!';
      return;
    }

    // AI move for human vs AI mode
    if (_gameMode == GameMode.humanVsAi && _currentTurn == CheckerColor.black) {
      _makeAIMove();
    }
  }

  List<List<List<int>>> _getAllPossibleMoves() {
    List<List<List<int>>> allMoves = [];

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (_board[row][col]?.color == _currentTurn) {
          List<List<int>> moves = _getPossibleMoves(row, col);
          if (moves.isNotEmpty) {
            allMoves.add([[row, col], ...moves]);
          }
        }
      }
    }

    return allMoves;
  }

  void _makeAIMove() {
    if (_gameOver) return;

    _aiThinking = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      List<List<List<int>>> possibleMoves = _getAllPossibleMoves();

      if (possibleMoves.isNotEmpty) {
        List<List<int>> move = possibleMoves[Random().nextInt(possibleMoves.length)];
        int fromRow = move[0][0];
        int fromCol = move[0][1];
        int toRow = move[1][0];
        int toCol = move[1][1];

        _makeMove(fromRow, fromCol, toRow, toCol);
      }

      _aiThinking = false;
      notifyListeners();
    });
  }

  void _updateGameStatus() {
    if (_gameMode == GameMode.humanVsAi) {
      _gameStatus = _currentTurn == CheckerColor.red ? 'Red to move' : 'Black to move (AI)';
    } else {
      _gameStatus = _currentTurn == CheckerColor.red ? 'Red to move' : 'Black to move';
    }
  }

  bool _isValidSquare(int row, int col) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  void restart() {
    _initializeBoard();
    notifyListeners();
  }

  bool isSquareSelected(int row, int col) {
    return _selectedRow == row && _selectedCol == col;
  }

  bool isPossibleMove(int row, int col) {
    if (_possibleMoves == null) return false;
    return _possibleMoves!.any((move) => move[0] == row && move[1] == col);
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class CheckersGame extends StatelessWidget {
  final GameMode mode;

  const CheckersGame({super.key, this.mode = GameMode.humanVsAi});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckersProvider(mode: mode),
      child: const _CheckersGameContent(),
    );
  }
}

class _CheckersGameContent extends StatelessWidget {
  const _CheckersGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckersProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Checkers", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                provider.gameStatus,
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
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                      ),
                      itemCount: 64,
                      itemBuilder: (ctx, index) {
                        int row = index ~/ 8;
                        int col = index % 8;
                        return _CheckerSquare(
                          row: row,
                          col: col,
                          piece: provider.board[row][col],
                          isSelected: provider.isSquareSelected(row, col),
                          isPossibleMove: provider.isPossibleMove(row, col),
                          onTap: () => provider.selectSquare(row, col),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Status and controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (provider.aiThinking)
                  const CircularProgressIndicator(),
                if (provider.gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      provider.gameStatus,
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  "Tap pieces to select, tap highlighted squares to move.\nJump over opponent pieces when possible.\nReach the opposite end to become a king!",
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

class _CheckerSquare extends StatelessWidget {
  final int row, col;
  final CheckerPiece? piece;
  final bool isSelected;
  final bool isPossibleMove;
  final VoidCallback onTap;

  const _CheckerSquare({
    required this.row,
    required this.col,
    required this.piece,
    required this.isSelected,
    required this.isPossibleMove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkSquare = (row + col) % 2 == 1;

    Color squareColor;
    if (isSelected) {
      squareColor = AppTheme.primary.withOpacity(0.8);
    } else if (isPossibleMove) {
      squareColor = AppTheme.secondary.withOpacity(0.8);
    } else {
      squareColor = isDarkSquare ? Colors.brown[300]! : Colors.brown[100]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: squareColor,
        child: Center(
          child: piece != null ? Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: piece!.color == CheckerColor.red ? Colors.red : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                piece!.symbol,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ) : null,
        ),
      ),
    );
  }
}