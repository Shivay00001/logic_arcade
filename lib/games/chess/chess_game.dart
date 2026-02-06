import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:logic_arcade/services/ads_service.dart';
import 'package:logic_arcade/services/unlock_service.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// CHESS MODES AND SETUP
// -----------------------------------------------------------------------------

enum GameMode { humanVsAi, humanVsHuman }

class ChessSetupScreen extends StatefulWidget {
  const ChessSetupScreen({super.key});

  @override
  State<ChessSetupScreen> createState() => _ChessSetupScreenState();
}

class _ChessSetupScreenState extends State<ChessSetupScreen> {
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _adsService.loadRewardedAd(() {
      UnlockService().unlockGame(UnlockService.chess);
      setState(() {});
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChessGame(mode: GameMode.humanVsAi),
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
          "Unlock Chess AI",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Watch a short ad to unlock playing Chess against the computer!",
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
        title: const Text("Chess Setup", style: TextStyle(color: Colors.white)),
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
              subtitle: UnlockService().isGameUnlocked(UnlockService.chess) ? "Play against computer" : "Watch ad to unlock",
              icon: UnlockService().isGameUnlocked(UnlockService.chess) ? Icons.computer : Icons.lock,
              onPressed: () {
                if (UnlockService().isGameUnlocked(UnlockService.chess)) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ChessGame(mode: GameMode.humanVsAi),
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
                  builder: (context) => ChessGame(mode: GameMode.humanVsHuman),
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
// CHESS LOGIC
// -----------------------------------------------------------------------------

enum PieceType { pawn, rook, knight, bishop, queen, king }
enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  bool hasMoved = false;

  ChessPiece(this.type, this.color);

  String get symbol {
    const symbols = {
      PieceType.pawn: '♟',
      PieceType.rook: '♜',
      PieceType.knight: '♞',
      PieceType.bishop: '♝',
      PieceType.queen: '♛',
      PieceType.king: '♚',
    };
    return symbols[type]!;
  }

  ChessPiece copy() {
    var piece = ChessPiece(type, color);
    piece.hasMoved = hasMoved;
    return piece;
  }
}

class ChessProvider extends ChangeNotifier {
  late List<List<ChessPiece?>> _board;
  late PieceColor _currentTurn;
  ChessPiece? _selectedPiece;
  int? _selectedRow, _selectedCol;
  bool _gameOver = false;
  String _gameStatus = 'White to move';
  bool _aiThinking = false;
  final GameMode _gameMode;

  List<List<ChessPiece?>> get board => _board;
  PieceColor get currentTurn => _currentTurn;
  ChessPiece? get selectedPiece => _selectedPiece;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  bool get gameOver => _gameOver;
  String get gameStatus => _gameStatus;
  bool get aiThinking => _aiThinking;
  GameMode get gameMode => _gameMode;

  ChessProvider({required GameMode mode}) : _gameMode = mode {
    _initializeBoard();
  }

  void _initializeBoard() {
    _board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));

    // Place pawns
    for (int i = 0; i < 8; i++) {
      _board[1][i] = ChessPiece(PieceType.pawn, PieceColor.black);
      _board[6][i] = ChessPiece(PieceType.pawn, PieceColor.white);
    }

    // Place other pieces
    final backRank = [PieceType.rook, PieceType.knight, PieceType.bishop, PieceType.queen,
                     PieceType.king, PieceType.bishop, PieceType.knight, PieceType.rook];

    for (int i = 0; i < 8; i++) {
      _board[0][i] = ChessPiece(backRank[i], PieceColor.black);
      _board[7][i] = ChessPiece(backRank[i], PieceColor.white);
    }

    _currentTurn = PieceColor.white;
    _selectedPiece = null;
    _selectedRow = null;
    _selectedCol = null;
    _gameOver = false;
    _gameStatus = 'White to move';
    _aiThinking = false;
  }

  void selectSquare(int row, int col) {
    if (_gameOver || _aiThinking) return;

    // If selecting own piece
    if (_board[row][col]?.color == _currentTurn) {
      _selectedPiece = _board[row][col];
      _selectedRow = row;
      _selectedCol = col;
      notifyListeners();
      return;
    }

    // If moving to empty square or capturing
    if (_selectedPiece != null && _selectedRow != null && _selectedCol != null) {
      if (_isValidMove(_selectedRow!, _selectedCol!, row, col)) {
        _makeMove(_selectedRow!, _selectedCol!, row, col);
        _selectedPiece = null;
        _selectedRow = null;
        _selectedCol = null;

        if (_currentTurn == PieceColor.black && _gameMode == GameMode.humanVsAi) {
          _makeAIMove();
        }
      } else {
        _selectedPiece = null;
        _selectedRow = null;
        _selectedCol = null;
      }
      notifyListeners();
    }
  }

  bool _isValidMove(int fromRow, int fromCol, int toRow, int toCol) {
    ChessPiece? piece = _board[fromRow][fromCol];
    if (piece == null) return false;

    // Can't capture own pieces
    if (_board[toRow][toCol]?.color == piece.color) return false;

    // Check piece-specific movement
    switch (piece.type) {
      case PieceType.pawn:
        return _isValidPawnMove(fromRow, fromCol, toRow, toCol, piece.color);
      case PieceType.rook:
        return _isValidRookMove(fromRow, fromCol, toRow, toCol);
      case PieceType.knight:
        return _isValidKnightMove(fromRow, fromCol, toRow, toCol);
      case PieceType.bishop:
        return _isValidBishopMove(fromRow, fromCol, toRow, toCol);
      case PieceType.queen:
        return _isValidQueenMove(fromRow, fromCol, toRow, toCol);
      case PieceType.king:
        return _isValidKingMove(fromRow, fromCol, toRow, toCol);
    }
  }

  bool _isValidPawnMove(int fromRow, int fromCol, int toRow, int toCol, PieceColor color) {
    int direction = color == PieceColor.white ? -1 : 1;
    int startRow = color == PieceColor.white ? 6 : 1;

    // Forward move
    if (fromCol == toCol && _board[toRow][toCol] == null) {
      if (toRow == fromRow + direction) return true;
      if (fromRow == startRow && toRow == fromRow + 2 * direction && _board[fromRow + direction][fromCol] == null) return true;
    }

    // Diagonal capture
    if ((toCol == fromCol - 1 || toCol == fromCol + 1) && toRow == fromRow + direction) {
      return _board[toRow][toCol] != null;
    }

    return false;
  }

  bool _isValidRookMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (fromRow != toRow && fromCol != toCol) return false;
    return _isPathClear(fromRow, fromCol, toRow, toCol);
  }

