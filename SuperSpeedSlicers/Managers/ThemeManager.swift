import UIKit

@MainActor
final class ThemeManager {
    static let shared = ThemeManager()
    private init() {}

    enum Theme: String { case dark, light }

    var current: Theme {
        get { Theme(rawValue: UserDefaults.standard.string(forKey: SlicersKeys.theme) ?? "dark") ?? .dark }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: SlicersKeys.theme) }
    }

    // Background & surface
    var background: UIColor  { current == .dark ? UIColor(white: 0.07, alpha: 1) : UIColor(white: 0.93, alpha: 1) }
    var skyTop:     UIColor  { current == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1)
                                                : UIColor(red: 0.45, green: 0.70, blue: 0.95, alpha: 1) }
    var skyBottom:  UIColor  { current == .dark ? UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1)
                                                : UIColor(red: 0.65, green: 0.85, blue: 1.00, alpha: 1) }
    var ground:     UIColor  { current == .dark ? UIColor(red: 0.12, green: 0.18, blue: 0.12, alpha: 1)
                                                : UIColor(red: 0.30, green: 0.55, blue: 0.25, alpha: 1) }

    // Text
    var textPrimary:   UIColor { current == .dark ? .white : UIColor(white: 0.10, alpha: 1) }
    var textSecondary: UIColor { current == .dark ? UIColor(white: 0.60, alpha: 1) : UIColor(white: 0.40, alpha: 1) }

    // Buttons / panels
    var panelBG:      UIColor { current == .dark ? UIColor(white: 0.12, alpha: 0.92) : UIColor(white: 0.96, alpha: 0.92) }
    var buttonFill:   UIColor { current == .dark ? UIColor(white: 0.20, alpha: 1) : UIColor(white: 0.82, alpha: 1) }
    var buttonStroke: UIColor { current == .dark ? UIColor(white: 0.40, alpha: 1) : UIColor(white: 0.35, alpha: 1) }

    // Accent & status
    var accent:  UIColor { UIColor(red: 1.00, green: 0.80, blue: 0.00, alpha: 1) }  // gold
    var success: UIColor { UIColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 1) }
    var danger:  UIColor { UIColor(red: 0.95, green: 0.20, blue: 0.20, alpha: 1) }

    // Player
    var playerBody: UIColor { UIColor(red: 0.30, green: 0.70, blue: 1.00, alpha: 1) }
    var sliceTrail: UIColor { UIColor(red: 1.00, green: 1.00, blue: 0.80, alpha: 0.95) }

    // Obstacles
    var wood:  UIColor { UIColor(red: 0.70, green: 0.45, blue: 0.20, alpha: 1) }
    var rope:  UIColor { UIColor(red: 0.60, green: 0.50, blue: 0.30, alpha: 1) }
    var glass: UIColor { UIColor(red: 0.70, green: 0.90, blue: 1.00, alpha: 0.75) }
    var spike: UIColor { UIColor(red: 0.65, green: 0.65, blue: 0.70, alpha: 1) }

    // Enemies
    var enemyDummy: UIColor { UIColor(red: 1.00, green: 0.65, blue: 0.00, alpha: 1) }
    var enemyDrone: UIColor { UIColor(red: 0.30, green: 0.30, blue: 0.45, alpha: 1) }
    var enemyBoss:  UIColor { UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1) }

    // Coins
    var coinGold: UIColor { UIColor(red: 1.00, green: 0.85, blue: 0.00, alpha: 1) }

    // Power-ups
    func powerUpColor(_ type: PowerUpType) -> UIColor {
        switch type {
        case .chainsaw:     return UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1)
        case .doubleKnives: return UIColor(red: 0.8, green: 0.2, blue: 0.9, alpha: 1)
        case .speedBoost:   return UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1)
        case .shield:       return UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1)
        case .slowMotion:   return UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1)
        }
    }
}
