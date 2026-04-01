import SpriteKit

final class PowerUpNode: SKNode {
    let powerUpType: PowerUpType

    init(type: PowerUpType) {
        self.powerUpType = type
        super.init()
        buildVisual()
        buildPhysics()
        startFloat()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildVisual() {
        let t     = ThemeManager.shared
        let color = t.powerUpColor(powerUpType)

        // Outer pulsing ring
        let ring = SKShapeNode(circleOfRadius: 26)
        ring.fillColor   = color.withAlphaComponent(0.18)
        ring.strokeColor = color
        ring.lineWidth   = 2.5
        ring.name        = "ring"
        addChild(ring)

        // Inner filled circle
        let inner = SKShapeNode(circleOfRadius: 18)
        inner.fillColor   = color.withAlphaComponent(0.85)
        inner.strokeColor = UIColor.white.withAlphaComponent(0.5)
        inner.lineWidth   = 1.5
        addChild(inner)

        // Icon symbol
        addChild(makeIcon(for: powerUpType))

        // Label below
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text      = shortName(for: powerUpType)
        label.fontSize  = 9
        label.fontColor = .white
        label.position  = CGPoint(x: 0, y: -40)
        addChild(label)

        // Rotate the outer ring
        ring.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 4.0)))
    }

    private func makeIcon(for type: PowerUpType) -> SKNode {
        switch type {

        case .chainsaw:
            let blade = SKShapeNode(rectOf: CGSize(width: 7, height: 22), cornerRadius: 2)
            blade.fillColor   = UIColor.white.withAlphaComponent(0.9)
            blade.strokeColor = .clear
            blade.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.4)))
            return blade

        case .doubleKnives:
            let container = SKNode()
            for x in [-5.0, 5.0] {
                let b = SKShapeNode(rectOf: CGSize(width: 3.5, height: 16))
                b.fillColor = UIColor.white.withAlphaComponent(0.9); b.strokeColor = .clear
                b.position.x = x; container.addChild(b)
            }
            return container

        case .speedBoost:
            // Lightning bolt
            let path = CGMutablePath()
            path.move(to:    CGPoint(x:  3, y:  10))
            path.addLine(to: CGPoint(x: -2, y:   2))
            path.addLine(to: CGPoint(x:  2, y:   2))
            path.addLine(to: CGPoint(x: -3, y: -10))
            path.addLine(to: CGPoint(x:  4, y:  -2))
            path.addLine(to: CGPoint(x: -1, y:  -2))
            path.closeSubpath()
            let node = SKShapeNode(path: path)
            node.fillColor = UIColor.white.withAlphaComponent(0.9); node.strokeColor = .clear
            return node

        case .shield:
            let node = SKShapeNode(circleOfRadius: 10)
            node.fillColor   = .clear
            node.strokeColor = UIColor.white.withAlphaComponent(0.9)
            node.lineWidth   = 3
            return node

        case .slowMotion:
            // Hourglass shape
            let path = CGMutablePath()
            path.move(to:    CGPoint(x: -9,  y:  9))
            path.addLine(to: CGPoint(x:  9,  y:  9))
            path.addLine(to: CGPoint(x:  0,  y:  0))
            path.addLine(to: CGPoint(x:  9,  y: -9))
            path.addLine(to: CGPoint(x: -9,  y: -9))
            path.addLine(to: CGPoint(x:  0,  y:  0))
            path.closeSubpath()
            let node = SKShapeNode(path: path)
            node.fillColor = UIColor.white.withAlphaComponent(0.85); node.strokeColor = .clear
            return node
        }
    }

    private func shortName(for type: PowerUpType) -> String {
        switch type {
        case .chainsaw:     return "SAW"
        case .doubleKnives: return "×2"
        case .speedBoost:   return "FAST"
        case .shield:       return "SHIELD"
        case .slowMotion:   return "SLOW"
        }
    }

    private func buildPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 26)
        body.categoryBitMask    = PhysicsCategory.powerUp
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask   = PhysicsCategory.none
        body.isDynamic          = false
        physicsBody             = body
    }

    private func startFloat() {
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 9, duration: 0.9),
            SKAction.moveBy(x: 0, y: -9, duration: 0.9)
        ])
        run(SKAction.repeatForever(float))
    }

    func collect() {
        physicsBody = nil
        run(SKAction.sequence([
            SKAction.scale(to: 1.8, duration: 0.12),
            SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
