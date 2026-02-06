import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// -----------------------------------------------------------------------------
// GAME LOGIC / MODEL
// -----------------------------------------------------------------------------

// LiquidLevel class removed (unused in MVP)

class LiquidSortProvider extends ChangeNotifier {
  List<List<int>> _tubes = [];
  final int _capacity = 4;
  int? _selectedTubeIndex;
  
  int _level = 1;
  int get level => _level;
  
  List<List<int>> get tubes => _tubes;
  int? get selectedTubeIndex => _selectedTubeIndex;

  LiquidSortProvider() {
    _startLevel(_level);
  }

  void _startLevel(int level) {
    // Basic generator for now.
    // Level 1: 3 tubes, 1 empty. 2 Colors.
    // Level 2: 4 tubes, 1 empty. 3 Colors.
    // ...
    int distinctColors = level + 1;
    if (distinctColors > 10) distinctColors = 10;
    
    int tubeCount = distinctColors + 2; // Always 2 empty tubes ideally for easier play
    
    _generateLevel(distinctColors, tubeCount);
    _selectedTubeIndex = null;
    notifyListeners();
  }

  void _generateLevel(int colorCount, int tubeCount) {
    List<List<int>> newTubes = List.generate(tubeCount, (_) => []);
    
    List<int> allSegments = [];
    for (int c = 0; c < colorCount; c++) {
      for (int i = 0; i < _capacity; i++) {
        allSegments.add(c);
      }
    }
    
    allSegments.shuffle(Random());
    
    // Fill tubes until segments run out. 
    // The last (tubeCount - colorCount) tubes should be empty essentially?
    // Actually we just fill the first 'colorCount' tubes? 
    // Wait, simple random fill:
    int filledTubesCount = colorCount;
    // We treat the "tubeCount" as total tubes available.
    // We have colorCount * capacity segments.
    // We must ensure we don't accidentally solve it or make it impossible (though random usually works for simple cases).
    
    // Better strategy for solvency: Start solved, perform random reverse moves.
    // But for MVP, let's just do random shuffle into N tubes.
    
    int currentTube = 0;
    for (int segment in allSegments) {
      if (newTubes[currentTube].length < _capacity) {
        newTubes[currentTube].add(segment);
      } else {
        currentTube++;
        if (currentTube < tubeCount) {
           newTubes[currentTube].add(segment);
        }
      }
    }
    
    _tubes = newTubes;
  }
  
  void restart() {
    _startLevel(_level);
  }

  void nextLevel() {
    _level++;
    _startLevel(_level);
  }

  void selectTube(int index) {
    if (_selectedTubeIndex == null) {
      // Select if not empty
      if (_tubes[index].isNotEmpty) {
        _selectedTubeIndex = index;
        notifyListeners();
      }
    } else {
      if (_selectedTubeIndex == index) {
        // Deselect
        _selectedTubeIndex = null;
        notifyListeners();
      } else {
        // Attempt move
        _attemptMove(_selectedTubeIndex!, index);
      }
    }
  }

  void _attemptMove(int fromIndex, int toIndex) {
    List<int> fromTube = _tubes[fromIndex];
    List<int> toTube = _tubes[toIndex];

    if (fromTube.isEmpty) {
      _selectedTubeIndex = null;
      notifyListeners();
      return;
    }

    // Rules:
    // 1. Destination tube must have space.
    // 2. Destination tube must be empty OR top color must match source top color.
    
    if (toTube.length < _capacity) {
      int colorToMove = fromTube.last;
      
      bool canMove = false;
      if (toTube.isEmpty) {
        canMove = true;
      } else {
        if (toTube.last == colorToMove) {
          canMove = true;
        }
      }

      if (canMove) {
        // Move ALL contiguous segments of same color? Usually yes.
        // Let's move one by one or chunk? Standard liquid sort moves 1 unit visually, 
        // but if there are multiple of same color on top of source and enough space in dest, it moves all.
        // Let's implement single unit move first for simplicity of animation/logic.
        
        // Actually, let's do the "move all that fit" logic for better UX.
        int countToMove = 0;
        for (int i = fromTube.length - 1; i >= 0; i--) {
          if (fromTube[i] == colorToMove) {
            countToMove++;
          } else {
            break;
          }
        }
        
        int spaceAvailable = _capacity - toTube.length;
        int actualMoveCount = min(countToMove, spaceAvailable);
        
        for(int i=0; i<actualMoveCount; i++) {
          toTube.add(fromTube.removeLast());
        }
      }
    }

    _selectedTubeIndex = null;
    notifyListeners();
    _checkWinCondition();
  }