  bool _isValidKnightMove(int fromRow, int fromCol, int toRow, int toCol) {
    int rowDiff = (toRow - fromRow).abs();
    int colDiff = (toCol - fromCol).abs();
    return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2);
  }

  bool _isValidBishopMove(int fromRow, int fromCol, int toRow, int toCol) {
    if ((toRow - fromRow).abs() != (toCol - fromCol).abs()) return false;
    return _isPathClear(fromRow, fromCol, toRow, toCol);
  }

  bool _isValidQueenMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (fromRow == toRow || fromCol == toCol || (toRow - fromRow).abs() == (toCol - fromCol).abs()) {
      return _isPathClear(fromRow, fromCol, toRow, toCol);
    }
    return false;
  }

  bool _isValidKingMove(int fromRow, int fromCol, int toRow, int toCol) {
    int rowDiff = (toRow - fromRow).abs();
    int colDiff = (toCol - fromCol).abs();
    return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0);
  }

  bool _isPathClear(int fromRow, int fromCol, int toRow, int toCol) {
    int rowStep = toRow > fromRow ? 1 : toRow < fromRow ? -1 : 0;
    int colStep = toCol > fromCol ? 1 : toCol < fromCol ? -1 : 0;

    int currentRow = fromRow + rowStep;
    int currentCol = fromCol + colStep;

    while (currentRow != toRow || currentCol != toCol) {
      if (_board[currentRow][currentCol] != null) return false;
      currentRow += rowStep;
      currentCol += colStep;
    }

    return true;
  }

  void _makeMove(int fromRow, int fromCol, int toRow, int toCol) {
    ChessPiece? piece = _board[fromRow][fromCol];
    if (piece == null) return;

    // Move piece
    _board[toRow][toCol] = piece.copy();
    _board[toRow][toCol]!.hasMoved = true;
    _board[fromRow][fromCol] = null;

    // Switch turns
    _currentTurn = _currentTurn == PieceColor.white ? PieceColor.black : PieceColor.white;
    _updateGameStatus();

    // Check for checkmate
    if (_isInCheck(_currentTurn)) {
      if (_isCheckmate(_currentTurn)) {
        _gameOver = true;
        _gameStatus = '${_currentTurn == PieceColor.white ? "Black" : "White"} wins by checkmate!';
      } else {
        _gameStatus += ' - Check!';
      }
    }
  }

  bool _isInCheck(PieceColor color) {
    // Find king position
    int kingRow = -1, kingCol = -1;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (_board[row][col]?.type == PieceType.king && _board[row][col]?.color == color) {
          kingRow = row;
          kingCol = col;
          break;
        }
      }
      if (kingRow != -1) break;
    }

    if (kingRow == -1) return false;

    // Check if any opponent piece can attack the king
    PieceColor opponent = color == PieceColor.white ? PieceColor.black : PieceColor.white;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (_board[row][col]?.color == opponent) {
          if (_isValidMove(row, col, kingRow, kingCol)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _isCheckmate(PieceColor color) {
    // Check if any move can get out of check
    for (int fromRow = 0; fromRow < 8; fromRow++) {
      for (int fromCol = 0; fromCol < 8; fromCol++) {
        if (_board[fromRow][fromCol]?.color == color) {
          for (int toRow = 0; toRow < 8; toRow++) {
            for (int toCol = 0; toCol < 8; toCol++) {
              if (_isValidMove(fromRow, fromCol, toRow, toCol)) {
                // Try the move
                ChessPiece? capturedPiece = _board[toRow][toCol];
                _board[toRow][toCol] = _board[fromRow][fromCol];
                _board[fromRow][fromCol] = null;

                bool stillInCheck = _isInCheck(color);

                // Undo the move
                _board[fromRow][fromCol] = _board[toRow][toCol];
                _board[toRow][toCol] = capturedPiece;

                if (!stillInCheck) return false;
              }
            }
          }
        }
      }
    }
    return true;
  }

  void _makeAIMove() {
    if (_gameOver) return;

    _aiThinking = true;
    notifyListeners();

    // Simple AI: make random valid move
    Future.delayed(const Duration(seconds: 1), () {
      List<List<int>> validMoves = [];

      for (int fromRow = 0; fromRow < 8; fromRow++) {
        for (int fromCol = 0; fromCol < 8; fromCol++) {
          if (_board[fromRow][fromCol]?.color == _currentTurn) {
            for (int toRow = 0; toRow < 8; toRow++) {
              for (int toCol = 0; toCol < 8; toCol++) {
                if (_isValidMove(fromRow, fromCol, toRow, toCol)) {
                  validMoves.add([fromRow, fromCol, toRow, toCol]);
                }
              }
            }
          }
        }
      }

      if (validMoves.isNotEmpty) {
        List<int> move = validMoves[Random().nextInt(validMoves.length)];
        _makeMove(move[0], move[1], move[2], move[3]);
      }

      _aiThinking = false;
      notifyListeners();
    });
  }

  void _updateGameStatus() {
    if (_gameMode == GameMode.humanVsAi) {
      _gameStatus = _currentTurn == PieceColor.white ? 'White to move' : 'Black to move (AI)';
    } else {
      _gameStatus = _currentTurn == PieceColor.white ? 'White to move' : 'Black to move';
    }
  }

  void restart() {
    _initializeBoard();
    notifyListeners();
  }

  bool isSquareSelected(int row, int col) {
    return _selectedRow == row && _selectedCol == col;
  }

  bool isValidMoveTarget(int row, int col) {
    return _selectedRow != null && _selectedCol != null &&
           _isValidMove(_selectedRow!, _selectedCol!, row, col);
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class ChessGame extends StatelessWidget {
  final GameMode mode;

  const ChessGame({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChessProvider(mode: mode),
      child: const _ChessGameContent(),
    );
  }
}

class _ChessGameContent extends StatelessWidget {
  const _ChessGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChessProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Chess", style: GoogleFonts.outfit()),
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
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                      ),
                      itemCount: 64,
                      itemBuilder: (ctx, index) {
                        int row = index ~/ 8;
                        int col = index % 8;
                        return _ChessSquare(
                          row: row,
                          col: col,
                          piece: provider.board[row][col],
                          isSelected: provider.isSquareSelected(row, col),
                          isValidTarget: provider.isValidMoveTarget(row, col),
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
                  "Tap pieces to select, tap squares to move.\nPlay as White against AI.",
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

class _ChessSquare extends StatelessWidget {
  final int row, col;
  final ChessPiece? piece;
  final bool isSelected;
  final bool isValidTarget;
  final VoidCallback onTap;

  const _ChessSquare({
    required this.row,
    required this.col,
    required this.piece,
    required this.isSelected,
    required this.isValidTarget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isLight = (row + col) % 2 == 0;
    Color squareColor = isLight ? Colors.white : Colors.grey[400]!;

    if (isSelected) {
      squareColor = AppTheme.primary.withOpacity(0.7);
    } else if (isValidTarget) {
      squareColor = AppTheme.secondary.withOpacity(0.7);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: squareColor,
        child: Center(
          child: piece != null ? Text(
            piece!.symbol,
            style: TextStyle(
              fontSize: 32,
              color: piece!.color == PieceColor.white ? Colors.white : Colors.black,
            ),
          ) : null,
        ),
      ),
    );
  }
}