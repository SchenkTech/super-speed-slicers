import SpriteKit

final class ObstacleNode: SKNode {
    let obstacleType: ObstacleType
    private(set) var hitsRemaining: Int
    private var visualNode: SKShapeNode!

    /// groundY is the world-space Y of the ground surface
    init(type: ObstacleType, groundY: CGFloat) {
        self.obstacleType = type
        self.hitsRemaining = type.hitsRequired
        super.init()
        buildVisual(groundY: groundY)
        buildPhysics()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Visual

    private func buildVisual(groundY: CGFloat) {
        let t = ThemeManager.shared
        switch obstacleType {

        case .woodenPlank:
            visualNode = SKShapeNode(rectOf: CGSize(width: 22, height: 72), cornerRadius: 3)
            visualNode.fillColor   = t.wood
            visualNode.strokeColor = UIColor(red: 0.4, green: 0.25, blue: 0.08, alpha: 1)
            visualNode.lineWidth   = 2
            // grain lines
            for i in 0...3 {
                let grain = SKShapeNode(rectOf: CGSize(width: 24, height: 1.5))
                grain.fillColor   = UIColor(white: 0, alpha: 0.15)
                grain.strokeColor = .clear
                grain.position.y  = -30 + CGFloat(i) * 20
                visualNode.addChild(grain)
            }
            position.y = groundY + 36

        case .rope:
            visualNode = SKShapeNode(rectOf: CGSize(width: 11, height: 84), cornerRadius: 6)
            visualNode.fillColor   = t.rope
            visualNode.strokeColor = UIColor(red: 0.38, green: 0.30, blue: 0.15, alpha: 1)
            visualNode.lineWidth   = 1
            for i in 0...5 {
                let knot = SKShapeNode(circleOfRadius: 6)
                knot.fillColor   = UIColor(red: 0.50, green: 0.40, blue: 0.22, alpha: 1)
                knot.strokeColor = .clear
                knot.position.y  = -38 + CGFloat(i) * 15
                visualNode.addChild(knot)
            }
            position.y = groundY + 42

        case .glassPane:
            visualNode = SKShapeNode(rectOf: CGSize(width: 14, height: 92), cornerRadius: 2)
            visualNode.fillColor   = t.glass
            visualNode.strokeColor = UIColor(red: 0.80, green: 0.93, blue: 1.0, alpha: 1)
            visualNode.lineWidth   = 2
            let shine = SKShapeNode(rectOf: CGSize(width: 4, height: 82))
            shine.fillColor   = UIColor.white.withAlphaComponent(0.45)
            shine.strokeColor = .clear
            shine.position.x  = -3
            visualNode.addChild(shine)
            position.y = groundY + 46

        case .spike:
            let path = CGMutablePath()
            path.move(to: CGPoint(x:  0, y: 38))
            path.addLine(to: CGPoint(x: -18, y: 0))
            path.addLine(to: CGPoint(x:  18, y: 0))
            path.closeSubpath()
            visualNode = SKShapeNode(path: path)
            visualNode.fillColor   = t.spike
            visualNode.strokeColor = UIColor.white.withAlphaComponent(0.35)
            visualNode.lineWidth   = 1.5
            position.y = groundY

        case .overheadBar:
            // Hangs from top; player must duck under it
            visualNode = SKShapeNode(rectOf: CGSize(width: 64, height: 22), cornerRadius: 4)
            visualNode.fillColor   = UIColor(red: 0.38, green: 0.38, blue: 0.46, alpha: 1)
            visualNode.strokeColor = UIColor(red: 0.55, green: 0.55, blue: 0.65, alpha: 1)
            visualNode.lineWidth   = 2
            // Danger stripes
            for i in 0..<4 {
                let stripe = SKShapeNode(rectOf: CGSize(width: 8, height: 20))
                stripe.fillColor   = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.5)
                stripe.strokeColor = .clear
                stripe.position.x  = -24 + CGFloat(i) * 16
                stripe.zRotation   = 0.3
                visualNode.addChild(stripe)
            }
            position.y = groundY + 90

        case .spinningBlade:
            let path = CGMutablePath()
            for i in 0..<4 {
                let angle = CGFloat(i) * .pi / 2
                let outer: CGFloat = 32
                let inner: CGFloat = 12
                path.move(to: CGPoint(x: cos(angle) * inner,          y: sin(angle) * inner))
                path.addLine(to: CGPoint(x: cos(angle + .pi/4) * outer, y: sin(angle + .pi/4) * outer))
                path.addLine(to: CGPoint(x: cos(angle + .pi/2) * inner, y: sin(angle + .pi/2) * inner))
            }
            path.closeSubpath()
            visualNode = SKShapeNode(path: path)
            visualNode.fillColor   = UIColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 0.9)
            visualNode.strokeColor = UIColor.white.withAlphaComponent(0.5)
            visualNode.lineWidth   = 1.5
            visualNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.9)))
            // Red glow behind blade
            let glow = SKShapeNode(circleOfRadius: 36)
            glow.fillColor   = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.15)
            glow.strokeColor = .clear
            glow.zPosition   = -1
            let glowPulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.08, duration: 0.4),
                SKAction.fadeAlpha(to: 0.2, duration: 0.4)
            ])
            glow.run(SKAction.repeatForever(glowPulse))
            visualNode.addChild(glow)
            position.y = groundY + 55

        case .barrel:
            visualNode = SKShapeNode(rectOf: CGSize(width: 36, height: 44), cornerRadius: 8)
            visualNode.fillColor   = UIColor(red: 0.55, green: 0.28, blue: 0.10, alpha: 1)
            visualNode.strokeColor = UIColor(red: 0.35, green: 0.18, blue: 0.05, alpha: 1)
            visualNode.lineWidth   = 2.5
            for hoop in [-12.0, 0.0, 12.0] as [CGFloat] {
                let band = SKShapeNode(rectOf: CGSize(width: 38, height: 4))
                band.fillColor   = UIColor(red: 0.30, green: 0.15, blue: 0.05, alpha: 1)
                band.strokeColor = .clear
                band.position.y  = hoop
                visualNode.addChild(band)
            }
            position.y = groundY + 22

        case .laserBeam:
            visualNode = SKShapeNode(rectOf: CGSize(width: 8, height: 60), cornerRadius: 4)
            visualNode.fillColor   = UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.9)
            visualNode.strokeColor = UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.6)
            visualNode.lineWidth   = 1.5
            let glow = SKShapeNode(rectOf: CGSize(width: 16, height: 64), cornerRadius: 6)
            glow.fillColor   = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.25)
            glow.strokeColor = .clear
            visualNode.addChild(glow)
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.3),
                SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            ])
            visualNode.run(SKAction.repeatForever(pulse))
            position.y = groundY + 45

        case .swingingAxe:
            let axeHead = SKShapeNode(rectOf: CGSize(width: 28, height: 22), cornerRadius: 3)
            axeHead.fillColor   = UIColor(red: 0.65, green: 0.65, blue: 0.72, alpha: 1)
            axeHead.strokeColor = UIColor.white.withAlphaComponent(0.4)
            axeHead.lineWidth   = 1.5
            axeHead.position    = CGPoint(x: 0, y: -38)
            let handle = SKShapeNode(rectOf: CGSize(width: 6, height: 44), cornerRadius: 2)
            handle.fillColor   = UIColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1)
            handle.strokeColor = .clear
            handle.position    = CGPoint(x: 0, y: -18)
            visualNode = SKShapeNode(rectOf: CGSize(width: 1, height: 1))
            visualNode.fillColor   = .clear
            visualNode.strokeColor = .clear
            visualNode.addChild(handle)
            visualNode.addChild(axeHead)
            let swingRight = SKAction.rotate(toAngle:  0.61, duration: 0.7)
            let swingLeft  = SKAction.rotate(toAngle: -0.61, duration: 0.7)
            swingRight.timingMode = .easeInEaseOut
            swingLeft.timingMode  = .easeInEaseOut
            visualNode.run(SKAction.repeatForever(SKAction.sequence([swingRight, swingLeft])))
            position.y = groundY + 95
        }

        addChild(visualNode)

        // Drop shadow for solid obstacles
        if ([.woodenPlank, .rope, .barrel] as [ObstacleType]).contains(obstacleType) {
            let shadow = SKShapeNode(rectOf: CGSize(width: 30, height: 8), cornerRadius: 4)
            shadow.fillColor   = UIColor.black.withAlphaComponent(0.2)
            shadow.strokeColor = .clear
            shadow.position    = CGPoint(x: 3, y: -(visualNode.position.y) - 2)
            shadow.zPosition   = -1
            addChild(shadow)
        }
    }

    private func buildPhysics() {
        let size: CGSize
        switch obstacleType {
        case .woodenPlank:   size = CGSize(width: 22, height: 72)
        case .rope:          size = CGSize(width: 11, height: 84)
        case .glassPane:     size = CGSize(width: 14, height: 92)
        case .spike:         size = CGSize(width: 28, height: 38)
        case .overheadBar:   size = CGSize(width: 64, height: 22)
        case .spinningBlade: size = CGSize(width: 56, height: 56)
        case .barrel:        size = CGSize(width: 36, height: 44)
        case .laserBeam:     size = CGSize(width: 8,  height: 60)
        case .swingingAxe:   size = CGSize(width: 34, height: 50)
        }
        let body = SKPhysicsBody(rectangleOf: size)
        body.categoryBitMask    = obstacleType.isSliceable ? PhysicsCategory.obstacle : PhysicsCategory.hazard
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask   = PhysicsCategory.none
        body.isDynamic          = false
        physicsBody = body
    }

    // MARK: - Gameplay

    /// Destroys any obstacle type regardless of isSliceable. Used by chainsaw.
    func forceDestroy() {
        physicsBody = nil
        explode()
    }

    /// Returns true if the obstacle is now destroyed.
    func receiveHit() -> Bool {
        guard obstacleType.isSliceable, hitsRemaining > 0 else { return false }
        hitsRemaining -= 1

        // Flash white on hit
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.03),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.12)
        ])
        visualNode.run(flash)

        if hitsRemaining <= 0 { explode(); return true }
        return false
    }

    private func explode() {
        physicsBody = nil
        let isGlass = obstacleType == .glassPane
        let baseColor = isGlass ? ThemeManager.shared.glass : ThemeManager.shared.wood
        let count = isGlass ? 16 : 9

        // Shockwave ring
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.fillColor   = .clear
        ring.strokeColor = baseColor.withAlphaComponent(0.6)
        ring.lineWidth   = 3
        ring.position    = position
        ring.zPosition   = 12
        parent?.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 8, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ]))

        // Debris particles
        let colors = isGlass
            ? [baseColor, UIColor.white.withAlphaComponent(0.7), UIColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.8)]
            : [baseColor, baseColor.withAlphaComponent(0.6)]
        for _ in 0..<count {
            let r = CGFloat.random(in: 2...8)
            let piece: SKShapeNode
            if isGlass && Bool.random() {
                // Triangular glass shards
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: r))
                path.addLine(to: CGPoint(x: -r * 0.7, y: -r * 0.5))
                path.addLine(to: CGPoint(x: r * 0.7, y: -r * 0.5))
                path.closeSubpath()
                piece = SKShapeNode(path: path)
            } else {
                piece = SKShapeNode(rectOf: CGSize(width: r * 2, height: r * 2), cornerRadius: r * 0.4)
            }
            piece.fillColor   = colors.randomElement()!
            piece.strokeColor = .clear
            piece.position    = position
            parent?.addChild(piece)
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let spd   = CGFloat.random(in: 100...260)
            piece.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * spd, y: sin(angle) * spd, duration: 0.5),
                    SKAction.rotate(byAngle: CGFloat.random(in: -.pi * 3 ... .pi * 3), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.05, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Fade out the main visual then remove
        visualNode.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ]))
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
}
