import SpriteKit
import UIKit

// MARK: - SlicersGameScene

final class SlicersGameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {

    // MARK: Constants
    private let playerX:  CGFloat = 160
    private var groundY:  CGFloat = 0   // set in didMove

    // MARK: Nodes
    private var player:         PlayerNode!
    private var scoreLabel:     SKLabelNode!
    private var comboLabel:     SKLabelNode!
    private var livesContainer: SKNode!
    private var powerUpLabel:   SKLabelNode!
    private var powerUpBar:     SKShapeNode!
    private var powerUpFill:    SKShapeNode!
    private var waveLabel:      SKLabelNode!
    private var coinLabel:      SKLabelNode!
    private var bgLayers:       [SKNode] = []
    private var sliceTrailNode: SKShapeNode?
    private var skySprite:      SKSpriteNode?

    // MARK: Game State
    private var isRunning   = false
    private var score       = 0
    private var lives       = 3
    private var combo       = 0
    private var wave        = 1
    private var config      = WaveConfig.make(wave: 1)

    private var activePowerUp:       PowerUpType? = nil
    private var powerUpTimeLeft:     TimeInterval  = 0
    private var powerUpDuration:     TimeInterval  = 1

    private var lastUpdateTime:      TimeInterval  = 0
    private var timeSinceLastSpawn:  TimeInterval  = 0
    private var timeSinceWaveStart:  TimeInterval  = 0
    private var invincibleTime:      TimeInterval  = 0  // brief grace after hit
    private var obstaclePool:        [ObstacleNode] = []
    private var pendingPowerUp:      Bool           = false
    private var spawnCount           = 0
    private var speedLinesNode:      SKNode?
    private var bossSpawnedThisWave  = false
    private var coinsCollected       = 0

    // MARK: Touch tracking
    private var touchStart:    CGPoint = .zero
    private var touchPath:     [CGPoint] = []
    private var lastTouchPoint: CGPoint = .zero

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        groundY = size.height * 0.20

        physicsWorld.gravity    = .zero
        physicsWorld.contactDelegate = self

        buildBackground()
        buildGround()
        buildPlayer()
        buildHUD()

