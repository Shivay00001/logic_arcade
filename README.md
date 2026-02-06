# Logic Arcade

A simple but unique and addictive gaming app built with Flutter, featuring multiple logical puzzle games designed to challenge your mind and provide endless entertainment.

## 🎮 Games Included

### Liquid Sort
- **Description**: Sort colorful liquids by pouring them between tubes
- **Objective**: Arrange each color in separate tubes by moving liquid segments
- **Difficulty**: Progressive levels with increasing complexity

### Tile Logic (2048)
- **Description**: Classic 2048 sliding number puzzle
- **Objective**: Combine tiles with the same numbers to reach 2048
- **Features**: Swipe controls, score tracking, and best score persistence

### Color Flood
- **Description**: Flood the entire board with one color
- **Objective**: Change the top-left color to spread and flood connected tiles
- **Features**: Progressive levels, move counter, and visual flood progress

### Bubble Pop
- **Description**: Pop bubbles of the same color when connected
- **Objective**: Clear the board by popping groups of 2+ connected bubbles
- **Features**: Endless mode, score-based gameplay, and satisfying animations

### Snake
- **Description**: Classic snake game with modern twists
- **Objective**: Guide the snake to eat food and grow without hitting walls or yourself
- **Features**: WASD/Arrow key controls, increasing speed, and score tracking

### Chess
- **Description**: Strategic chess game against AI
- **Objective**: Checkmate the AI opponent using classic chess rules
- **Features**: Full chess rules, piece movement validation, check/checkmate detection

### Checkers
- **Description**: Classic checkers with jumping mechanics
- **Objective**: Capture all opponent pieces or block their movement
- **Features**: Mandatory jumps, king promotion, AI opponent

### Minesweeper
- **Description**: Logic puzzle with hidden mines
- **Objective**: Reveal all safe cells without detonating mines
- **Features**: Number hints, flagging system, timer, win/lose conditions

### Connect Four
- **Description**: Drop pieces to get four in a row
- **Objective**: Connect four pieces horizontally, vertically, or diagonally
- **Features**: Gravity-based gameplay, strategic AI opponent, win detection

### Ludo
- **Description**: Classic board game with dice rolling
- **Objective**: Move all pieces around the board and into home
- **Features**: 4-player colors, dice mechanics, AI opponents, king promotion

### Bubble Shot
- **Description**: Physics-based bubble shooting game
- **Objective**: Shoot bubbles to create groups of 3+ same color
- **Features**: Aim and shoot mechanics, gravity physics, score system

### Colour Calculator
- **Description**: Math problems solved with colored visual aids
- **Objective**: Solve equations by counting colored circles
- **Features**: Visual math learning, timed challenges, progressive difficulty

### Gully Fighting
- **Description**: Action game of finding weapons and eliminating enemies
- **Objective**: Find the gun, then eliminate all enemies before they find you
- **Features**: Grid-based movement, strategic positioning, turn-based combat

### Block Puzzle
- **Description**: Tetris-style falling block game
- **Objective**: Arrange falling blocks to clear complete lines
- **Features**: Classic Tetris mechanics, line clearing, increasing speed

### Sliding Puzzle
- **Description**: Arrange numbers 1-15 in order
- **Objective**: Slide tiles to arrange them in numerical order
- **Features**: Move counter and visual feedback for movable tiles

## 🚀 Features

- **Beautiful Dark Theme**: Modern UI with smooth animations
- **Cross-Platform**: Built with Flutter for iOS, Android, and desktop
- **Ad-Supported**: Integrated Google Mobile Ads for monetization
- **Offline Play**: All games work without internet connection
- **Progressive Difficulty**: Games get harder as you advance
- **Intuitive Controls**: Touch and keyboard support

## 🛠️ Technical Stack

- **Framework**: Flutter
- **State Management**: Provider
- **UI**: Material Design 3 with custom theming
- **Fonts**: Google Fonts (Outfit)
- **Animations**: Flutter Animate
- **Ads**: Google Mobile Ads SDK

## 📱 Screenshots

*(Add screenshots of your app here)*

## 🎯 Game Collection

Logic Arcade now features **13 unique games** across multiple genres:

### 🧩 **Puzzle Games**
- **Liquid Sort** - Color sorting logic puzzle
- **Tile Logic (2048)** - Number merging strategy
- **Sliding Puzzle** - Number arrangement challenge
- **Minesweeper** - Logic minefield navigation
- **Colour Calculator** - Visual math learning

### 🎲 **Board Games**
- **Chess** - Strategic chess mastery with AI
- **Checkers** - Classic jumping strategy
- **Ludo** - Dice-rolling board adventure
- **Connect Four** - Drop-to-win strategy

### 🎮 **Action Games**
- **Snake** - Classic arcade survival
- **Block Puzzle** - Tetris-style falling blocks
- **Bubble Shot** - Physics-based bubble shooter
- **Gully Fighting** - Action strategy combat

### 🧠 **Learning Games**
- **Colour Calculator** - Math through visual patterns
- **Sliding Puzzle** - Spatial reasoning
- **Minesweeper** - Logic and probability

## 🏃‍♂️ Getting Started

### Prerequisites
- Flutter SDK (3.10.3 or higher)
- Dart SDK (included with Flutter)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/logic_arcade.git
cd logic_arcade
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

```bash
# For Android APK
flutter build apk --release

# For iOS
flutter build ios --release

# For Windows
flutter build windows --release
```

## 📊 Game Rules

### Liquid Sort Rules
1. Pour liquid between tubes by tapping on them
2. You can only pour onto empty tubes or tubes where the top color matches
3. Complete a level when each tube contains only one color or is empty

### 2048 Rules
1. Swipe in any direction to move tiles
2. Tiles with the same number merge when they collide
3. Reach the 2048 tile to win (but keep playing for higher scores!)

### Sudoku Rules
1. Fill each row, column, and 3x3 box with numbers 1-9
2. Each number can only appear once per row, column, and box
3. Use notes to track possible numbers for each cell

### Sliding Puzzle Rules
1. Slide tiles horizontally or vertically into the empty space
2. Arrange numbers 1-15 in ascending order
3. The empty space should end up in the bottom-right corner

## 🎯 Architecture

```
lib/
├── core/           # Theme and core utilities
├── games/          # Individual game implementations
│   ├── liquid_sort/
│   ├── tile/
│   ├── sudoku/
│   └── sliding_puzzle/
├── screens/        # App screens (main menu, etc.)
├── services/       # Ads and other services
└── main.dart       # App entry point
```

## 📈 Monetization

The app is designed to be ad-supported with banner ads displayed at the bottom of the main menu. For production use:

1. Replace test ad unit IDs with your own from Google AdMob
2. Configure ad units for different platforms (Android/iOS)
3. Test ads thoroughly before release

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Game design inspiration from classic puzzle games
- Material Design for UI inspiration
