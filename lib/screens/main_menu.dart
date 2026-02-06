import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logic_arcade/core/theme.dart';
import 'package:logic_arcade/services/ads_service.dart';

// Placeholders for game screens - we will implement these later or stub them now
// to avoid compile errors, I will create simple placeholders inside this file for now
// and move them later, OR just navigate to named routes that I will define in main.dart.
class LiquidSortScreenPlaceholder extends StatelessWidget {
  const LiquidSortScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Liquid Sort")));
}

class TileGameScreenPlaceholder extends StatelessWidget {
  const TileGameScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Tile Logic")));
}


class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _adsService.loadBanner((ad) => setState(() {}));
    _adsService.loadTopLeftBanner((ad) => setState(() {}));
    _adsService.loadNativeAd((ad) => setState(() {}));
  }

  @override
  void dispose() {
    _adsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: _adsService.getTopLeftBannerAdWidget(),
            ),
            const Gap(32),
            Text(
              "LOGIC\nARCADE",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 0.9,
                color: AppTheme.text,
                shadows: [
                  Shadow(
                    color: AppTheme.primary.withOpacity(0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
            const Gap(48),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _GameCard(
                    title: "Liquid Sort",
                    subtitle: "Sort colors logic puzzle",
                    icon: Icons.water_drop_outlined,
                    color: AppTheme.primary,
                    delay: 200,
                    onTap: () => Navigator.pushNamed(context, '/liquid_sort'),
                  ),
                  const Gap(16),
                   _GameCard(
                     title: "Tile Logic",
                     subtitle: "Sliding numbers puzzle",
                     icon: Icons.grid_view_rounded,
                     color: AppTheme.secondary,
                     delay: 400,
                     onTap: () => Navigator.pushNamed(context, '/tile_game'),
                   ),
                   const Gap(16),
                    _GameCard(
                     title: "Tic-Tac-Toe",
                     subtitle: "2-4 Players",
                     icon: Icons.close,
                     color: AppTheme.accent,
                     delay: 500,
                    onTap: () => Navigator.pushNamed(context, '/tic_tac_toe'),
                    ),
                   const Gap(16),
                   // Native Ad
                   _adsService.getNativeAdWidget(),
                   const Gap(16),
                   const Gap(16),
                    _GameCard(
                      title: "Dot Arrow Connect",
                      subtitle: "Connect colored dots!",
                      icon: Icons.timeline,
                      color: Colors.cyanAccent,
                      delay: 3000,
                      onTap: () => Navigator.pushNamed(context, '/dot_arrow_connect'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Candy Crush",
                      subtitle: "Match-3 fun!",
                      icon: Icons.grid_3x3,
                      color: Colors.pinkAccent,
                      delay: 3200,
                      onTap: () => Navigator.pushNamed(context, '/candy_crush'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Angry Birds",
                      subtitle: "Physics slingshot!",
                      icon: Icons.sports_baseball,
                      color: Colors.orangeAccent,
                      delay: 3400,
                      onTap: () => Navigator.pushNamed(context, '/angry_birds'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Unscrew Nuts",
                      subtitle: "Match & unscrew!",
                      icon: Icons.build,
                      color: Colors.blueGrey,
                      delay: 3600,
                      onTap: () => Navigator.pushNamed(context, '/unscrew_nuts'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "More Coming Soon",
                      subtitle: "Stay tuned!",
                      icon: Icons.update,
                      color: AppTheme.textSecondary,
                      delay: 3800,
                      onTap: () {},
                      isLocked: true,
                    ),
                    const Gap(16),
                   _GameCard(
                     title: "Sliding Puzzle",
                     subtitle: "Arrange the numbers",
                     icon: Icons.extension_outlined,
                     color: AppTheme.secondary,
                     delay: 600,
                     onTap: () => Navigator.pushNamed(context, '/sliding_puzzle'),
                   ),
                    const Gap(16),
                     _GameCard(
                       title: "Ludo",
                       subtitle: "2-4 Players",
                       icon: Icons.casino,
                       color: AppTheme.primary,
                       delay: 800,
                       onTap: () => Navigator.pushNamed(context, '/ludo'),
                     ),
                     const Gap(16),
                    _GameCard(
                      title: "Bubble Shot",
                      subtitle: "Aim and shoot!",
                      icon: Icons.adjust,
                      color: AppTheme.secondary,
                      delay: 1000,
                      onTap: () => Navigator.pushNamed(context, '/bubble_shot'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Snake",
                      subtitle: "Classic arcade fun!",
                      icon: Icons.play_arrow,
                      color: AppTheme.secondary,
                      delay: 1200,
                      onTap: () => Navigator.pushNamed(context, '/snake'),
                    ),
                     const Gap(16),
                     _GameCard(
                       title: "Carrom",
                       subtitle: "2-4 Players",
                       icon: Icons.sports_soccer,
                       color: Colors.greenAccent,
                       delay: 1400,
                       onTap: () => Navigator.pushNamed(context, '/carrom'),
                     ),
                     const Gap(16),
                    _GameCard(
                      title: "Chess",
                      subtitle: "Strategic mastery!",
                      icon: Icons.castle,
                      color: AppTheme.accent,
                      delay: 1600,
                      onTap: () => Navigator.pushNamed(context, '/chess'),
                    ),
                    const Gap(16),
                   _GameCard(
                     title: "Checkers",
                     subtitle: "Jump to victory!",
                     icon: Icons.grid_on,
                     color: AppTheme.primary,
                     delay: 1600,
                     onTap: () => Navigator.pushNamed(context, '/checkers'),
                   ),
                    const Gap(16),
                   _GameCard(
                     title: "Minesweeper",
                     subtitle: "Minefield logic!",
                     icon: Icons.flag,
                     color: AppTheme.secondary,
                     delay: 1800,
                     onTap: () => Navigator.pushNamed(context, '/minesweeper'),
                   ),
                    const Gap(16),
                    _GameCard(
                      title: "Connect Four",
                      subtitle: "Drop to win!",
                      icon: Icons.call_received,
                      color: AppTheme.accent,
                      delay: 2000,
                      onTap: () => Navigator.pushNamed(context, '/connect_four'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Colour Calculator",
                      subtitle: "2+2=4 in colours!",
                      icon: Icons.calculate,
                      color: Colors.orangeAccent,
                      delay: 2200,
                      onTap: () => Navigator.pushNamed(context, '/colour_calculator'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Gully Fighting",
                      subtitle: "Find gun, kill enemy!",
                      icon: Icons.gavel,
                      color: Colors.redAccent,
                      delay: 2400,
                      onTap: () => Navigator.pushNamed(context, '/gully_fighting'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Block Puzzle",
                      subtitle: "Fit the pieces!",
                      icon: Icons.extension,
                      color: Colors.purpleAccent,
                      delay: 2600,
                      onTap: () => Navigator.pushNamed(context, '/block_puzzle'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "Gully Fighting",
                      subtitle: "Find gun, eliminate!",
                      icon: Icons.gavel,
                      color: Colors.redAccent,
                      delay: 2800,
                      onTap: () => Navigator.pushNamed(context, '/gully_fighting'),
                    ),
                     const Gap(16),
                    _GameCard(
                      title: "More Coming Soon",
                      subtitle: "Stay tuned!",
                      icon: Icons.update,
                      color: AppTheme.textSecondary,
                      delay: 3000,
                      onTap: () {},
                      isLocked: true,
                    ),
                    const Gap(16),
                   _GameCard(
                     title: "More Games",
                     subtitle: "Coming Soon...",
                     icon: Icons.sports_esports_outlined,
                     color: AppTheme.textSecondary,
                     delay: 1000,
                     onTap: () {},
                     isLocked: true,
                   ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8),
              child: _adsService.getBannerAdWidget(),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "Made with ❤️ by Shivakriti in India",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  final bool isLocked;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.delay = 0,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Gap(24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Gap(20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? AppTheme.textSecondary : AppTheme.text,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
              ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(delay: delay.ms, duration: 600.ms)
    .slideX(begin: 0.2, end: 0, delay: delay.ms, curve: Curves.easeOut);
  }
}
