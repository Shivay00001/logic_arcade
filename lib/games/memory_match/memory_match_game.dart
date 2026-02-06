import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class MemoryMatchGame extends StatelessWidget {
  const MemoryMatchGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemoryMatchProvider(),
      child: const _MemoryMatchContent(),
    );
  }
}

class CardModel {
  final int id;
  final IconData icon;
  bool isFaceUp;
  bool isMatched;

  CardModel({
    required this.id,
    required this.icon,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

class MemoryMatchProvider extends ChangeNotifier {
  List<CardModel> _cards = [];
  CardModel? _firstSelected;
  bool _isProcessing = false;
  int _moves = 0;
  
  List<CardModel> get cards => _cards;
  int get moves => _moves;
  bool get isGameOver => _cards.every((c) => c.isMatched);

  static const List<IconData> _icons = [
    Icons.ac_unit,
    Icons.access_alarm,
    Icons.accessibility_new,
    Icons.adb,
    Icons.add_a_photo,
    Icons.airport_shuttle,
    Icons.attractions,
    Icons.audiotrack,
  ];

  MemoryMatchProvider() {
    _startNewGame();
  }

  void _startNewGame() {
    List<CardModel> pairs = [];
    for (int i = 0; i < 8; i++) { // 8 pairs = 16 cards
      pairs.add(CardModel(id: i * 2, icon: _icons[i]));
      pairs.add(CardModel(id: i * 2 + 1, icon: _icons[i]));
    }
    pairs.shuffle(Random());
    _cards = pairs;
    _firstSelected = null;
    _isProcessing = false;
    _moves = 0;
    notifyListeners();
  }
  
  void restart() => _startNewGame();

  void onCardTap(CardModel card) async {
    if (_isProcessing || card.isFaceUp || card.isMatched) return;

    card.isFaceUp = true;
    notifyListeners();

    if (_firstSelected == null) {
      _firstSelected = card;
    } else {
      _moves++;
      _isProcessing = true;
      if (_firstSelected!.icon == card.icon) {
        // Match
        _firstSelected!.isMatched = true;
        card.isMatched = true;
        _firstSelected = null;
        _isProcessing = false;
        notifyListeners();
      } else {
        // No match
        await Future.delayed(const Duration(milliseconds: 800));
        _firstSelected!.isFaceUp = false;
        card.isFaceUp = false;
        _firstSelected = null;
        _isProcessing = false;
        notifyListeners();
      }
    }
  }
}

class _MemoryMatchContent extends StatelessWidget {
  const _MemoryMatchContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryMatchProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("Memory Match", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.restart,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Moves: ${provider.moves}", style: GoogleFonts.outfit(fontSize: 20, color: AppTheme.textSecondary)),
                if (provider.isGameOver)
                  Text("COMPLETE!", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accent)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: provider.cards.length,
              itemBuilder: (context, index) {
                final card = provider.cards[index];
                return GestureDetector(
                  onTap: () => provider.onCardTap(card),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                    decoration: BoxDecoration(
                      color: card.isFaceUp || card.isMatched ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: card.isMatched ? AppTheme.accent : Colors.transparent, 
                        width: 2
                      ),
                    ),
                    alignment: Alignment.center,
                    child: (card.isFaceUp || card.isMatched)
                        ? Icon(card.icon, size: 32, color: Colors.white).animate().fadeIn()
                        : Icon(Icons.question_mark_rounded, color: AppTheme.textSecondary.withOpacity(0.3)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
