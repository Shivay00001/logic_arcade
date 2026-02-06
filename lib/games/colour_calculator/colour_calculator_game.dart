import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

// -----------------------------------------------------------------------------
// COLOUR CALCULATOR LOGIC
// -----------------------------------------------------------------------------

class ColourCalculatorProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _problems = [];
  int _currentProblemIndex = 0;
  int _score = 0;
  bool _gameOver = false;
  int _timeLeft = 60; // 60 seconds per level
  Timer? _timer;

  List<Map<String, dynamic>> get problems => _problems;
  int get currentProblemIndex => _currentProblemIndex;
  int get score => _score;
  bool get gameOver => _gameOver;
  int get timeLeft => _timeLeft;

  Map<String, dynamic>? get currentProblem => _currentProblemIndex < _problems.length ? _problems[_currentProblemIndex] : null;

  ColourCalculatorProvider() {
    _generateProblems();
    _startTimer();
  }

  void _generateProblems() {
    _problems = [];
    Random random = Random();

    for (int i = 0; i < 10; i++) {
      int a = random.nextInt(5) + 1;
      int b = random.nextInt(5) + 1;
      int operation = random.nextInt(3); // 0: +, 1: -, 2: *

      int result;
      String op;
      switch (operation) {
        case 0:
          result = a + b;
          op = '+';
          break;
        case 1:
          result = a - b;
          op = '-';
          // Ensure positive result
          if (result < 0) {
            result = b - a;
            op = '-';
          }
          break;
        case 2:
          result = a * b;
          op = '×';
          break;
        default:
          result = a + b;
          op = '+';
      }

      _problems.add({
        'a': a,
        'b': b,
        'operation': op,
        'result': result,
        'options': _generateOptions(result),
      });
    }
  }

  List<int> _generateOptions(int correctAnswer) {
    List<int> options = [correctAnswer];
    Random random = Random();

    while (options.length < 4) {
      int option = correctAnswer + random.nextInt(9) - 4;
      if (option > 0 && !options.contains(option)) {
        options.add(option);
      }
    }

    options.shuffle();
    return options;
  }

  void selectAnswer(int answer) {
    if (_gameOver || currentProblem == null) return;

    if (answer == currentProblem!['result']) {
      _score += 10;
    }

    _currentProblemIndex++;

    if (_currentProblemIndex >= _problems.length) {
      _gameOver = true;
      _timer?.cancel();
    }

    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeft--;
      if (_timeLeft <= 0) {
        _gameOver = true;
        _timer?.cancel();
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  void restart() {
    _currentProblemIndex = 0;
    _score = 0;
    _gameOver = false;
    _timeLeft = 60;
    _generateProblems();
    _timer?.cancel();
    _startTimer();
    notifyListeners();
  }

  Color getColorForNumber(int number) {
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[number % colors.length];
  }

  Widget buildNumberVisual(int number, {double size = 30}) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(number, (index) =>
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: getColorForNumber(index % 10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

class ColourCalculatorGame extends StatelessWidget {
  const ColourCalculatorGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ColourCalculatorProvider(),
      child: const _ColourCalculatorGameContent(),
    );
  }
}

class _ColourCalculatorGameContent extends StatelessWidget {
  const _ColourCalculatorGameContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ColourCalculatorProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Colour Calculator", style: GoogleFonts.outfit()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "Score: ${provider.score} | Time: ${provider.timeLeft}s",
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
      body: provider.currentProblem != null ? Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: provider.currentProblemIndex / provider.problems.length,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),

          // Problem display
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Visual equation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First number
                        provider.buildNumberVisual(provider.currentProblem!['a'], size: 40),

                        // Operation
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            provider.currentProblem!['operation'],
                            style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.text),
                          ),
                        ),

                        // Second number
                        provider.buildNumberVisual(provider.currentProblem!['b'], size: 40),

                        // Equals
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '=',
                            style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.text),
                          ),
                        ),

                        // Question mark
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary, width: 2),
                          ),
                          child: const Center(
                            child: Text('?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Answer options
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: provider.currentProblem!['options'].map<Widget>((option) =>
                        GestureDetector(
                          onTap: () => provider.selectAnswer(option),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                provider.buildNumberVisual(option, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  '$option',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Look at the colored circles and solve the equation!\nEach circle represents 1.",
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ) : const Center(
        child: Text("Loading..."),
      ),
    );
  }
}