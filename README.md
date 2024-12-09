# Infinity Runner

An endless runner game inspired by Jetpack Joyride, built with SpriteKit for iOS. Navigate through obstacles, collect coins, and see how far you can go!

## Features

### Core Mechanics
- [x] Jetpack-based vertical movement
- [x] Continuous horizontal scrolling
- [x] Dynamic obstacle spawning
- [x] Coin collection system
- [x] Score tracking based on distance
- [x] High score persistence
- [x] Collision detection and game over state
- [x] Particle effects for jetpack
- [x] Beautiful starfield background

### User Interface
- [x] Main menu with title and "Tap to Play"
- [x] In-game HUD with score and coins
- [x] Pause menu with resume and main menu options
- [x] Game over screen with final score
- [x] High score display
- [ ] Settings menu for sound/music control
- [ ] Tutorial overlay for new players

### Planned Features
- [ ] Power-ups (shields, magnets, speed boosts)
- [ ] Character customization
- [ ] Different environments/themes
- [ ] Achievement system
- [ ] Daily challenges
- [ ] Social features (leaderboards)
- [ ] Sound effects and background music
- [ ] More obstacle types
- [ ] Shop system for upgrades
- [ ] Cloud save support

## Requirements
- iOS 14.0+
- Xcode 13.0+
- Swift 5.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/infinity-runner.git
```

2. Open the project in Xcode:
```bash
cd infinity-runner
open "Infinity Runner.xcodeproj"
```

3. Select your target device and press Run (⌘R)

## How to Play

1. Tap and hold anywhere on the screen to activate the jetpack
2. Release to fall
3. Avoid obstacles and collect coins
4. Try to beat your high score!

## Technical Details

### Architecture
- Built with SpriteKit framework
- Scene management for different game states
- Physics-based collision detection
- Particle systems for visual effects
- UserDefaults for local data persistence

### Performance Optimizations
- Node recycling for obstacles and coins
- Efficient particle system management
- Optimized texture atlases
- Smart node culling when off-screen

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by Jetpack Joyride
- Built with SpriteKit
- Particle effects designed in Xcode
- Special thanks to the iOS game development community

## Development Roadmap

### Short Term (1-2 months)
- [ ] Add sound effects and background music
- [ ] Implement basic power-ups
- [ ] Add more obstacle types
- [ ] Create basic tutorial

### Medium Term (3-6 months)
- [ ] Character customization system
- [ ] Shop implementation
- [ ] Achievement system
- [ ] Different game modes

### Long Term (6+ months)
- [ ] Online leaderboards
- [ ] Daily challenges
- [ ] Multiple environments
- [ ] Social features
- [ ] Cloud save support

---

Made with ❤️ using SpriteKit
