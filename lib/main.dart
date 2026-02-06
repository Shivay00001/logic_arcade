import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:logic_arcade/screens/main_menu.dart';
import 'package:logic_arcade/services/ads_service.dart';
import 'package:logic_arcade/services/unlock_service.dart';

import 'package:logic_arcade/games/liquid_sort/liquid_sort_game.dart';
import 'package:logic_arcade/games/tile/tile_game.dart';
import 'package:logic_arcade/games/tic_tac_toe/tic_tac_toe_game.dart';
import 'package:logic_arcade/games/memory_match/memory_match_game.dart';
import 'package:logic_arcade/games/sliding_puzzle/sliding_puzzle_game.dart';
import 'package:logic_arcade/games/ludo/ludo_game.dart';
import 'package:logic_arcade/games/bubble_shot/bubble_shot_game.dart';
import 'package:logic_arcade/games/colour_calculator/colour_calculator_game.dart';
import 'package:logic_arcade/games/block_puzzle/block_puzzle_game.dart';
import 'package:logic_arcade/games/gully_fighting/gully_fighting_game.dart';
import 'package:logic_arcade/games/dot_arrow_connect/dot_arrow_connect_game.dart';
import 'package:logic_arcade/games/candy_crush/candy_crush_game.dart';
import 'package:logic_arcade/games/angry_birds/angry_birds_game.dart';
import 'package:logic_arcade/games/unscrew_nuts/unscrew_nuts_game.dart';
import 'package:logic_arcade/games/snake/snake_game.dart';
import 'package:logic_arcade/games/chess/chess_game.dart';
import 'package:logic_arcade/games/checkers/checkers_game.dart';

import 'package:logic_arcade/games/carrom/carrom_game.dart';
import 'package:logic_arcade/games/minesweeper/minesweeper_game.dart';
import 'package:logic_arcade/games/connect_four/connect_four_game.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
   // Initialize Ads
   AdsService().initialize();

   // Initialize Unlock Service
   await UnlockService().initialize();

  runApp(const LogicArcadeApp());
}

class LogicArcadeApp extends StatelessWidget {
  const LogicArcadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logic Arcade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenuScreen(),
        // We will enable these routes as we build the files
        '/liquid_sort': (context) => const LiquidSortGame(),
        '/tile_game': (context) => const TileGame(),
        '/tic_tac_toe': (context) => const TicTacToeSetupScreen(),
        '/memory_match': (context) => const MemoryMatchGame(),
        '/sliding_puzzle': (context) => const SlidingPuzzleGame(),
        '/ludo': (context) => const LudoSetupScreen(),
        '/bubble_shot': (context) => const BubbleShotGame(),
        '/colour_calculator': (context) => const ColourCalculatorGame(),
        '/block_puzzle': (context) => const BlockPuzzleGame(),
        '/gully_fighting': (context) => const GullyFightingGame(),
        '/dot_arrow_connect': (context) => const DotArrowConnectGame(),
        '/candy_crush': (context) => const CandyCrushGame(),
        '/angry_birds': (context) => const AngryBirdsGame(),
        '/unscrew_nuts': (context) => const UnscrewNutsGame(),
        '/snake': (context) => const SnakeGame(),
        '/chess': (context) => const ChessSetupScreen(),
        '/checkers': (context) => const CheckersSetupScreen(),
        '/minesweeper': (context) => const MinesweeperGame(),
        '/connect_four': (context) => const ConnectFourGame(),
        '/carrom': (context) => const CarromSetupScreen(),
      },
    );
  }
}