  void _checkWinCondition() {
    // All tubes must be either full of SAME color or empty.
    bool won = true;
    for (var tube in _tubes) {
      if (tube.isEmpty) continue;
      if (tube.length != _capacity) {
        won = false;
        break;
      }
      int firstColor = tube.first;
      if (tube.any((c) => c != firstColor)) {
        won = false;
        break;
      }
    }
    
    if (won) {
      // Trigger win
      debugPrint("WON LEVEL $_level");
      // Could set a "won" state to show dialog
      // For now, auto next level after delay? Or just notify UI.
    }
  }
  
  bool get isLevelWon {
     for (var tube in _tubes) {
      if (tube.isEmpty) continue;
      if (tube.length != _capacity) return false;
      int firstColor = tube.first;
      if (tube.any((c) => c != firstColor)) return false;
    }
    return true;
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class LiquidSortGame extends StatelessWidget {
  const LiquidSortGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LiquidSortProvider(),
      child: const _LiquidSortGameContent(),
    );
  }
}

class _LiquidSortGameContent extends StatelessWidget {
  const _LiquidSortGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiquidSortProvider>();
    
    // Post-build callback for win dialog
    if (provider.isLevelWon) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         // Show simple dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
             backgroundColor: AppTheme.surface,
             title: const Text("Level Complete!", style: TextStyle(color: Colors.white)),
             content: const Text("Great job!", style: TextStyle(color: Colors.white70)),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.pop(ctx);
                   provider.nextLevel();
                 },
                 child: const Text("Next Level"),
               )
             ],
           ),
         );
       });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Level ${provider.level}", style: GoogleFonts.outfit()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.restart,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate tube width based on count
               final tubes = provider.tubes;
               int count = tubes.length;
               // max columns 4 or 5? If count > 5 wrap?
               // Let's use Wrap or Grid.
               
               double tubeWidth = 60;
               double tubeHeight = 200;
               
              return Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 40,
                children: List.generate(count, (index) {
                  return GestureDetector(
                    onTap: () => provider.selectTube(index),
                    child: _TubeWidget(
                      colors: tubes[index],
                      capacity: 4,
                      isSelected: provider.selectedTubeIndex == index,
                      width: tubeWidth,
                      height: tubeHeight,
                    ),
                  );
                }),
              );
            }
          ),
        ),
      ),
    );
  }
}

class _TubeWidget extends StatelessWidget {
  final List<int> colors;
  final int capacity;
  final bool isSelected;
  final double width;
  final double height;

  const _TubeWidget({
    required this.colors,
    required this.capacity,
    required this.isSelected,
    required this.width,
    required this.height,
  });

  Color _getColor(int index) {
    const palette = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
      Colors.limeAccent,
    ];
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    // If selected, move up slightly
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, isSelected ? -20 : 0, 0),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(4),
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Render segments
          for (int i = colors.length - 1; i >= 0; i--) 
             // Logic is bottom-up in list? "Add" appends to end -> Top.
             // So list order is [Bottom, ..., Top]
             // We need to render Top at top? 
             // Column renders Top -> Bottom.
             // So we reverse logic for Column display?
             // Actually, if list is [0, 1] -> 0 is bottom, 1 is top.
             // In Column, 1 should be above 0.
             // So we should iterate reversed? 
             // Wait, if 1 is top, it should be first in Column?
             // Yes.
             Container(
               height: (height - 10) / capacity, // rough calc
               width: double.infinity,
               decoration: BoxDecoration(
                 color: _getColor(colors[i]),
                 borderRadius: BorderRadius.vertical(
                   top: i == colors.length - 1 ? const Radius.circular(4) : Radius.zero,
                   bottom: i == 0 ? const Radius.circular(24) : Radius.zero, 
                   // Bottom of tube is rounded
                 ),
                ),
              ).animate().fadeIn(),
         ] as List<Widget>, // Correct order: Top index is first in Column (visually top)
      ),
    );
  }
}