        // Short countdown before game starts
        let countdown = buildCountdown()
        addChild(countdown)
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                countdown.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
                self?.startRun()
            }
        ]))
    }

    private func startRun() {
        isRunning = true
        config    = WaveConfig.make(wave: wave)
    }

    // MARK: - Background

    private func buildBackground() {
        let t = ThemeManager.shared
        backgroundColor = .black

        // Sky gradient texture
        let gradTexture = makeGradientTexture(size: CGSize(width: size.width, height: size.height),
                                              topColor: t.skyTop, bottomColor: t.skyBottom)
        let gradSprite = SKSpriteNode(texture: gradTexture, size: CGSize(width: size.width, height: size.height))
        gradSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        gradSprite.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        gradSprite.zPosition   = -1
        addChild(gradSprite)
        skySprite = gradSprite

        // Glowing stars
        let starRadii: [CGFloat] = [0.8, 1.2, 1.6, 2.0]
        let starTextures = starRadii.map { makeStarTexture(radius: $0) }
        for _ in 0..<20 {
            let r = starRadii.randomElement() ?? 1.2
            let tex = starTextures[starRadii.firstIndex(of: r) ?? 0]
            let star = SKSpriteNode(texture: tex, size: CGSize(width: r * 6, height: r * 6))
            star.alpha     = CGFloat.random(in: 0.5...0.9)
            star.position  = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.55...size.height - 10))
            star.zPosition = -0.5
            // Twinkle
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.2...0.4), duration: Double.random(in: 1.5...3.0)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...0.9),  duration: Double.random(in: 1.5...3.0))
            ])
            star.run(SKAction.repeatForever(twinkle))
            addChild(star)
        }

        // Mountain silhouettes (distant layer)
        let mountainLayer = SKNode()
        mountainLayer.zPosition = 0.5
        bgLayers.append(mountainLayer)
        addChild(mountainLayer)
        buildMountainRange(into: mountainLayer, baseY: groundY + 10, count: 5,
                           minH: 60, maxH: 140, color: t.ground.withAlphaComponent(0.4), spread: 1.6)

        // Mountain silhouettes (nearer layer)
        let nearMountains = SKNode()
        nearMountains.zPosition = 1.0
        bgLayers.append(nearMountains)
        addChild(nearMountains)
        buildMountainRange(into: nearMountains, baseY: groundY + 5, count: 6,
                           minH: 40, maxH: 90, color: t.ground.withAlphaComponent(0.6), spread: 1.4)

        // Cloud layers (parallax): distant, mid, near
        let alphas: [CGFloat] = [0.2, 0.35, 0.5]
        for i in 0..<3 {
            let layer = SKNode()
            layer.zPosition = CGFloat(i) + 1.5
            bgLayers.append(layer)
            addChild(layer)

            let count = 8 + i * 3
            for j in 0..<count {
                let cloud = SKShapeNode(rectOf: CGSize(
                    width:  CGFloat.random(in: 40...130),
                    height: CGFloat.random(in: 16...42)),
                    cornerRadius: 12)
                cloud.fillColor   = UIColor.white.withAlphaComponent(alphas[i])
                cloud.strokeColor = .clear
                cloud.position    = CGPoint(
                    x: CGFloat(j) / CGFloat(count) * size.width * 1.5,
                    y: CGFloat.random(in: groundY + 80 ... size.height - 30))
                cloud.name = "cloud_\(i)"
                layer.addChild(cloud)
            }
        }
    }

    private func buildMountainRange(into layer: SKNode, baseY: CGFloat, count: Int,
                                     minH: CGFloat, maxH: CGFloat, color: UIColor, spread: CGFloat) {
        let totalW = size.width * spread
        for i in 0..<count {
            let peakH  = CGFloat.random(in: minH...maxH)
            let halfW  = CGFloat.random(in: 60...120)
            let cx     = CGFloat(i) / CGFloat(count) * totalW + CGFloat.random(in: -30...30)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: cx - halfW, y: baseY))
            path.addLine(to: CGPoint(x: cx - halfW * 0.3, y: baseY + peakH * 0.7))
            path.addLine(to: CGPoint(x: cx, y: baseY + peakH))
            path.addLine(to: CGPoint(x: cx + halfW * 0.4, y: baseY + peakH * 0.6))
            path.addLine(to: CGPoint(x: cx + halfW, y: baseY))
            path.closeSubpath()

            let mountain = SKShapeNode(path: path)
            mountain.fillColor   = color
            mountain.strokeColor = .clear
            layer.addChild(mountain)
        }
    }

    private func buildGround() {
        let t = ThemeManager.shared

        // Ground platform
        let ground = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: groundY * 2))
        ground.fillColor   = t.ground
        ground.strokeColor = .clear
        ground.position    = CGPoint(x: size.width / 2, y: groundY / 2 - groundY / 2)
        ground.zPosition   = 2
        addChild(ground)

        // Ground surface lighter band
        let surface = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 6))
        surface.fillColor   = UIColor.white.withAlphaComponent(0.08)
        surface.strokeColor = .clear
        surface.position    = CGPoint(x: size.width / 2, y: groundY - 2)
        surface.zPosition   = 2.5
        addChild(surface)

        // Ground edge highlight
        let edge = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 3))
        edge.fillColor   = UIColor.white.withAlphaComponent(0.18)
        edge.strokeColor = .clear
        edge.position    = CGPoint(x: size.width / 2, y: groundY + 1)
        edge.zPosition   = 3
        addChild(edge)

        // Subtle ground texture lines
        for i in 0..<6 {
            let line = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 1))
            line.fillColor   = UIColor.white.withAlphaComponent(0.04)
            line.strokeColor = .clear
            line.position    = CGPoint(x: size.width / 2,
                                       y: CGFloat(i) * groundY / 6.0)
            line.zPosition   = 2.1
            addChild(line)
        }

        // Ground detail layer (grass tufts, rocks, flowers) — parallax scrolled
        let detailLayer = SKNode()
        detailLayer.zPosition = 3.5
        bgLayers.append(detailLayer)
        addChild(detailLayer)

        for i in 0..<20 {
            let x = CGFloat(i) * (size.width * 1.5 / 20.0) + CGFloat.random(in: -15...15)
            let detail: SKNode
            let roll = Int.random(in: 0...2)
            if roll == 0 {
                // Grass tuft
                let path = CGMutablePath()
                for blade in 0..<3 {
                    let bx = CGFloat(blade) * 4 - 4
                    let h  = CGFloat.random(in: 6...14)
                    let lean = CGFloat.random(in: -3...3)
                    path.move(to: CGPoint(x: bx, y: 0))
                    path.addQuadCurve(to: CGPoint(x: bx + lean, y: h),
                                      control: CGPoint(x: bx + lean * 0.5, y: h * 0.6))
                }
                let grass = SKShapeNode(path: path)
                grass.strokeColor = t.ground.blended(withFraction: 0.3, of: UIColor(red: 0.3, green: 0.7, blue: 0.2, alpha: 1))
                grass.lineWidth   = 1.5
                grass.lineCap     = .round
                detail = grass
            } else if roll == 1 {
                // Small rock
                let rockW = CGFloat.random(in: 4...10)
                let rockH = CGFloat.random(in: 3...6)
                let rock = SKShapeNode(ellipseOf: CGSize(width: rockW, height: rockH))
                rock.fillColor   = UIColor(white: CGFloat.random(in: 0.25...0.4), alpha: 0.6)
                rock.strokeColor = .clear
                detail = rock
            } else {
                // Tiny flower
                let stem = SKShapeNode(rectOf: CGSize(width: 1.5, height: 8))
                stem.fillColor   = UIColor(red: 0.2, green: 0.5, blue: 0.15, alpha: 0.7)
                stem.strokeColor = .clear
                let petal = SKShapeNode(circleOfRadius: 2.5)
                petal.fillColor   = [UIColor.yellow, UIColor.red, UIColor.magenta, UIColor.white]
                    .randomElement()!.withAlphaComponent(0.7)
                petal.strokeColor = .clear
                petal.position    = CGPoint(x: 0, y: 5)
                stem.addChild(petal)
                detail = stem
            }
            detail.position = CGPoint(x: x, y: groundY + CGFloat.random(in: 1...4))
            detailLayer.addChild(detail)
        }
    }

    private func buildPlayer() {
        player = PlayerNode()
        player.position  = CGPoint(x: playerX, y: groundY)
        player.zPosition = 10
        addChild(player)
    }

    // MARK: - HUD

    private func buildHUD() {
        let t   = ThemeManager.shared
        let safeTop   = view?.safeAreaInsets.top ?? 0
        let safeLeft  = view?.safeAreaInsets.left ?? 0
        let safeRight = view?.safeAreaInsets.right ?? 0
        let top = size.height - max(28, safeTop + 8)
        let leftEdge  = safeLeft + 20
        let rightEdge = size.width - safeRight - 20

        // HUD background panel (top-left)
        let hudBG = SKShapeNode(rectOf: CGSize(width: 130, height: 60), cornerRadius: 10)
        hudBG.fillColor   = UIColor.black.withAlphaComponent(0.3)
        hudBG.strokeColor = .clear
        hudBG.position    = CGPoint(x: leftEdge + 52, y: top - 8)
        hudBG.zPosition   = 19
        addChild(hudBG)

        // Score
        scoreLabel          = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text     = "0"
        scoreLabel.fontSize = 26
        scoreLabel.fontColor = t.accent
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position  = CGPoint(x: leftEdge, y: top)
        scoreLabel.zPosition = 20
        addChild(scoreLabel)

        // Coin icon (small gold circle)
        let coinIcon = SKShapeNode(circleOfRadius: 7)
        coinIcon.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1)
        coinIcon.strokeColor = UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1)
        coinIcon.lineWidth   = 1.5
        coinIcon.position    = CGPoint(x: leftEdge + 8, y: top - 20)
        coinIcon.zPosition   = 20
        addChild(coinIcon)

        // Coin counter
        coinLabel          = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.text     = "0"
        coinLabel.fontSize = 16
        coinLabel.fontColor = t.accent
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position  = CGPoint(x: leftEdge + 20, y: top - 26)
        coinLabel.zPosition = 20
        addChild(coinLabel)

        // Wave
        waveLabel           = SKLabelNode(fontNamed: "AvenirNext-Medium")
        waveLabel.text      = "WAVE 1"
        waveLabel.fontSize  = 14
        waveLabel.fontColor = t.textSecondary
        waveLabel.horizontalAlignmentMode = .center
        waveLabel.position  = CGPoint(x: size.width / 2, y: top + 2)
        waveLabel.zPosition = 20
        addChild(waveLabel)

        // Combo
        comboLabel           = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        comboLabel.text      = ""
        comboLabel.fontSize  = 18
        comboLabel.fontColor = t.success
        comboLabel.horizontalAlignmentMode = .center
        comboLabel.position  = CGPoint(x: size.width / 2, y: top - 26)
        comboLabel.zPosition = 20
        addChild(comboLabel)

        // Lives (hearts)
        livesContainer          = SKNode()
        livesContainer.position = CGPoint(x: rightEdge, y: top + 4)
        livesContainer.zPosition = 20
        addChild(livesContainer)
        refreshLives()

        // Power-up label + progress bar
        powerUpLabel           = SKLabelNode(fontNamed: "AvenirNext-Bold")
        powerUpLabel.text      = ""
        powerUpLabel.fontSize  = 13
        powerUpLabel.fontColor = t.accent
        powerUpLabel.horizontalAlignmentMode = .center
        powerUpLabel.position  = CGPoint(x: size.width / 2, y: top - 48)
        powerUpLabel.zPosition = 20
        addChild(powerUpLabel)

        let barW: CGFloat = 140
        powerUpBar = SKShapeNode(rectOf: CGSize(width: barW, height: 6), cornerRadius: 3)
        powerUpBar.fillColor   = UIColor(white: 0.3, alpha: 0.6)
        powerUpBar.strokeColor = .clear
        powerUpBar.position    = CGPoint(x: size.width / 2, y: top - 62)
        powerUpBar.zPosition   = 20
        powerUpBar.isHidden    = true
        addChild(powerUpBar)

        powerUpFill = SKShapeNode(rectOf: CGSize(width: barW, height: 6), cornerRadius: 3)
        powerUpFill.fillColor   = ThemeManager.shared.accent
        powerUpFill.strokeColor = .clear
        powerUpFill.position    = powerUpBar.position
        powerUpFill.zPosition   = 21
        powerUpFill.isHidden    = true
        addChild(powerUpFill)

        // Swipe hint on first run
        if PointsManager.shared.totalRuns == 0 {
            addHint()
        }
    }

    private func addHint() {
        let t = ThemeManager.shared
        let hint = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hint.text      = "Swipe to slice • Swipe ↑ to jump • Swipe ↓ to slide"
        hint.fontSize  = 13
        hint.fontColor = t.textSecondary
        hint.position  = CGPoint(x: size.width / 2, y: groundY + 40)
        hint.zPosition = 15
        hint.name      = "hint"
        hint.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))
        addChild(hint)
    }

    private func refreshLives() {
        livesContainer.removeAllChildren()
        for i in 0..<3 {
            let heart = SKLabelNode(text: i < lives ? "❤️" : "🖤")
            heart.fontSize  = 18
            heart.position  = CGPoint(x: -CGFloat(i) * 26, y: 0)

            // Pulse animation for active hearts
            if i < lives {
                let pulseSpeed: TimeInterval = lives == 1 ? 0.4 : 0.8
                let pulseScale: CGFloat = lives == 1 ? 1.3 : 1.1
                let pulse = SKAction.repeatForever(SKAction.sequence([
                    SKAction.scale(to: pulseScale, duration: pulseSpeed),
                    SKAction.scale(to: 1.0, duration: pulseSpeed)
                ]))
                heart.run(pulse)
            }

            livesContainer.addChild(heart)
        }
    }

    private func buildCountdown() -> SKNode {
        let t = ThemeManager.shared
        let panel = SKShapeNode(rectOf: CGSize(width: 160, height: 80), cornerRadius: 16)
        panel.fillColor   = t.panelBG
        panel.strokeColor = t.buttonStroke
        panel.lineWidth   = 2
        panel.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition   = 50

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text                  = "READY?"
        label.fontSize              = 28
        label.fontColor             = t.accent
        label.verticalAlignmentMode = .center
        panel.addChild(label)
        return panel
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard isRunning, player.state != .dead else { return }

        let dt: TimeInterval = lastUpdateTime == 0 ? 0.016 : min(currentTime - lastUpdateTime, 0.1)
        lastUpdateTime = currentTime

        // Invincibility cooldown
        if invincibleTime > 0 { invincibleTime -= dt }

        // Scroll background
        scrollBackground(dt: dt)

        // Move obstacles, power-ups, enemies, and coins
        let scrollDx = -config.scrollSpeed * CGFloat(dt)
        for name in ["obstacle", "powerup", "coin"] {
            enumerateChildNodes(withName: name) { node, _ in node.position.x += scrollDx }
        }
        // Enemies scroll at normal speed, but bosses move slower so they can be hit
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let enemy = node as? EnemyNode, enemy.enemyType == .boss {
                // Boss moves at 30% scroll speed, and stops when on-screen
                let bossSpeed: CGFloat
                if node.position.x > 100 && node.position.x < self.size.width - 60 {
                    bossSpeed = scrollDx * 0.15  // nearly stationary when on screen
                } else {
                    bossSpeed = scrollDx * 0.35  // slower approach and exit
                }
                node.position.x += bossSpeed
            } else {
                node.position.x += scrollDx
            }
        }

        // Remove off-screen nodes
        for name in ["obstacle", "powerup", "enemy", "coin"] {
            enumerateChildNodes(withName: name) { node, _ in
                if node.position.x < -120 { node.removeFromParent() }
            }
        }

        // Spawn
        timeSinceLastSpawn += dt
        if timeSinceLastSpawn >= config.spawnInterval {
            timeSinceLastSpawn = 0

            // Roll for enemy spawn
            let isBossWave = wave >= 5 && wave % 5 == 0
            if isBossWave && !bossSpawnedThisWave {
                spawnEnemy(forceBoss: true)
                bossSpawnedThisWave = true
            } else if config.enemyChance > 0 && Double.random(in: 0...1) < config.enemyChance {
                spawnEnemy(forceBoss: false)
            } else {
                spawnObstacle()
            }

            spawnCount += 1

            // Coin clusters
            if spawnCount % config.coinClusterEvery == 0 {
                spawnCoinCluster()
            }

            if spawnCount % 5 == 0 { pendingPowerUp = true }
            if pendingPowerUp {
                pendingPowerUp = false
                if Double.random(in: 0...1) < config.powerUpChance { spawnPowerUp() }
            }
        }

        // Wave progression
        timeSinceWaveStart += dt
        if timeSinceWaveStart >= 20.0 {
            timeSinceWaveStart = 0
            wave += 1
            bossSpawnedThisWave = false
            config = WaveConfig.make(wave: wave)
            waveLabel.text = "WAVE \(wave)"
            flashLabel(waveLabel)
            showWaveBanner(wave: wave)
            transitionSky(wave: wave)
        }

        // Score (time-based)
        let points = 1 + (wave - 1) / 2
        score += points
        updateScoreDisplay()

        // Power-up countdown (shield has no timer — it's consumed on hit)
        if let active = activePowerUp, active != .shield {
            powerUpTimeLeft -= dt
            updatePowerUpBar()
            if powerUpTimeLeft <= 0 { deactivatePowerUp() }
        }

    }

    private func scrollBackground(dt: TimeInterval) {
        // bgLayers order: [0] distant mountains, [1] near mountains,
        //                 [2] distant clouds, [3] mid clouds, [4] near clouds
        let speeds: [CGFloat] = [0.08, 0.15, 0.15, 0.4, 0.7]
        for (i, layer) in bgLayers.enumerated() {
            guard i < speeds.count else { break }
            let dx = -config.scrollSpeed * speeds[i] * CGFloat(dt)
            for child in layer.children {
                child.position.x += dx
                if child.position.x < -200 { child.position.x += size.width + 400 }
            }
        }
    }

    // MARK: - Spawning

    private func spawnObstacle() {
        let types = config.obstacleTypes
        let type  = types[Int.random(in: 0..<types.count)]
        let obs   = ObstacleNode(type: type, groundY: groundY)
        obs.position.x = size.width + 60
        obs.zPosition  = 8
        obs.name       = "obstacle"
        addChild(obs)
    }

    private func spawnPowerUp() {
        let type     = PowerUpType.allCases.randomElement()!
        let node     = PowerUpNode(type: type)
        node.position = CGPoint(x: size.width + 60,
                                y: groundY + CGFloat.random(in: 50...90))
        node.zPosition = 8
        node.name      = "powerup"
        addChild(node)
    }

    private func spawnEnemy(forceBoss: Bool) {
        let type: EnemyType
        if forceBoss {
            type = .boss
        } else {
            let available = config.enemyTypesForWave(wave)
            guard !available.isEmpty else { return }
            type = available.randomElement()!
        }
        let node = EnemyNode(type: type, groundY: groundY)
        node.position.x = size.width + 80
        node.zPosition  = 8
        node.name       = "enemy"
        addChild(node)
    }

    private func spawnCoinCluster() {
        let count = Int.random(in: 3...5)
        for i in 0..<count {
            let coin = CoinNode()
            coin.position = CGPoint(
                x: size.width + 80 + CGFloat(i) * 40,
                y: groundY + CGFloat.random(in: 40...100)
            )
            coin.zPosition = 8
            coin.name      = "coin"
            addChild(coin)
        }
    }

    private func spawnCoinMagnetTrail(from pos: CGPoint) {
        let targetPos = player.position
        for i in 0..<4 {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            sparkle.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.9)
            sparkle.strokeColor = .clear
            sparkle.position    = pos
            sparkle.zPosition   = 12

            let delay = Double(i) * 0.05
            let midPt = CGPoint(x: (pos.x + targetPos.x) / 2 + CGFloat.random(in: -20...20),
                                y: pos.y + CGFloat.random(in: 20...50))

            let movePath = CGMutablePath()
            movePath.move(to: pos)
            movePath.addQuadCurve(to: targetPos, control: midPt)

            sparkle.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.follow(movePath, asOffset: false, orientToPath: false, duration: 0.3),
                    SKAction.sequence([
                        SKAction.wait(forDuration: 0.2),
                        SKAction.fadeOut(withDuration: 0.1)
                    ]),
                    SKAction.scale(to: 0.3, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
            addChild(sparkle)
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA, b = contact.bodyB
        let masks = a.categoryBitMask | b.categoryBitMask

        if masks == PhysicsCategory.player | PhysicsCategory.powerUp {
            let puNode = (a.categoryBitMask == PhysicsCategory.powerUp ? a.node : b.node) as? PowerUpNode
            if let puNode { collectPowerUp(puNode) }
        }

        if masks == PhysicsCategory.player | PhysicsCategory.hazard ||
           masks == PhysicsCategory.player | PhysicsCategory.obstacle {
            guard invincibleTime <= 0 else { return }

            // Chainsaw power-up auto-destroys all obstacles (including hazards)
            if activePowerUp == .chainsaw {
                let obsNode = (a.categoryBitMask == PhysicsCategory.obstacle ||
                               a.categoryBitMask == PhysicsCategory.hazard ? a.node : b.node) as? ObstacleNode
                if let obsNode {
                    SoundManager.shared.playChainsaw()
                    score += obsNode.obstacleType.scoreValue
                    if obsNode.obstacleType.isSliceable {
                        _ = obsNode.receiveHit()
                    } else {
                        obsNode.forceDestroy()
                    }
                }
                return
            }

            if activePowerUp == .shield {
                player.isShielded = false
                activePowerUp     = nil
                powerUpLabel.text = ""
                powerUpBar.isHidden  = true
                powerUpFill.isHidden = true
                invincibleTime = 1.5
                player.flashHit()
                SoundManager.shared.playPlayerHit()
                return
            }

            loseLife()
        }

        // Enemy contact
        if masks == PhysicsCategory.player | PhysicsCategory.enemy {
            guard invincibleTime <= 0 else { return }

            if activePowerUp == .chainsaw {
                let enemyNode = (a.categoryBitMask == PhysicsCategory.enemy ? a.node : b.node) as? EnemyNode
                if let enemyNode {
                    SoundManager.shared.playChainsaw()
                    score += enemyNode.enemyType.scoreValue
                    _ = enemyNode.receiveHit()
                }
                return
            }

            if activePowerUp == .shield {
                player.isShielded = false
                activePowerUp     = nil
                powerUpLabel.text = ""
                powerUpBar.isHidden  = true
                powerUpFill.isHidden = true
                invincibleTime = 1.5
                player.flashHit()
                SoundManager.shared.playPlayerHit()
                return
            }

            loseLife()
        }

        // Coin contact
        if masks == PhysicsCategory.player | PhysicsCategory.coin {
            let coinNode = (a.categoryBitMask == PhysicsCategory.coin ? a.node : b.node) as? CoinNode
            if let coinNode {
                let coinPos = coinNode.position
                coinNode.collect()
                coinsCollected += 1
                score += 5
                SoundManager.shared.playPowerUpPickup()
                updateScoreDisplay()
                updateCoinDisplay()
                spawnCoinMagnetTrail(from: coinPos)
            }
        }
    }

    // MARK: - Power-ups

    private func collectPowerUp(_ node: PowerUpNode) {
        node.collect()
        SoundManager.shared.playPowerUpPickup()

        let type = node.powerUpType
        activePowerUp        = type
        player.activePowerUp = type
        player.isShielded    = (type == .shield)

        if type == .shield {
            powerUpTimeLeft  = 0
            powerUpDuration  = 1
        } else {
            powerUpTimeLeft  = type.duration
            powerUpDuration  = type.duration
        }

        powerUpLabel.text = type.displayName
        powerUpBar.isHidden  = (type == .shield)
        powerUpFill.isHidden = (type == .shield)

        // Slow motion: halve scroll speed temporarily
        if type == .slowMotion {
            config = WaveConfig(
                spawnInterval:    config.spawnInterval * 1.8,
                scrollSpeed:      config.scrollSpeed * 0.4,
                obstacleTypes:    config.obstacleTypes,
                powerUpChance:    config.powerUpChance,
                enemyChance:      config.enemyChance,
                coinClusterEvery: config.coinClusterEvery
            )
        }

        // Speed boost: increase scroll speed + speed lines
        if type == .speedBoost {
            showSpeedLines()
            config = WaveConfig(
                spawnInterval:    config.spawnInterval * 0.7,
                scrollSpeed:      config.scrollSpeed * 1.5,
                obstacleTypes:    config.obstacleTypes,
                powerUpChance:    config.powerUpChance,
                enemyChance:      config.enemyChance,
                coinClusterEvery: config.coinClusterEvery
            )
        }

        flashLabel(powerUpLabel)
    }

    private func deactivatePowerUp() {
        if activePowerUp == .speedBoost {
            hideSpeedLines()
        }
        if activePowerUp == .slowMotion || activePowerUp == .speedBoost {
            config = WaveConfig.make(wave: wave) // restore normal speed
        }
        activePowerUp        = nil
        player.activePowerUp = nil
        player.isShielded    = false
        powerUpLabel.text    = ""
        powerUpBar.isHidden  = true
        powerUpFill.isHidden = true
    }

    private func updatePowerUpBar() {
        guard let activePowerUp, activePowerUp != .shield, powerUpDuration > 0 else { return }
        let pct    = max(0, CGFloat(powerUpTimeLeft / powerUpDuration))
        let barW   = CGFloat(140) * pct
        guard barW > 0 else { return }

        powerUpFill.removeFromParent()
        powerUpFill = SKShapeNode(rectOf: CGSize(width: barW, height: 6), cornerRadius: 3)
        powerUpFill.fillColor   = ThemeManager.shared.powerUpColor(activePowerUp)
        powerUpFill.strokeColor = .clear
        powerUpFill.position    = CGPoint(x: size.width / 2 - (140 - barW) / 2,
                                          y: size.height - 90)
        powerUpFill.zPosition   = 21
        powerUpFill.isHidden    = false
        addChild(powerUpFill)
    }

    // MARK: - Lives & Game Over

    private func loseLife() {
        lives -= 1
        invincibleTime = 1.2
        combo          = 0
        refreshComboLabel()
        refreshLives()
        player.flashHit()
        SoundManager.shared.playPlayerHit()
        flashScreen(color: ThemeManager.shared.danger)
        screenShake(intensity: lives <= 1 ? 2.0 : 1.0)

        if lives > 0 {
            // Reset player back to ground position after brief delay
            run(SKAction.wait(forDuration: 0.15)) { [weak self] in
                guard let self = self else { return }
                self.player.forceEndSlide()
                self.player.removeAllActions()
                self.player.position = CGPoint(x: self.playerX, y: self.groundY)
            }
        } else {
            triggerGameOver()
        }
    }

    private func screenShake(intensity: CGFloat = 1.0) {
        let s = intensity
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -6 * s, y:  3 * s, duration: 0.03),
            SKAction.moveBy(x: 12 * s, y: -6 * s, duration: 0.03),
            SKAction.moveBy(x: -8 * s, y:  4 * s, duration: 0.03),
            SKAction.moveBy(x:  4 * s, y: -2 * s, duration: 0.03),
            SKAction.moveBy(x: -2 * s, y:  1 * s, duration: 0.02)
        ])
        player.run(shake)
    }

    private func triggerGameOver() {
        isRunning = false
        player.die()
        SoundManager.shared.playGameOver()
        PointsManager.shared.recordRun(score: score, coins: coinsCollected)

        // Slow-mo death effect
        speed = 0.3
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in self?.speed = 1.0 },
            // Screen crack edges
            SKAction.run { [weak self] in self?.showDeathCrackEffect() },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.showGameOverPanel() }
        ]))
    }

    private func showDeathCrackEffect() {
        let t = ThemeManager.shared
        // Draw crack lines from edges
        for _ in 0..<6 {
            let edge = Int.random(in: 0...3) // top, right, bottom, left
            let startPt: CGPoint
            switch edge {
            case 0: startPt = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
            case 1: startPt = CGPoint(x: size.width, y: CGFloat.random(in: 0...size.height))
            case 2: startPt = CGPoint(x: CGFloat.random(in: 0...size.width), y: 0)
            default: startPt = CGPoint(x: 0, y: CGFloat.random(in: 0...size.height))
            }

            let path = CGMutablePath()
            path.move(to: startPt)
            var pt = startPt
            let segments = Int.random(in: 3...6)
            for _ in 0..<segments {
                let dx = CGFloat.random(in: -40...40) + (size.width / 2 - pt.x) * 0.15
                let dy = CGFloat.random(in: -40...40) + (size.height / 2 - pt.y) * 0.15
                pt = CGPoint(x: pt.x + dx, y: pt.y + dy)
                path.addLine(to: pt)
            }

            let crack = SKShapeNode(path: path)
            crack.strokeColor = t.danger.withAlphaComponent(0.7)
            crack.lineWidth   = CGFloat.random(in: 1.5...3.0)
            crack.zPosition   = 45
            crack.alpha       = 0
            crack.run(SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.1),
                SKAction.wait(forDuration: 1.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
            addChild(crack)
        }
    }

    private func showGameOverPanel() {
        let t = ThemeManager.shared

        // Dim overlay
        let dim = SKShapeNode(rectOf: size)
        dim.fillColor   = UIColor.black.withAlphaComponent(0.5)
        dim.strokeColor = .clear
        dim.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.zPosition   = 40
        dim.alpha       = 0
        dim.run(SKAction.fadeAlpha(to: 1, duration: 0.3))
        addChild(dim)

        // Panel
        let panel = SKShapeNode(rectOf: CGSize(width: 340, height: 270), cornerRadius: 20)
        panel.fillColor   = t.panelBG
        panel.strokeColor = t.buttonStroke
        panel.lineWidth   = 2
        panel.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition   = 50
        panel.setScale(0.6)
        panel.run(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.2),
            SKAction.scale(to: 1.0,  duration: 0.1)
        ]))
        addChild(panel)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text                  = "GAME OVER"
        title.fontSize              = 30
        title.fontColor             = t.danger
        title.verticalAlignmentMode = .center
        title.position              = CGPoint(x: 0, y: 72)
        panel.addChild(title)

        let scoreLine = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLine.text                  = "Score: \(score)"
        scoreLine.fontSize              = 22
        scoreLine.fontColor             = t.textPrimary
        scoreLine.verticalAlignmentMode = .center
        scoreLine.position              = CGPoint(x: 0, y: 30)
        panel.addChild(scoreLine)

        // Coins and wave info
        let statsLine = SKLabelNode(fontNamed: "AvenirNext-Medium")
        statsLine.text                  = "Wave \(wave)  •  \(coinsCollected) coins"
        statsLine.fontSize              = 14
        statsLine.fontColor             = t.textSecondary
        statsLine.verticalAlignmentMode = .center
        statsLine.position              = CGPoint(x: 0, y: 8)
        panel.addChild(statsLine)

        let hs = PointsManager.shared.highScore
        let isNew = score >= hs
        let hsLine = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hsLine.text                  = isNew ? "🏆 NEW BEST!" : "Best: \(hs)"
        hsLine.fontSize              = 16
        hsLine.fontColor             = isNew ? t.accent : t.textSecondary
        hsLine.verticalAlignmentMode = .center
        hsLine.position              = CGPoint(x: 0, y: -14)
        panel.addChild(hsLine)

        // Retry button
        addPanelButton(to: panel, text: "▶  PLAY AGAIN", at: CGPoint(x: 0, y: -52),
                       fill: t.accent, textColor: UIColor(white: 0.1, alpha: 1), name: "retryBtn")

        // Menu button
        addPanelButton(to: panel, text: "MENU", at: CGPoint(x: 0, y: -102),
                       fill: t.buttonFill, textColor: t.textSecondary, name: "menuBtn")
    }

    private func addPanelButton(to panel: SKNode, text: String, at pos: CGPoint,
                                fill: UIColor, textColor: UIColor, name: String) {
        let t  = ThemeManager.shared
        let bg = SKShapeNode(rectOf: CGSize(width: 220, height: 44), cornerRadius: 10)
        bg.fillColor   = fill
        bg.strokeColor = t.buttonStroke
        bg.lineWidth   = 1.5
        bg.position    = pos
        bg.name        = name
        panel.addChild(bg)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text                  = text
        label.fontSize              = 18
        label.fontColor             = textColor
        label.verticalAlignmentMode = .center
        label.name                  = name
        bg.addChild(label)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStart     = touch.location(in: self)
        lastTouchPoint = touchStart
        touchPath      = [touchStart]
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        touchPath.append(loc)
        lastTouchPoint = loc
        drawSliceTrail()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let end = touch.location(in: self)

        // Check game-over buttons first
        let node = atPoint(end)
        switch node.name {
        case "retryBtn":
            SoundManager.shared.playButtonTap()
            let fresh = SlicersGameScene(size: size)
            fresh.scaleMode = .resizeFill
            view?.presentScene(fresh, transition: SKTransition.fade(withDuration: 0.3))
            return
        case "menuBtn":
            SoundManager.shared.playButtonTap()
            let menu = SlicersWelcomeScene(size: size)
            menu.scaleMode = .resizeFill
            view?.presentScene(menu, transition: SKTransition.push(with: .right, duration: 0.35))
            return
        default:
            break
        }

        guard isRunning else { return }

        // Clear visual trail
        sliceTrailNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        sliceTrailNode = nil

        let dx = end.x - touchStart.x
        let dy = end.y - touchStart.y

        // Vertical gestures
        if dy > 50 && abs(dy) > abs(dx) {
            player.jump()
            return
        }
        if dy < -50 && abs(dy) > abs(dx) {
            player.slide()
            return
        }

        // Horizontal / diagonal → SLICE
        if abs(dx) > 25 || touchPath.count > 3 {
            processSlice()
        }

        touchPath = []
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        sliceTrailNode?.removeFromParent()
        sliceTrailNode = nil
        touchPath = []
    }

    // MARK: - Slice Logic

    private func drawSliceTrail() {
        sliceTrailNode?.removeFromParent()
        guard touchPath.count >= 2 else { return }

        let path = CGMutablePath()
        path.move(to: touchPath[0])
        for pt in touchPath.dropFirst() { path.addLine(to: pt) }

        let trail = SKShapeNode(path: path)
        trail.strokeColor = ThemeManager.shared.sliceTrail
        trail.lineWidth   = activePowerUp == .doubleKnives ? 8 : 4
        trail.lineCap     = .round
        trail.zPosition   = 30
        trail.name        = "sliceTrail"
        addChild(trail)
        sliceTrailNode = trail
    }

    private func processSlice() {
        guard touchPath.count >= 2 else { return }

        let sliceStart = touchPath.first!
        let sliceEnd   = touchPath.last!
        let sliceWidth: CGFloat = activePowerUp == .doubleKnives ? 50 : 28

        SoundManager.shared.playSlice()

        var hitSomething = false

        enumerateChildNodes(withName: "obstacle") { [weak self] node, _ in
            guard let self, let obs = node as? ObstacleNode else { return }
            guard obs.obstacleType.isSliceable else { return }

            let obsPos = obs.position
            let dist   = self.pointToLineDistance(point: obsPos, lineA: sliceStart, lineB: sliceEnd)
            if dist < sliceWidth + 20 {
                let destroyed = obs.receiveHit()
                hitSomething  = true
                if destroyed {
                    let pts = obs.obstacleType.scoreValue * self.comboMultiplier()
                    self.score += pts
                    self.combo += 1
                    self.refreshComboLabel()
                    if self.combo >= 2 { SoundManager.shared.playCombo(self.combo) }
                    SoundManager.shared.playObstacleDestroyed(obs.obstacleType)
                    self.spawnSliceFlash(at: obsPos)
                    self.spawnScorePopup(at: CGPoint(x: obsPos.x, y: obsPos.y + 20), points: pts)
                    if self.combo >= 3 { self.screenShake(intensity: min(CGFloat(self.combo) * 0.15, 1.5)) }
                } else {
                    SoundManager.shared.playSlice()
                }
            }
        }

        // Also check enemies
        enumerateChildNodes(withName: "enemy") { [weak self] node, _ in
            guard let self, let enemy = node as? EnemyNode else { return }

            let enemyPos = enemy.position
            let dist = self.pointToLineDistance(point: enemyPos, lineA: sliceStart, lineB: sliceEnd)
            if dist < sliceWidth + 24 {
                let destroyed = enemy.receiveHit()
                hitSomething  = true
                if destroyed {
                    let pts = enemy.enemyType.scoreValue * self.comboMultiplier()
                    self.score += pts
                    self.combo += 1
                    self.refreshComboLabel()
                    if self.combo >= 2 { SoundManager.shared.playCombo(self.combo) }
                    SoundManager.shared.playSlice()
                    self.spawnSliceFlash(at: enemyPos)
                    self.spawnScorePopup(at: CGPoint(x: enemyPos.x, y: enemyPos.y + 20), points: pts)
                    if self.combo >= 3 { self.screenShake(intensity: min(CGFloat(self.combo) * 0.15, 1.5)) }
                }
            }
        }

        if !hitSomething {
            combo = max(0, combo - 1)
            refreshComboLabel()
        }

        updateScoreDisplay()
    }

    private func comboMultiplier() -> Int {
        if combo < 2  { return 1 }
        if combo < 5  { return 2 }
        if combo < 10 { return 3 }
        if combo < 20 { return 4 }
        return 5
    }

    /// Distance from a point to an infinite line defined by two points.
    private func pointToLineDistance(point p: CGPoint, lineA a: CGPoint, lineB b: CGPoint) -> CGFloat {
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let len = hypot(ab.x, ab.y)
        guard len > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        // Project p onto segment
        let t = max(0, min(1, ((p.x - a.x) * ab.x + (p.y - a.y) * ab.y) / (len * len)))
        let proj = CGPoint(x: a.x + t * ab.x, y: a.y + t * ab.y)
        return hypot(p.x - proj.x, p.y - proj.y)
    }

    private func spawnSliceFlash(at pos: CGPoint) {
        // Horizontal slash line
        let flash = SKShapeNode(rectOf: CGSize(width: 60, height: 3), cornerRadius: 1)
        flash.fillColor   = ThemeManager.shared.sliceTrail
        flash.strokeColor = .clear
        flash.position    = pos
        flash.zPosition   = 15
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scaleX(to: 2.5, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
        addChild(flash)

        // Spark/debris particles
        let particleCount = min(combo + 3, 10)
        for _ in 0..<particleCount {
            let spark = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 2...5),
                                                    height: CGFloat.random(in: 2...5)),
                                     cornerRadius: 1)
            spark.fillColor   = [ThemeManager.shared.accent, ThemeManager.shared.sliceTrail,
                                 UIColor.white].randomElement()!
            spark.strokeColor = .clear
            spark.position    = pos
            spark.zPosition   = 16

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist  = CGFloat.random(in: 30...80)
            let dx    = cos(angle) * dist
            let dy    = sin(angle) * dist

            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: Double.random(in: 0.2...0.4)),
                    SKAction.fadeOut(withDuration: 0.35),
                    SKAction.scale(to: 0.2, duration: 0.35)
                ]),
                SKAction.removeFromParent()
            ]))
            addChild(spark)
        }
    }

    // MARK: - Display Updates

    private func spawnScorePopup(at pos: CGPoint, points: Int) {
        let t = ThemeManager.shared
        let mult = comboMultiplier()
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text      = "+\(points)"
        label.fontSize  = mult >= 3 ? 22 : 16
        label.fontColor = mult >= 3 ? t.accent : t.success
        label.position  = pos
        label.zPosition = 25
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 60, duration: 0.6),
                SKAction.sequence([
                    SKAction.fadeIn(withDuration: 0.05),
                    SKAction.wait(forDuration: 0.35),
                    SKAction.fadeOut(withDuration: 0.2)
                ]),
                SKAction.scale(to: 1.3, duration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
        addChild(label)

        if mult >= 2 {
            let multLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            multLabel.text      = "x\(mult)"
            multLabel.fontSize  = 12
            multLabel.fontColor = t.accent.withAlphaComponent(0.8)
            multLabel.position  = CGPoint(x: pos.x + 25, y: pos.y + 8)
            multLabel.zPosition = 25
            multLabel.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 50, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
            addChild(multLabel)
        }
    }

    private func updateScoreDisplay() {
        scoreLabel.text = "\(score)"
    }

    private func updateCoinDisplay() {
        coinLabel.text = "\(coinsCollected)"
    }

    private func refreshComboLabel() {
        if combo >= 2 {
            comboLabel.text = "×\(comboMultiplier()) COMBO x\(combo)!"
            // Color by combo tier
            let t = ThemeManager.shared
            switch comboMultiplier() {
            case 1:  comboLabel.fontColor = t.success
            case 2:  comboLabel.fontColor = UIColor(red: 0.9, green: 0.85, blue: 0.0, alpha: 1)
            case 3:  comboLabel.fontColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
            case 4:  comboLabel.fontColor = t.danger
            default: comboLabel.fontColor = UIColor(red: 0.8, green: 0.2, blue: 0.9, alpha: 1)
            }
            let pop = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.08)
            ])
            comboLabel.run(pop)
        } else {
            comboLabel.text = ""
        }
    }

    private func transitionSky(wave: Int) {
        guard let skySprite else { return }
        // Cycle: dawn(1-3) -> day(4-6) -> dusk(7-9) -> night(10+) then repeat
        let phase = (wave - 1) % 12
        let topColor: UIColor
        let bottomColor: UIColor
        switch phase {
        case 0...2: // Dawn
            topColor    = UIColor(red: 0.15, green: 0.1, blue: 0.25, alpha: 1)
            bottomColor = UIColor(red: 0.9, green: 0.5, blue: 0.3, alpha: 1)
        case 3...5: // Day
            topColor    = UIColor(red: 0.2, green: 0.45, blue: 0.8, alpha: 1)
            bottomColor = UIColor(red: 0.5, green: 0.75, blue: 0.95, alpha: 1)
        case 6...8: // Dusk
            topColor    = UIColor(red: 0.12, green: 0.08, blue: 0.2, alpha: 1)
            bottomColor = UIColor(red: 0.7, green: 0.3, blue: 0.15, alpha: 1)
        default: // Night
            topColor    = ThemeManager.shared.skyTop
            bottomColor = ThemeManager.shared.skyBottom
        }

        let newTexture = makeGradientTexture(size: size, topColor: topColor, bottomColor: bottomColor)
        let newSky = SKSpriteNode(texture: newTexture, size: size)
        newSky.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        newSky.position    = skySprite.position
        newSky.zPosition   = skySprite.zPosition
        newSky.alpha       = 0
        addChild(newSky)
        newSky.run(SKAction.fadeIn(withDuration: 2.0))
        skySprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 2.0),
            SKAction.removeFromParent()
        ]))
        self.skySprite = newSky
    }

    private func showSpeedLines() {
        hideSpeedLines()
        let container = SKNode()
        container.zPosition = 5
        container.name = "speedLines"

        let spawnLine = SKAction.run { [weak self] in
            guard let self else { return }
            let line = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 40...120), height: 1.5))
            line.fillColor   = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.1...0.25))
            line.strokeColor = .clear
            line.position    = CGPoint(x: self.size.width + 60,
                                       y: CGFloat.random(in: self.groundY...self.size.height))
            line.run(SKAction.sequence([
                SKAction.moveTo(x: -80, duration: Double.random(in: 0.2...0.5)),
                SKAction.removeFromParent()
            ]))
            container.addChild(line)
        }

        container.run(SKAction.repeatForever(SKAction.sequence([
            spawnLine,
            SKAction.wait(forDuration: 0.03)
        ])))
        addChild(container)
        speedLinesNode = container
    }

    private func hideSpeedLines() {
        speedLinesNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        speedLinesNode = nil
    }

    private func showWaveBanner(wave: Int) {
        let t = ThemeManager.shared
        let isBossWave = wave >= 5 && wave % 5 == 0

        let banner = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 12)
        banner.fillColor   = (isBossWave ? t.danger : t.accent).withAlphaComponent(0.85)
        banner.strokeColor = .clear
        banner.position    = CGPoint(x: size.width + 160, y: size.height / 2)
        banner.zPosition   = 35

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text      = isBossWave ? "BOSS WAVE \(wave)" : "WAVE \(wave)"
        label.fontSize  = 26
        label.fontColor = UIColor(white: 0.1, alpha: 1)
        label.verticalAlignmentMode = .center
        banner.addChild(label)

        if isBossWave {
            let sub = SKLabelNode(fontNamed: "AvenirNext-Medium")
            sub.text      = "Defeat the boss!"
            sub.fontSize  = 12
            sub.fontColor = UIColor(white: 0.15, alpha: 1)
            sub.verticalAlignmentMode = .center
            sub.position = CGPoint(x: 0, y: -18)
            banner.addChild(sub)
            label.position = CGPoint(x: 0, y: 8)
        }

        banner.run(SKAction.sequence([
            SKAction.moveTo(x: size.width / 2, duration: 0.25),
            SKAction.wait(forDuration: 0.8),
            SKAction.moveTo(x: -160, duration: 0.25),
            SKAction.removeFromParent()
        ]))
        addChild(banner)
    }

    private func flashLabel(_ label: SKLabelNode) {
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12)
        ])
        label.run(pop)
    }

    private func flashScreen(color: UIColor) {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor   = color.withAlphaComponent(0.35)
        overlay.strokeColor = .clear
        overlay.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition   = 35
        overlay.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.03),
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent()
        ]))
        addChild(overlay)
    }

    // MARK: - CoreGraphics Helpers

    private func makeGradientTexture(size: CGSize, topColor: UIColor, bottomColor: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            guard let gradient = CGGradient(colorsSpace: colorSpace,
                                            colors: colors,
                                            locations: locations) else { return }
            cgCtx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end:   CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        return SKTexture(image: image)
    }

    private func makeStarTexture(radius: CGFloat) -> SKTexture {
        let outerRadius = radius * 3.5
        let totalSize   = CGSize(width: outerRadius * 2, height: outerRadius * 2)
        let center      = CGPoint(x: outerRadius, y: outerRadius)
        let renderer    = UIGraphicsImageRenderer(size: totalSize)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            // Outer glow ring
            let glowColors = [UIColor.white.withAlphaComponent(0.35).cgColor,
                              UIColor.white.withAlphaComponent(0.0).cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace,
                                         colors: glowColors,
                                         locations: locations) {
                cgCtx.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: radius * 0.5,
                    endCenter:   center,
                    endRadius:   outerRadius,
                    options:     .drawsBeforeStartLocation
                )
            }
            // Bright core
            let coreColors = [UIColor.white.cgColor,
                              UIColor.white.withAlphaComponent(0.0).cgColor] as CFArray
            if let core = CGGradient(colorsSpace: colorSpace,
                                     colors: coreColors,
                                     locations: locations) {
                cgCtx.drawRadialGradient(
                    core,
                    startCenter: center,
                    startRadius: 0,
                    endCenter:   center,
                    endRadius:   radius,
                    options:     .drawsBeforeStartLocation
                )
            }
        }
        return SKTexture(image: image)
    }
}
