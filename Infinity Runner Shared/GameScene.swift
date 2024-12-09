import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game states
    private enum GameState {
        case menu
        case playing
        case paused
        case gameOver
    }
    
    // Game nodes
    private var player: SKSpriteNode!
    private var jetpackParticles: SKEmitterNode?
    private var starfieldNode: SKEmitterNode?
    private var ground: SKSpriteNode!
    private var ceiling: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var coinLabel: SKLabelNode!
    private var highScoreLabel: SKLabelNode!
    private var menuNode: SKNode!
    private var pauseButton: SKSpriteNode!
    private var worldNode: SKNode!
    
    // Game state
    private var gameState: GameState = .menu
    private var score = 0
    private var coins = 0
    private var highScore = UserDefaults.standard.integer(forKey: "HighScore")
    private var isGameOver = false
    private var isJetpackActive = false
    private var gameSpeed: CGFloat = 400.0
    private var lastUpdateTime: TimeInterval = 0
    private var distance: CGFloat = 0
    private var currentPowerUp: PowerUpType?
    private var powerUpTimeRemaining: TimeInterval = 0
    
    // Power-up types
    private enum PowerUpType: String, CaseIterable {
        case shield = "🛡️"
        case speedBoost = "⚡️"
        case magnet = "🧲"
        case miniSize = "🔍"
        
        var duration: TimeInterval {
            switch self {
            case .shield: return 5.0
            case .speedBoost: return 3.0
            case .magnet: return 7.0
            case .miniSize: return 5.0
            }
        }
    }
    
    // Physics categories
    private let playerCategory: UInt32 = 0x1 << 0
    private let obstacleCategory: UInt32 = 0x1 << 1
    private let coinCategory: UInt32 = 0x1 << 2
    private let groundCategory: UInt32 = 0x1 << 3
    private let ceilingCategory: UInt32 = 0x1 << 4
    private let powerUpCategory: UInt32 = 0x1 << 5
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        showMainMenu()
    }
    
    private func showMainMenu() {
        removeAllChildren()
        gameState = .menu
        
        setupBackground()
        
        menuNode = SKNode()
        addChild(menuNode)
        
        // Game Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "INFINITY RUNNER"
        titleLabel.fontSize = 44
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        menuNode.addChild(titleLabel)
        
        // High Score
        highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highScoreLabel.text = "High Score: \(highScore)"
        highScoreLabel.fontSize = 24
        highScoreLabel.position = CGPoint(x: size.width/2, y: size.height * 0.6)
        menuNode.addChild(highScoreLabel)
        
        // Play Button
        let playButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playButton.text = "TAP TO PLAY"
        playButton.fontSize = 32
        playButton.name = "playButton"
        playButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        menuNode.addChild(playButton)
    }
    
    private func setupGame() {
        removeAllChildren()
        gameState = .playing
        
        // Reset game state
        isGameOver = false
        score = 0
        coins = 0
        distance = 0
        gameSpeed = 400.0
        lastUpdateTime = 0
        
        // Create world node first
        worldNode = SKNode()
        addChild(worldNode)
        
        setupBackground()
        setupPlayer()
        setupBoundaries()
        setupHUD()
        startSpawning()
    }
    
    private func setupBackground() {
        // Set pitch black background
        backgroundColor = .black
        
        // Create starfield effect
        if let starfield = SKEmitterNode(fileNamed: "StarfieldParticle") {
            starfield.position = CGPoint(x: size.width, y: size.height/2)
            starfield.particlePositionRange = CGVector(dx: size.height, dy: size.height)
            starfield.particleBirthRate = 20
            starfield.particleLifetime = 4.0
            starfield.particleSpeed = 150
            starfield.particleSpeedRange = 50
            starfield.particleAlpha = 0.8
            starfield.particleAlphaRange = 0.2
            starfield.particleScale = 0.3
            starfield.particleScaleRange = 0.2
            starfield.emissionAngle = .pi
            starfield.particleColor = .white
            starfield.zPosition = -1
            worldNode.addChild(starfield)
            starfieldNode = starfield
        }
    }
    
    private func setupPlayer() {
        // Create player sprite with better visuals
        let playerSize = CGSize(width: 40, height: 40)
        player = SKSpriteNode(color: .cyan, size: playerSize)
        player.position = CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        
        // Add visual effects
        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
        glow.addChild(SKSpriteNode(color: .cyan, size: CGSize(width: playerSize.width + 4, height: playerSize.height + 4)))
        player.addChild(glow)
        
        // Setup physics
        player.physicsBody = SKPhysicsBody(rectangleOf: playerSize)
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.collisionBitMask = groundCategory | ceilingCategory
        player.physicsBody?.contactTestBitMask = obstacleCategory | coinCategory | powerUpCategory
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 2.0
        player.physicsBody?.mass = 0.2
        player.zPosition = 10
        
        worldNode.addChild(player)
        setupJetpack()
    }
    
    private func setupJetpack() {
        if let particles = SKEmitterNode(fileNamed: "JetpackParticle") {
            jetpackParticles = particles
            jetpackParticles?.position = CGPoint(x: -20, y: 0)
            jetpackParticles?.targetNode = self
            jetpackParticles?.particleBirthRate = 0
            player.addChild(jetpackParticles!)
        }
    }
    
    private func setupBoundaries() {
        // Ground
        ground = SKSpriteNode(color: .gray, size: CGSize(width: size.width, height: 20))
        ground.position = CGPoint(x: size.width/2, y: 20)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = groundCategory
        worldNode.addChild(ground)
        
        // Ceiling
        ceiling = SKSpriteNode(color: .gray, size: CGSize(width: size.width, height: 20))
        ceiling.position = CGPoint(x: size.width/2, y: size.height - 20)
        ceiling.physicsBody = SKPhysicsBody(rectangleOf: ceiling.size)
        ceiling.physicsBody?.isDynamic = false
        ceiling.physicsBody?.categoryBitMask = ceilingCategory
        worldNode.addChild(ceiling)
    }
    
    private func setupHUD() {
        let hudNode = SKNode()
        addChild(hudNode)
        
        // Score label with background
        let scoreBg = SKShapeNode(rectOf: CGSize(width: 150, height: 30), cornerRadius: 8)
        scoreBg.fillColor = SKColor.black.withAlphaComponent(0.5)
        scoreBg.strokeColor = .white
        scoreBg.position = CGPoint(x: size.width - 85, y: size.height - 35)
        hudNode.addChild(scoreBg)
        
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.position = CGPoint(x: size.width - 85, y: size.height - 44)
        hudNode.addChild(scoreLabel)
        
        // Coin label with background
        let coinBg = SKShapeNode(rectOf: CGSize(width: 150, height: 30), cornerRadius: 8)
        coinBg.fillColor = SKColor.black.withAlphaComponent(0.5)
        coinBg.strokeColor = .white
        coinBg.position = CGPoint(x: size.width - 85, y: size.height - 75)
        hudNode.addChild(coinBg)
        
        coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.text = "Coins: 0"
        coinLabel.fontSize = 20
        coinLabel.position = CGPoint(x: size.width - 85, y: size.height - 84)
        hudNode.addChild(coinLabel)
        
        // Pause button
        pauseButton = SKSpriteNode(imageNamed: "pause")
        pauseButton.size = CGSize(width: 30, height: 30)
        pauseButton.position = CGPoint(x: 40, y: size.height - 40)
        pauseButton.name = "pauseButton"
        hudNode.addChild(pauseButton)
    }
    
    private func startSpawning() {
        // Spawn obstacles with increasing difficulty
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnRandomObstacle()
                },
                SKAction.wait(forDuration: 1.5)
            ])
        ))
        
        // Spawn coins in patterns
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnCoinPattern()
                },
                SKAction.wait(forDuration: 2.0)
            ])
        ))
        
        // Spawn power-ups less frequently
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnPowerUp()
                },
                SKAction.wait(forDuration: 15.0)
            ])
        ))
    }
    
    private func spawnRandomObstacle() {
        let randomType = Int.random(in: 0...1)
        switch randomType {
        case 0:
            spawnCone()
        case 1:
            spawnLaser()
        default:
            break
        }
    }
    
    private func spawnCone() {
        let cone = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 40))
        cone.position = CGPoint(x: size.width + cone.size.width/2,
                              y: CGFloat.random(in: ground.frame.maxY + cone.size.height...ceiling.frame.minY - cone.size.height))
        
        cone.physicsBody = SKPhysicsBody(rectangleOf: cone.size)
        cone.physicsBody?.isDynamic = false
        cone.physicsBody?.categoryBitMask = obstacleCategory
        cone.physicsBody?.contactTestBitMask = playerCategory
        cone.name = "obstacle"
        
        // Add slower rotation (4 seconds per rotation)
        let rotationDirection = Bool.random() ? 1.0 : -1.0
        let rotateAction = SKAction.rotate(byAngle: .pi * 2 * rotationDirection, duration: 4.0)
        let repeatRotation = SKAction.repeatForever(rotateAction)
        cone.run(repeatRotation)
        
        worldNode.addChild(cone)
        
        let moveLeft = SKAction.moveBy(x: -(size.width + cone.size.width), y: 0, duration: 4.0)
        let remove = SKAction.removeFromParent()
        cone.run(SKAction.sequence([moveLeft, remove]))
    }
    
    private func spawnLaser() {
        let laserHeight = CGFloat.random(in: size.height * 0.2...size.height * 0.4)
        let laser = SKSpriteNode(color: .red, size: CGSize(width: 10, height: laserHeight))
        laser.position = CGPoint(x: size.width + laser.size.width/2,
                               y: CGFloat.random(in: ground.frame.maxY + laserHeight/2...ceiling.frame.minY - laserHeight/2))
        
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.isDynamic = false
        laser.physicsBody?.categoryBitMask = obstacleCategory
        laser.physicsBody?.contactTestBitMask = playerCategory
        laser.name = "obstacle"
        
        // Add slower rotation (4 seconds per rotation)
        let rotationDirection = Bool.random() ? 1.0 : -1.0
        let rotateAction = SKAction.rotate(byAngle: .pi * 2 * rotationDirection, duration: 4.0)
        let repeatRotation = SKAction.repeatForever(rotateAction)
        laser.run(repeatRotation)
        
        worldNode.addChild(laser)
        
        let moveLeft = SKAction.moveBy(x: -(size.width + laser.size.width), y: 0, duration: 3.0)
        let remove = SKAction.removeFromParent()
        laser.run(SKAction.sequence([moveLeft, remove]))
    }
    
    private func spawnCoinPattern() {
        let patterns = [
            spawnCoinLine,
            spawnCoinArc,
            spawnCoinZigzag
        ]
        
        let randomPattern = patterns.randomElement()
        randomPattern?()
    }
    
    private func spawnCoinLine() {
        let coinCount = 10
        let spacing: CGFloat = 30
        let randomY = CGFloat.random(in: ground.frame.maxY + 50...ceiling.frame.minY - 50)
        
        for i in 0..<coinCount {
            let coin = createCoin()
            coin.position = CGPoint(x: size.width + CGFloat(i) * spacing,
                                  y: randomY)
            worldNode.addChild(coin)
            
            let moveAction = SKAction.moveBy(x: -(size.width + CGFloat(coinCount) * spacing),
                                           y: 0,
                                           duration: 3.0)
            let removeAction = SKAction.removeFromParent()
            coin.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    
    private func spawnCoinArc() {
        let coinCount = 12
        let radius: CGFloat = 100
        let randomY = CGFloat.random(in: ground.frame.maxY + radius...ceiling.frame.minY - radius)
        
        for i in 0..<coinCount {
            let angle = CGFloat(i) * .pi / CGFloat(coinCount - 1)
            let coin = createCoin()
            coin.position = CGPoint(x: size.width + radius * cos(angle),
                                  y: randomY + radius * sin(angle))
            worldNode.addChild(coin)
            
            let moveAction = SKAction.moveBy(x: -(size.width + radius * 2),
                                           y: 0,
                                           duration: 3.0)
            let removeAction = SKAction.removeFromParent()
            coin.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    
    private func spawnCoinZigzag() {
        let coinCount = 15
        let spacing: CGFloat = 30
        let amplitude: CGFloat = 50
        
        for i in 0..<coinCount {
            let coin = createCoin()
            let x = size.width + CGFloat(i) * spacing
            let y = size.height/2 + amplitude * sin(CGFloat(i) * .pi / 4)
            coin.position = CGPoint(x: x, y: y)
            worldNode.addChild(coin)
            
            let moveAction = SKAction.moveBy(x: -(size.width + CGFloat(coinCount) * spacing),
                                           y: 0,
                                           duration: 3.0)
            let removeAction = SKAction.removeFromParent()
            coin.run(SKAction.sequence([moveAction, removeAction]))
        }
    }
    
    private func createCoin() -> SKSpriteNode {
        let coin = SKSpriteNode(color: .yellow, size: CGSize(width: 15, height: 15))
        coin.physicsBody = SKPhysicsBody(circleOfRadius: 7.5)
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.collisionBitMask = 0
        coin.physicsBody?.isDynamic = false
        
        // Add rotation animation
        let rotateAction = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 1.0))
        coin.run(rotateAction)
        
        return coin
    }
    
    private func spawnPowerUp() {
        guard let powerUpType = PowerUpType.allCases.randomElement() else { return }
        
        let powerUp = SKLabelNode(text: powerUpType.rawValue)
        powerUp.fontSize = 30
        powerUp.position = CGPoint(x: size.width + 20,
                                 y: CGFloat.random(in: ground.frame.maxY + 50...ceiling.frame.minY - 50))
        
        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        powerUp.physicsBody?.categoryBitMask = powerUpCategory
        powerUp.physicsBody?.collisionBitMask = 0
        powerUp.physicsBody?.isDynamic = false
        powerUp.name = powerUpType.rawValue
        
        worldNode.addChild(powerUp)
        
        let moveAction = SKAction.moveBy(x: -size.width - 40, y: 0, duration: 3.0)
        let removeAction = SKAction.removeFromParent()
        powerUp.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    private func activatePowerUp(_ type: PowerUpType) {
        currentPowerUp = type
        powerUpTimeRemaining = type.duration
        
        switch type {
        case .shield:
            player.run(SKAction.colorize(with: .blue, colorBlendFactor: 0.5, duration: 0.2))
        case .speedBoost:
            gameSpeed *= 1.5
        case .magnet:
            // Magnet effect handled in update method
            break
        case .miniSize:
            player.run(SKAction.scale(to: 0.5, duration: 0.2))
        }
    }
    
    private func deactivatePowerUp() {
        guard let type = currentPowerUp else { return }
        
        switch type {
        case .shield:
            player.run(SKAction.colorize(withColorBlendFactor: 0, duration: 0.2))
        case .speedBoost:
            gameSpeed /= 1.5
        case .magnet:
            break
        case .miniSize:
            player.run(SKAction.scale(to: 1.0, duration: 0.2))
        }
        
        currentPowerUp = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver && gameState == .playing else { return }
        
        // Calculate delta time
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update distance and score
        distance += gameSpeed * CGFloat(dt)
        score = Int(distance / 100)
        scoreLabel.text = "Score: \(score)"
        
        // Apply jetpack force
        if isJetpackActive {
            player.physicsBody?.applyForce(CGVector(dx: 0, dy: 2000))
        }
        
        // Update power-up duration
        if let type = currentPowerUp {
            powerUpTimeRemaining -= dt
            if powerUpTimeRemaining <= 0 {
                deactivatePowerUp()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch gameState {
        case .menu:
            setupGame()
        case .playing:
            if let node = nodes(at: location).first, node.name == "pauseButton" {
                pauseGame()
            } else {
                isJetpackActive = true
                jetpackParticles?.particleBirthRate = 100
            }
        case .paused:
            if let node = nodes(at: location).first {
                switch node.name {
                case "resumeButton":
                    resumeGame()
                case "menuButton":
                    showMainMenu()
                default:
                    break
                }
            }
        case .gameOver:
            setupGame()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .playing {
            isJetpackActive = false
            jetpackParticles?.particleBirthRate = 0
        }
    }
    
    private func pauseGame() {
        gameState = .paused
        self.isPaused = true
        
        let pauseMenu = SKNode()
        pauseMenu.name = "pauseMenu"
        addChild(pauseMenu)
        
        let resumeButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        resumeButton.text = "Resume"
        resumeButton.fontSize = 32
        resumeButton.position = CGPoint(x: size.width/2, y: size.height * 0.6)
        resumeButton.name = "resumeButton"
        pauseMenu.addChild(resumeButton)
        
        let menuButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuButton.text = "Main Menu"
        menuButton.fontSize = 32
        menuButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        menuButton.name = "menuButton"
        pauseMenu.addChild(menuButton)
    }
    
    private func resumeGame() {
        gameState = .playing
        self.isPaused = false
        if let pauseMenu = childNode(withName: "pauseMenu") {
            pauseMenu.removeFromParent()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == playerCategory | obstacleCategory {
            if currentPowerUp == .shield {
                deactivatePowerUp()
                return
            }
            gameOver()
        } else if collision == playerCategory | coinCategory {
            if let coin = (contact.bodyA.categoryBitMask == coinCategory ? contact.bodyA.node : contact.bodyB.node) {
                collectCoin(coin)
            }
        } else if collision == playerCategory | powerUpCategory {
            if let powerUp = (contact.bodyA.categoryBitMask == powerUpCategory ? contact.bodyA.node : contact.bodyB.node) {
                collectPowerUp(powerUp)
            }
        }
    }
    
    private func gameOver() {
        gameState = .gameOver
        player.physicsBody?.isDynamic = false
        
        // Update high score
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "HighScore")
        }
        
        // Stop all spawning actions
        removeAllActions()
        
        // Show game over UI
        let gameOverNode = SKNode()
        addChild(gameOverNode)
        
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 40)
        gameOverNode.addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 30
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        gameOverNode.addChild(scoreLabel)
        
        if score == highScore {
            let newHighScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            newHighScoreLabel.text = "New High Score!"
            newHighScoreLabel.fontSize = 25
            newHighScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 30)
            gameOverNode.addChild(newHighScoreLabel)
        }
        
        let tapToRestartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapToRestartLabel.text = "Tap to Play Again"
        tapToRestartLabel.fontSize = 25
        tapToRestartLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 60)
        gameOverNode.addChild(tapToRestartLabel)
    }
    
    private func collectCoin(_ coin: SKNode) {
        coins += 1
        coinLabel.text = "Coins: \(coins)"
        
        // Add collection effect
        let scale = SKAction.scale(to: 1.5, duration: 0.1)
        let fade = SKAction.fadeOut(withDuration: 0.1)
        let remove = SKAction.removeFromParent()
        coin.run(SKAction.sequence([scale, fade, remove]))
        
        // TODO: Add sound effect
    }
    
    private func collectPowerUp(_ powerUp: SKNode) {
        if let powerUpType = PowerUpType(rawValue: powerUp.name ?? "") {
            activatePowerUp(powerUpType)
            powerUp.removeFromParent()
        }
    }
}

// Extension to convert SKShapeNode to SKSpriteNode
extension SKShapeNode {
    func asSprite() -> SKSpriteNode {
        let texture = SKView().texture(from: self)
        return SKSpriteNode(texture: texture)
    }
}
