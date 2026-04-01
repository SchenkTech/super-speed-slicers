import SpriteKit
import UIKit

final class CoinNode: SKNode {

    override init() {
        super.init()
        buildVisual()
        buildPhysics()
        startFloat()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Visual

    private func buildVisual() {
        // Outer gold circle
        let outer = SKShapeNode(circleOfRadius: 12)
        outer.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1)
        outer.strokeColor = UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1)
        outer.lineWidth   = 2
        addChild(outer)

        // Inner ring detail
        let inner = SKShapeNode(circleOfRadius: 8)
        inner.fillColor   = UIColor(red: 1.0, green: 0.90, blue: 0.25, alpha: 1)
        inner.strokeColor = UIColor(red: 0.9, green: 0.7, blue: 0.0, alpha: 0.6)
        inner.lineWidth   = 1
        addChild(inner)

        // Shine highlight
        let shine = SKShapeNode(circleOfRadius: 4)
        shine.fillColor   = UIColor.white.withAlphaComponent(0.5)
        shine.strokeColor = .clear
        shine.position    = CGPoint(x: -3, y: 3)
        addChild(shine)

        // Sparkle pulse
        let sparkle = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        outer.run(SKAction.repeatForever(sparkle))

        // Gentle spin (simulated via x-scale oscillation for a 2D "rotation")
        let spinOut = SKAction.scaleX(to: 0.3, duration: 0.4)
        let spinIn  = SKAction.scaleX(to: 1.0, duration: 0.4)
        spinOut.timingMode = .easeInEaseOut
        spinIn.timingMode  = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([spinOut, spinIn])))
    }

    // MARK: - Physics

    private func buildPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 14)
        body.categoryBitMask    = PhysicsCategory.coin
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask   = PhysicsCategory.none
        body.isDynamic          = false
        physicsBody = body
    }

    // MARK: - Animation

    private func startFloat() {
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.7),
            SKAction.moveBy(x: 0, y: -6, duration: 0.7)
        ])
        run(SKAction.repeatForever(float))
    }

    func collect() {
        physicsBody = nil
        SoundManager.shared.playPowerUpPickup()
        run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.6, duration: 0.1),
                SKAction.fadeAlpha(to: 0.8, duration: 0.1)
            ]),
            SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
