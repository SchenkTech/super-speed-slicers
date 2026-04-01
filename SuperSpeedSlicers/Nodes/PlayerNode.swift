import SpriteKit
import UIKit

enum PlayerState { case running, jumping, sliding, dead }

extension UIColor {
    func blended(withFraction f: CGFloat, of other: UIColor) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: r1 + (r2 - r1) * f,
            green: g1 + (g2 - g1) * f,
            blue: b1 + (b2 - b1) * f,
            alpha: a1 + (a2 - a1) * f
        )
    }
}

final class PlayerNode: SKNode {
    private var bodyNode: SKShapeNode!
    private var headNode: SKShapeNode!
    private var leftLeg:  SKShapeNode!
    private var rightLeg: SKShapeNode!
    private var armNode:  SKShapeNode!
    private var visor:    SKShapeNode!
    private var weaponNode: SKNode?
    private var shieldNode: SKShapeNode?

    static let jumpHeight: CGFloat = 130

    private(set) var state: PlayerState = .running

    var activePowerUp: PowerUpType? { didSet { refreshWeapon() } }

    var isShielded: Bool = false { didSet { refreshShield() } }

    override init() {
        super.init()
        buildVisuals()
        buildPhysics(sliding: false)
        startRunLoop()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildVisuals() {
        let t = ThemeManager.shared
        let bodyColor = t.playerBody
        let strokeColor = UIColor.white.withAlphaComponent(0.25)

        // Legs (below body)
        leftLeg = SKShapeNode(rectOf: CGSize(width: 8, height: 18), cornerRadius: 3)
        leftLeg.fillColor   = bodyColor.withAlphaComponent(0.85)
        leftLeg.strokeColor = strokeColor
        leftLeg.lineWidth   = 1
        leftLeg.position    = CGPoint(x: -6, y: 2)
        addChild(leftLeg)

        rightLeg = SKShapeNode(rectOf: CGSize(width: 8, height: 18), cornerRadius: 3)
        rightLeg.fillColor   = bodyColor.withAlphaComponent(0.85)
        rightLeg.strokeColor = strokeColor
        rightLeg.lineWidth   = 1
        rightLeg.position    = CGPoint(x: 6, y: 2)
        addChild(rightLeg)

        // Body (torso)
        bodyNode = SKShapeNode(rectOf: CGSize(width: 28, height: 38), cornerRadius: 6)
        bodyNode.fillColor   = .clear
        bodyNode.strokeColor = .clear
        bodyNode.lineWidth   = 0
        bodyNode.position    = CGPoint(x: 0, y: 26)
        addChild(bodyNode)

        // Body sprite with armor gradient
        let bodySprite = makeBodySprite(size: CGSize(width: 28, height: 38), baseColor: bodyColor)
        bodySprite.zPosition = 0
        bodyNode.addChild(bodySprite)

        // Arm
        armNode = SKShapeNode(rectOf: CGSize(width: 7, height: 22), cornerRadius: 3)
        armNode.fillColor   = bodyColor.withAlphaComponent(0.8)
        armNode.strokeColor = strokeColor
        armNode.lineWidth   = 1
        armNode.position    = CGPoint(x: -16, y: 22)
        addChild(armNode)

        // Head
        headNode = SKShapeNode(circleOfRadius: 14)
        headNode.fillColor   = .clear
        headNode.strokeColor = .clear
        headNode.lineWidth   = 0
        headNode.position    = CGPoint(x: 0, y: 52)
        addChild(headNode)

        // Head sprite with gradient sheen
        let headSprite = makeHeadSprite(radius: 14, baseColor: bodyColor.withAlphaComponent(0.92))
        headSprite.zPosition = 0
        headNode.addChild(headSprite)

        // Visor / eye band
        visor = SKShapeNode(rectOf: CGSize(width: 18, height: 5), cornerRadius: 2)
        visor.fillColor   = UIColor.white.withAlphaComponent(0.8)
        visor.strokeColor = .clear
        visor.position    = CGPoint(x: 2, y: 52)
        addChild(visor)

        refreshWeapon()
    }

    private func buildPhysics(sliding: Bool) {
        let size = sliding ? CGSize(width: 36, height: 26) : CGSize(width: 26, height: 70)
        let body = SKPhysicsBody(rectangleOf: size, center: sliding ? CGPoint(x: 0, y: 13) : CGPoint(x: 0, y: 35))
        body.categoryBitMask    = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.hazard | PhysicsCategory.powerUp | PhysicsCategory.enemy | PhysicsCategory.coin
        body.collisionBitMask   = PhysicsCategory.none
        body.allowsRotation    = false
        body.isDynamic         = true
        body.affectedByGravity = false
        body.linearDamping     = 0
        body.angularDamping    = 0
        physicsBody            = body
    }

    private func startRunLoop() {
        // Body bob
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.14),
            SKAction.moveBy(x: 0, y: -3, duration: 0.14)
        ])
        bodyNode.run(SKAction.repeatForever(bob), withKey: "bodyBob")

        // Running legs - alternating stride
        let legForward  = SKAction.rotate(toAngle:  0.45, duration: 0.14)
        let legBackward = SKAction.rotate(toAngle: -0.45, duration: 0.14)
        let legCycle    = SKAction.sequence([legForward, legBackward])
        leftLeg.run(SKAction.repeatForever(legCycle), withKey: "legRun")

        let legCycleR = SKAction.sequence([legBackward, legForward])
        rightLeg.run(SKAction.repeatForever(legCycleR), withKey: "legRun")

        // Arm swing (opposite to legs)
        let armForward  = SKAction.rotate(toAngle:  0.3, duration: 0.14)
        let armBackward = SKAction.rotate(toAngle: -0.3, duration: 0.14)
        armNode.run(SKAction.repeatForever(SKAction.sequence([armForward, armBackward])), withKey: "armSwing")
    }

    private func refreshWeapon() {
        weaponNode?.removeFromParent()
        weaponNode = nil

        switch activePowerUp {
        case .chainsaw:
            let saw = SKShapeNode(rectOf: CGSize(width: 10, height: 52), cornerRadius: 3)
            saw.fillColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1)
            saw.strokeColor = .white; saw.lineWidth = 1
            saw.position = CGPoint(x: 24, y: 30)
            saw.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.25)))
            let glow = SKShapeNode(rectOf: CGSize(width: 14, height: 56), cornerRadius: 3)
            glow.fillColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.3)
            glow.strokeColor = .clear
            glow.position = saw.position
            let container = SKNode(); container.addChild(glow); container.addChild(saw)
            addChild(container); weaponNode = container

        case .doubleKnives:
            let container = SKNode()
            for offsetX in [-6.0, 6.0] {
                let blade = SKShapeNode(rectOf: CGSize(width: 4, height: 28), cornerRadius: 1)
                blade.fillColor = .lightGray
                blade.strokeColor = UIColor.white.withAlphaComponent(0.5)
                blade.lineWidth = 1
                blade.position = CGPoint(x: 22 + offsetX, y: 30)
                container.addChild(blade)
            }
            addChild(container); weaponNode = container

        default:
            let bladeSprite = makeBladeSprite(size: CGSize(width: 4, height: 30))
            bladeSprite.position = CGPoint(x: 22, y: 30)
            addChild(bladeSprite); weaponNode = bladeSprite
        }
    }

    private func refreshShield() {
        shieldNode?.removeFromParent()
        shieldNode = nil
        guard isShielded else { return }
        let ring = SKShapeNode(circleOfRadius: 44)
        ring.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.18)
        ring.strokeColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.85)
        ring.lineWidth = 2.5
        ring.position = CGPoint(x: 0, y: 33)
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.7),
            SKAction.fadeAlpha(to: 1.0, duration: 0.7)
        ])
        ring.run(SKAction.repeatForever(pulse))
        addChild(ring); shieldNode = ring
    }

    // MARK: - Actions

    func jump() {
        guard state == .running else { return }
        state = .jumping
        SoundManager.shared.playJump()
        let up   = SKAction.moveBy(x: 0, y: PlayerNode.jumpHeight, duration: 0.30)
        let down = SKAction.moveBy(x: 0, y: -PlayerNode.jumpHeight, duration: 0.36)
        up.timingMode   = .easeOut
        down.timingMode = .easeIn
        run(SKAction.sequence([up, down, SKAction.run { [weak self] in
            self?.state = .running
        }]))
    }

    func slide() {
        guard state == .running else { return }
        state = .sliding
        bodyNode.yScale = 0.5
        bodyNode.position.y = 10
        headNode.position.y = 27
        visor.position.y = 27
        leftLeg.isHidden  = true
        rightLeg.isHidden = true
        armNode.isHidden  = true
        buildPhysics(sliding: true)
        let wait = SKAction.wait(forDuration: 0.85)
        run(SKAction.sequence([wait, SKAction.run { [weak self] in self?.forceEndSlide() }]))
    }

    func forceEndSlide() {
        guard state == .sliding else { return }
        state = .running
        bodyNode.yScale = 1; bodyNode.position.y = 26
        headNode.position.y = 52
        visor.position.y = 52
        leftLeg.isHidden  = false
        rightLeg.isHidden = false
        armNode.isHidden  = false
        buildPhysics(sliding: false)
    }

    func flashHit() {
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.9, duration: 0.04),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.25)
        ])
        bodyNode.run(flash)
        headNode.run(flash.copy() as! SKAction)
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -7, y: 0, duration: 0.04),
            SKAction.moveBy(x: 14, y: 0, duration: 0.04),
            SKAction.moveBy(x: -7, y: 0, duration: 0.04)
        ])
        run(shake)
    }

    func die() {
        state = .dead
        physicsBody = nil
        // Stop all running animations
        leftLeg.removeAllActions()
        rightLeg.removeAllActions()
        armNode.removeAllActions()
        bodyNode.removeAction(forKey: "bodyBob")

        run(SKAction.sequence([
            SKAction.group([
                SKAction.rotate(byAngle: .pi * 1.5, duration: 0.5),
                SKAction.moveBy(x: 0, y: 60, duration: 0.25)
            ]),
            SKAction.moveBy(x: 0, y: -160, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.25)
        ]))
    }

    // MARK: - CoreGraphics Helpers

    private func makeHeadSprite(radius: CGFloat, baseColor: UIColor) -> SKSpriteNode {
        let diameter = radius * 2 + 4
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            // Clip to circle
            let circlePath = CGPath(ellipseIn: CGRect(x: 2, y: 2,
                                                       width: diameter - 4, height: diameter - 4),
                                    transform: nil)
            cgCtx.addPath(circlePath)
            cgCtx.clip()
            // Base fill
            cgCtx.setFillColor(baseColor.cgColor)
            cgCtx.fill(CGRect(origin: .zero, size: size))
            // Radial highlight
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let highlightColors = [UIColor.white.withAlphaComponent(0.65).cgColor,
                                   UIColor.white.withAlphaComponent(0.0).cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace,
                                         colors: highlightColors,
                                         locations: locations) {
                cgCtx.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.3),
                    startRadius: 0,
                    endCenter:   center,
                    endRadius:   radius,
                    options:     .drawsBeforeStartLocation
                )
            }
            // Stroke rim
            cgCtx.resetClip()
            cgCtx.addPath(circlePath)
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            cgCtx.setLineWidth(1.5)
            cgCtx.strokePath()
        }
        return SKSpriteNode(texture: SKTexture(image: image), size: size)
    }

    private func makeBodySprite(size: CGSize, baseColor: UIColor) -> SKSpriteNode {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let cornerRadius: CGFloat = 6
            let path = CGPath(roundedRect: CGRect(origin: .zero, size: size),
                              cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            cgCtx.addPath(path)
            cgCtx.clip()
            // Gradient
            let topColor    = baseColor.blended(withFraction: 0.25, of: UIColor.white)
            let bottomColor = baseColor.blended(withFraction: 0.25, of: UIColor.black)
            let colorSpace  = CGColorSpaceCreateDeviceRGB()
            let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace,
                                         colors: colors,
                                         locations: locations) {
                cgCtx.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end:   CGPoint(x: 0, y: size.height),
                    options: []
                )
            }
            // Highlight stripe
            cgCtx.resetClip()
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.18).cgColor)
            cgCtx.setLineWidth(1)
            cgCtx.move(to: CGPoint(x: size.width * 0.25, y: cornerRadius))
            cgCtx.addLine(to: CGPoint(x: size.width * 0.25, y: size.height - cornerRadius))
            cgCtx.strokePath()
        }
        return SKSpriteNode(texture: SKTexture(image: image), size: size)
    }

    private func makeBladeSprite(size: CGSize) -> SKSpriteNode {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let path = CGPath(roundedRect: CGRect(origin: .zero, size: size),
                              cornerWidth: 1, cornerHeight: 1, transform: nil)
            cgCtx.addPath(path)
            cgCtx.clip()
            // Metallic gradient
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(white: 0.62, alpha: 1).cgColor,
                UIColor(white: 0.98, alpha: 1).cgColor,
                UIColor(white: 0.72, alpha: 1).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.45, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace,
                                         colors: colors,
                                         locations: locations) {
                cgCtx.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end:   CGPoint(x: size.width, y: 0),
                    options: []
                )
            }
        }
        return SKSpriteNode(texture: SKTexture(image: image), size: size)
    }
}
