import SpriteKit
import UIKit

final class SlicersWelcomeScene: SKScene {

    override func didMove(to view: SKView) {
        buildBackground()
        buildTitle()
        buildButtons()
        buildHighScore()
        buildAnimatedPlayer()
    }

    // MARK: - Build

    private func buildBackground() {
        let t = ThemeManager.shared
        backgroundColor = .black

        // Sky gradient texture
        let gradTexture = makeGradientTexture(size: size, topColor: t.skyTop, bottomColor: t.skyBottom)
        let gradSprite = SKSpriteNode(texture: gradTexture, size: size)
        gradSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        gradSprite.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        gradSprite.zPosition   = -0.5
        addChild(gradSprite)

        // Ground strip
        let ground = SKShapeNode(rectOf: CGSize(width: size.width, height: 80))
        ground.fillColor   = t.ground
        ground.strokeColor = .clear
        ground.position    = CGPoint(x: size.width / 2, y: 40)
        ground.zPosition   = 1
        addChild(ground)

        // Glowing stars
        let starRadii: [CGFloat] = [1.0, 1.5, 2.0, 2.5]
        let starTextures = starRadii.map { makeStarTexture(radius: $0) }
        for _ in 0..<20 {
            let r = starRadii.randomElement() ?? 1.5
            let tex = starTextures[starRadii.firstIndex(of: r) ?? 0]
            let star = SKSpriteNode(texture: tex, size: CGSize(width: r * 7, height: r * 7))
            star.alpha     = CGFloat.random(in: 0.6...1.0)
            star.position  = CGPoint(x: CGFloat.random(in: 0...size.width),
                                     y: CGFloat.random(in: 100...size.height))
            star.zPosition = 0.5
            // Subtle twinkle
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.3...0.5), duration: Double.random(in: 1.5...3.0)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.7...1.0), duration: Double.random(in: 1.5...3.0))
            ])
            star.run(SKAction.repeatForever(twinkle))
            addChild(star)
        }
    }

    private func buildTitle() {
        let t = ThemeManager.shared

        // Shadow label
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadow.text      = "SUPER SPEED SLICERS"
        shadow.fontSize  = 44
        shadow.fontColor = UIColor.black.withAlphaComponent(0.35)
        shadow.position  = CGPoint(x: size.width / 2 + 3, y: size.height * 0.72 - 3)
        shadow.zPosition = 4
        addChild(shadow)

        // Main title
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text      = "SUPER SPEED SLICERS"
        title.fontSize  = 44
        title.fontColor = t.accent
        title.position  = CGPoint(x: size.width / 2, y: size.height * 0.72)
        title.zPosition = 5

        // Pop animation on entry
        title.setScale(0.3)
        title.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.35),
            SKAction.scale(to: 1.0,  duration: 0.12)
        ]))
        addChild(title)

        // Subtitle
        let sub = SKLabelNode(fontNamed: "AvenirNext-Medium")
        sub.text      = "Slice. Dodge. Survive."
        sub.fontSize  = 18
        sub.fontColor = t.textSecondary
        sub.position  = CGPoint(x: size.width / 2, y: size.height * 0.62)
        sub.zPosition = 5
        sub.alpha      = 0
        sub.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeIn(withDuration: 0.4)
        ]))
        addChild(sub)
    }

    private func buildButtons() {
        let t = ThemeManager.shared
        let centerX = size.width / 2
        let btnHeight: CGFloat = 52
        let btnGap: CGFloat = 16
        // Center the two main buttons vertically around 42% height
        let groupCenter = size.height * 0.42
        let playY = groupCenter + (btnHeight + btnGap) / 2
        let howToY = groupCenter - (btnHeight + btnGap) / 2

        // PLAY button
        addButton(text: "▶  PLAY", at: CGPoint(x: centerX, y: playY),
                  fill: t.accent, stroke: t.accent, textColor: UIColor(white: 0.1, alpha: 1),
                  width: 220, name: "playBtn", fontSize: 22)

        // How to Play button
        addButton(text: "?  HOW TO PLAY", at: CGPoint(x: centerX, y: howToY),
                  fill: t.buttonFill, stroke: t.buttonStroke, textColor: t.textPrimary,
                  width: 220, name: "howToPlayBtn", fontSize: 18)

        // Settings button (small, bottom-right)
        addButton(text: "⚙  SETTINGS", at: CGPoint(x: size.width - 90, y: 45),
                  fill: t.buttonFill, stroke: t.buttonStroke, textColor: t.textSecondary,
                  width: 150, name: "settingsBtn", fontSize: 14)
    }

    private func addButton(text: String, at pos: CGPoint,
                           fill: UIColor, stroke: UIColor, textColor: UIColor,
                           width: CGFloat, name: String, fontSize: CGFloat) {
        let btnSize = CGSize(width: width, height: 52)
        let texture = makeButtonTexture(size: btnSize, fill: fill, stroke: stroke)
        let bg = SKSpriteNode(texture: texture, size: btnSize)
        bg.position  = pos
        bg.zPosition = 10
        bg.name      = name
        addChild(bg)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text                  = text
        label.fontSize              = fontSize
        label.fontColor             = textColor
        label.verticalAlignmentMode = .center
        label.zPosition             = 11
        label.name                  = name
        bg.addChild(label)
    }

    private func buildHighScore() {
        let hs = PointsManager.shared.highScore
        let t  = ThemeManager.shared

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text      = "BEST: \(hs)"
        label.fontSize  = 16
        label.fontColor = t.textSecondary
        label.position  = CGPoint(x: size.width / 2, y: size.height * 0.27)
        label.zPosition = 5
        addChild(label)

        let runs = PointsManager.shared.totalRuns
        if runs > 0 {
            let runsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            runsLabel.text      = "RUNS: \(runs)"
            runsLabel.fontSize  = 13
            runsLabel.fontColor = t.textSecondary.withAlphaComponent(0.7)
            runsLabel.position  = CGPoint(x: size.width / 2, y: size.height * 0.22)
            runsLabel.zPosition = 5
            addChild(runsLabel)
        }
    }

    private func buildAnimatedPlayer() {
        // Small running player demo in the bottom-left
        let t = ThemeManager.shared
        let body = SKShapeNode(rectOf: CGSize(width: 18, height: 28), cornerRadius: 3)
        body.fillColor   = t.playerBody
        body.strokeColor = .clear
        body.position    = CGPoint(x: 55, y: 68)
        body.zPosition   = 3

        let bob = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.14),
            SKAction.moveBy(x: 0, y: -3, duration: 0.14)
        ]))
        body.run(bob)
        addChild(body)

        // Knife
        let knife = SKShapeNode(rectOf: CGSize(width: 3, height: 18), cornerRadius: 1)
        knife.fillColor   = .lightGray
        knife.strokeColor = .clear
        knife.position    = CGPoint(x: 64, y: 68)
        knife.zPosition   = 3
        addChild(knife)
    }

    // MARK: - Touch

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        var node: SKNode? = atPoint(loc)
        while node != nil {
            if let name = node?.name {
                handleButtonTap(name)
                return
            }
            node = node?.parent
        }
    }

    private func handleButtonTap(_ name: String) {
        switch name {
        case "playBtn":
            SoundManager.shared.playButtonTap()
            let game = SlicersGameScene(size: size)
            game.scaleMode = .resizeFill
            let transition = SKTransition.push(with: .left, duration: 0.35)
            view?.presentScene(game, transition: transition)

        case "settingsBtn":
            SoundManager.shared.playButtonTap()
            toggleTheme()

        case "howToPlayBtn":
            SoundManager.shared.playButtonTap()
            showHowToPlay()

        case "closeHowToBtn", "howToPlayOverlay":
            SoundManager.shared.playButtonTap()
            removeChildren(in: [childNode(withName: "howToPlayOverlay") ?? SKNode()])

        default:
            break
        }
    }

    private func toggleTheme() {
        let t = ThemeManager.shared
        t.current = t.current == .dark ? .light : .dark
        // Rebuild scene
        let fresh = SlicersWelcomeScene(size: size)
        fresh.scaleMode = .resizeFill
        view?.presentScene(fresh, transition: SKTransition.fade(withDuration: 0.3))
    }

    private func showHowToPlay() {
        let t = ThemeManager.shared

        // Overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor   = UIColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition   = 50
        overlay.alpha       = 0
        overlay.name        = "howToPlayOverlay"
        overlay.run(SKAction.fadeAlpha(to: 1, duration: 0.2))
        addChild(overlay)

        // Panel
        let panel = SKShapeNode(rectOf: CGSize(width: 300, height: 420), cornerRadius: 16)
        panel.fillColor   = t.panelBG
        panel.strokeColor = t.buttonStroke
        panel.lineWidth   = 2
        panel.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition   = 51
        addChild(panel)

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text      = "HOW TO PLAY"
        title.fontSize  = 24
        title.fontColor = t.textPrimary
        title.position  = CGPoint(x: size.width / 2, y: size.height / 2 + 170)
        title.zPosition = 52
        addChild(title)

        // Instructions
        let instructions = [
            "👆 TAP — Jump over obstacles",
            "👇 SWIPE DOWN — Slide under bars",
            "✂️ SWIPE — Slice obstacles & enemies",
            "⭐ POWER-UPS — Special abilities",
            "🪙 COINS — Bonus score",
            "❤️ LIVES — 3 total, survive long!"
        ]

        var y: CGFloat = 130
        for instruction in instructions {
            let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
            label.text      = instruction
            label.fontSize  = 13
            label.fontColor = t.textSecondary
            label.lineBreakMode = .byWordWrapping
            label.preferredMaxLayoutWidth = 260
            label.horizontalAlignmentMode = .left
            label.position  = CGPoint(x: size.width / 2 - 130, y: size.height / 2 + y)
            label.zPosition = 52
            addChild(label)
            y -= 30
        }

        // Close button
        let closeBtn = SKShapeNode(rectOf: CGSize(width: 140, height: 44), cornerRadius: 10)
        closeBtn.fillColor   = t.accent
        closeBtn.strokeColor = t.accent
        closeBtn.lineWidth   = 2
        closeBtn.position    = CGPoint(x: size.width / 2, y: size.height / 2 - 160)
        closeBtn.zPosition   = 52
        closeBtn.name        = "closeHowToBtn"
        addChild(closeBtn)

        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLabel.text      = "GOT IT"
        closeLabel.fontSize  = 16
        closeLabel.fontColor = UIColor(white: 0.1, alpha: 1)
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position  = CGPoint(x: size.width / 2, y: size.height / 2 - 160)
        closeLabel.zPosition = 53
        closeLabel.name      = "closeHowToBtn"
        addChild(closeLabel)
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

    private func makeButtonTexture(size: CGSize, fill: UIColor, stroke: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let cornerRadius: CGFloat = 12
            let rect = CGRect(origin: .zero, size: size)
            // Rounded rect path
            let path = CGPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5),
                              cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                              transform: nil)
            cgCtx.addPath(path)
            cgCtx.clip()
            // Gradient fill
            let topColor    = fill.blended(withFraction: 0.18, of: UIColor.white)
            let bottomColor = fill.blended(withFraction: 0.12, of: UIColor.black)
            let colorSpace  = CGColorSpaceCreateDeviceRGB()
            let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace,
                                         colors: colors,
                                         locations: locations) {
                cgCtx.drawLinearGradient(gradient,
                                         start: CGPoint(x: 0, y: 0),
                                         end:   CGPoint(x: 0, y: size.height),
                                         options: [])
            }
            // Inner highlight (top edge sheen)
            cgCtx.resetClip()
            let shinePath = CGPath(roundedRect: CGRect(x: 2, y: 2, width: size.width - 4, height: size.height / 2 - 2),
                                   cornerWidth: cornerRadius, cornerHeight: cornerRadius / 2,
                                   transform: nil)
            cgCtx.addPath(shinePath)
            cgCtx.setFillColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            cgCtx.fillPath()
            // Stroke border
            cgCtx.addPath(path)
            cgCtx.setStrokeColor(stroke.cgColor)
            cgCtx.setLineWidth(2)
            cgCtx.strokePath()
        }
        return SKTexture(image: image)
    }
}
