import SpriteKit
import UIKit

final class EnemyNode: SKNode {
    let enemyType: EnemyType
    private(set) var hitsRemaining: Int
    private var visualNode: SKNode!
    private var healthBar: SKShapeNode?
    private var healthFill: SKShapeNode?

    init(type: EnemyType, groundY: CGFloat) {
        self.enemyType     = type
        self.hitsRemaining = type.hitsRequired
        super.init()
        buildVisual(groundY: groundY)
        buildPhysics()
        if type == .drone { startSineWave() }
        if type == .boss  { buildHealthBar() }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Visual

    private func buildVisual(groundY: CGFloat) {
        let container = SKNode()

        switch enemyType {
        case .dummy:
            // Orange humanoid target
            let body = SKShapeNode(rectOf: CGSize(width: 26, height: 40), cornerRadius: 4)
            body.fillColor   = UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1)
            body.strokeColor = UIColor(red: 0.8, green: 0.45, blue: 0.0, alpha: 1)
            body.lineWidth   = 2
            body.position    = CGPoint(x: 0, y: 20)
            container.addChild(body)

            let head = SKShapeNode(circleOfRadius: 12)
            head.fillColor   = UIColor(red: 1.0, green: 0.70, blue: 0.15, alpha: 1)
            head.strokeColor = UIColor(red: 0.8, green: 0.45, blue: 0.0, alpha: 1)
            head.lineWidth   = 1.5
            head.position    = CGPoint(x: 0, y: 48)
            container.addChild(head)

            // Target rings on body
            let ring1 = SKShapeNode(circleOfRadius: 10)
            ring1.fillColor   = .clear
            ring1.strokeColor = UIColor.white.withAlphaComponent(0.5)
            ring1.lineWidth   = 1.5
            ring1.position    = CGPoint(x: 0, y: 20)
            container.addChild(ring1)

            let ring2 = SKShapeNode(circleOfRadius: 5)
            ring2.fillColor   = UIColor.red.withAlphaComponent(0.6)
            ring2.strokeColor = .clear
            ring2.position    = CGPoint(x: 0, y: 20)
            container.addChild(ring2)

            position.y = groundY

            // Idle bob
            let bob = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 0.4),
                SKAction.moveBy(x: 0, y: -3, duration: 0.4)
            ])
            container.run(SKAction.repeatForever(bob))

        case .drone:
            // Gray flying robot
            let body = SKShapeNode(rectOf: CGSize(width: 44, height: 22), cornerRadius: 6)
            body.fillColor   = UIColor(red: 0.3, green: 0.3, blue: 0.45, alpha: 1)
            body.strokeColor = UIColor(red: 0.45, green: 0.45, blue: 0.6, alpha: 1)
            body.lineWidth   = 1.5
            container.addChild(body)

            // Rotors
            for x in [-14.0, 14.0] as [CGFloat] {
                let rotor = SKShapeNode(circleOfRadius: 7)
                rotor.fillColor   = UIColor(white: 0.5, alpha: 0.8)
                rotor.strokeColor = UIColor(white: 0.7, alpha: 0.5)
                rotor.lineWidth   = 1
                rotor.position    = CGPoint(x: x, y: 14)
                rotor.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.2)))
                container.addChild(rotor)
            }

            // Red LED
            let led = SKShapeNode(circleOfRadius: 3)
            led.fillColor   = UIColor.red
            led.strokeColor = .clear
            led.position    = CGPoint(x: 0, y: -8)
            let blink = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: 0.4)
            ])
            led.run(SKAction.repeatForever(blink))
            container.addChild(led)

            position.y = groundY + 80

        case .boss:
            // Large red humanoid with crown
            let body = SKShapeNode(rectOf: CGSize(width: 44, height: 68), cornerRadius: 6)
            body.fillColor   = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
            body.strokeColor = UIColor(red: 0.6, green: 0.05, blue: 0.05, alpha: 1)
            body.lineWidth   = 3
            body.position    = CGPoint(x: 0, y: 34)
            container.addChild(body)

            let head = SKShapeNode(circleOfRadius: 20)
            head.fillColor   = UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)
            head.strokeColor = UIColor(red: 0.6, green: 0.05, blue: 0.05, alpha: 1)
            head.lineWidth   = 2
            head.position    = CGPoint(x: 0, y: 82)
            container.addChild(head)

            // Crown
            let crownPath = CGMutablePath()
            crownPath.move(to:    CGPoint(x: -16, y: 0))
            crownPath.addLine(to: CGPoint(x: -12, y: 18))
            crownPath.addLine(to: CGPoint(x:  -4, y: 8))
            crownPath.addLine(to: CGPoint(x:   0, y: 20))
            crownPath.addLine(to: CGPoint(x:   4, y: 8))
            crownPath.addLine(to: CGPoint(x:  12, y: 18))
            crownPath.addLine(to: CGPoint(x:  16, y: 0))
            crownPath.closeSubpath()
            let crown = SKShapeNode(path: crownPath)
            crown.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1)
            crown.strokeColor = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1)
            crown.lineWidth   = 1.5
            crown.position    = CGPoint(x: 0, y: 100)
            container.addChild(crown)

            // Angry eyes
            for x in [-8.0, 8.0] as [CGFloat] {
                let eye = SKShapeNode(rectOf: CGSize(width: 8, height: 5), cornerRadius: 1)
                eye.fillColor   = UIColor.yellow
                eye.strokeColor = .clear
                eye.position    = CGPoint(x: x, y: 82)
                container.addChild(eye)
            }

            position.y = groundY

            // Menacing idle animation
            let bob = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 4, duration: 0.5),
                SKAction.moveBy(x: 0, y: -4, duration: 0.5)
            ])
            container.run(SKAction.repeatForever(bob))
        }

        addChild(container)
        visualNode = container
    }

    // MARK: - Physics

    private func buildPhysics() {
        let size: CGSize
        switch enemyType {
        case .dummy: size = CGSize(width: 26, height: 58)
        case .drone: size = CGSize(width: 44, height: 22)
        case .boss:  size = CGSize(width: 44, height: 100)
        }
        let center: CGPoint
        switch enemyType {
        case .dummy: center = CGPoint(x: 0, y: 29)
        case .drone: center = .zero
        case .boss:  center = CGPoint(x: 0, y: 50)
        }
        let body = SKPhysicsBody(rectangleOf: size, center: center)
        body.categoryBitMask    = PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask   = PhysicsCategory.none
        body.isDynamic          = false
        physicsBody = body
    }

    // MARK: - Animations

    private func startSineWave() {
        let up   = SKAction.moveBy(x: 0, y: 30, duration: 1.0)
        let down = SKAction.moveBy(x: 0, y: -30, duration: 1.0)
        up.timingMode   = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([up, down])))
    }

    private func buildHealthBar() {
        let barW: CGFloat = 80
        let barY: CGFloat = 125

        let bg = SKShapeNode(rectOf: CGSize(width: barW, height: 8), cornerRadius: 4)
        bg.fillColor   = UIColor(white: 0.2, alpha: 0.8)
        bg.strokeColor = .clear
        bg.position    = CGPoint(x: 0, y: barY)
        addChild(bg)
        healthBar = bg

        let fill = SKShapeNode(rectOf: CGSize(width: barW, height: 8), cornerRadius: 4)
        fill.fillColor   = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        fill.strokeColor = .clear
        fill.position    = CGPoint(x: 0, y: barY)
        addChild(fill)
        healthFill = fill
    }

    // MARK: - Gameplay

    /// Returns true if the enemy is destroyed.
    func receiveHit() -> Bool {
        guard hitsRemaining > 0 else { return false }
        hitsRemaining -= 1

        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.03),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.12)
        ])
        visualNode.run(flash)

        if enemyType == .boss { updateHealthBar() }

        if hitsRemaining <= 0 { explode(); return true }
        return false
    }

    private func updateHealthBar() {
        guard let healthFill else { return }
        let pct  = CGFloat(hitsRemaining) / CGFloat(enemyType.hitsRequired)
        let barW = CGFloat(80) * pct
        let barY: CGFloat = 125

        healthFill.removeFromParent()
        let newFill = SKShapeNode(rectOf: CGSize(width: max(barW, 1), height: 8), cornerRadius: 4)
        newFill.fillColor   = pct > 0.5
            ? UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
            : UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
        newFill.strokeColor = .clear
        newFill.position    = CGPoint(x: -(80 - barW) / 2, y: barY)
        addChild(newFill)
        self.healthFill = newFill
    }

    private func explode() {
        physicsBody = nil
        let color = enemyType == .boss
            ? UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
            : UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1)
        let count = enemyType == .boss ? 16 : 8

        for _ in 0..<count {
            let r = CGFloat.random(in: 2...7)
            let piece = SKShapeNode(circleOfRadius: r)
            piece.fillColor   = color
            piece.strokeColor = .clear
            piece.position    = position
            parent?.addChild(piece)
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let spd   = CGFloat.random(in: 90...250)
            piece.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * spd, y: sin(angle) * spd, duration: 0.45),
                    SKAction.rotate(byAngle: CGFloat.random(in: -.pi * 2 ... .pi * 2), duration: 0.45),
                    SKAction.fadeOut(withDuration: 0.45),
                    SKAction.scale(to: 0.1, duration: 0.45)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
    }
}
