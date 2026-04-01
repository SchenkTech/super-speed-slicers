import Foundation
import CoreGraphics

// MARK: - PowerUp Type

enum PowerUpType: String, CaseIterable, Sendable {
    case chainsaw
    case doubleKnives
    case speedBoost
    case shield
    case slowMotion

    var duration: TimeInterval {
        switch self {
        case .chainsaw:     return 7.0
        case .doubleKnives: return 10.0
        case .speedBoost:   return 8.0
        case .shield:       return 0   // consumed on first hit
        case .slowMotion:   return 4.0
        }
    }

    var displayName: String {
        switch self {
        case .chainsaw:     return "CHAINSAW"
        case .doubleKnives: return "DOUBLE KNIVES"
        case .speedBoost:   return "SPEED BOOST"
        case .shield:       return "SHIELD"
        case .slowMotion:   return "SLOW MO"
        }
    }
}

// MARK: - Obstacle Type

enum ObstacleType: CaseIterable, Sendable {
    // Sliceable
    case woodenPlank
    case rope
    case glassPane

    // Hazards (must dodge)
    case spike
    case overheadBar
    case spinningBlade
    case laserBeam
    case barrel
    case swingingAxe

    var isSliceable: Bool {
        switch self {
        case .woodenPlank, .rope, .glassPane: return true
        default: return false
        }
    }

    var hitsRequired: Int {
        switch self {
        case .woodenPlank, .glassPane: return 1
        case .rope:                    return 2
        default:                       return 0
        }
    }

    var scoreValue: Int {
        switch self {
        case .woodenPlank: return 10
        case .rope:        return 25
        case .glassPane:   return 15
        default:           return 0
        }
    }
}

// MARK: - Enemy Type

enum EnemyType: CaseIterable, Sendable {
    case dummy      // stationary target, 1 hit
    case drone      // flies in sine wave, 1 hit
    case boss       // large, multi-hit, appears every 5 waves

    var hitsRequired: Int {
        switch self {
        case .dummy: return 1
        case .drone: return 1
        case .boss:  return 5
        }
    }

    var scoreValue: Int {
        switch self {
        case .dummy: return 20
        case .drone: return 35
        case .boss:  return 200
        }
    }
}

// MARK: - Wave Configuration

struct WaveConfig: Sendable {
    let spawnInterval:    TimeInterval
    let scrollSpeed:      CGFloat
    let obstacleTypes:    [ObstacleType]
    let powerUpChance:    Double
    let enemyChance:      Double
    let coinClusterEvery: Int       // spawn coin cluster every N obstacles

    static func make(wave: Int) -> WaveConfig {
        let t = min(Double(wave) / 20.0, 1.0)
        return WaveConfig(
            spawnInterval:    max(1.8 - t * 0.9, 0.9),
            scrollSpeed:      250 + CGFloat(t) * 350,
            obstacleTypes:    typesForWave(wave),
            powerUpChance:    0.25,
            enemyChance:      wave >= 2 ? min(0.12 + t * 0.15, 0.30) : 0,
            coinClusterEvery: max(3 - wave / 5, 2)
        )
    }

    private static func typesForWave(_ wave: Int) -> [ObstacleType] {
        var types: [ObstacleType] = [.woodenPlank, .spike]
        if wave >= 2  { types.append(.rope) }
        if wave >= 3  { types.append(.overheadBar) }
        if wave >= 4  { types.append(.glassPane) }
        if wave >= 5  { types.append(.barrel) }
        if wave >= 7  { types.append(.laserBeam) }
        if wave >= 8  { types.append(.spinningBlade) }
        if wave >= 10 { types.append(.swingingAxe) }
        return types
    }

    func enemyTypesForWave(_ wave: Int) -> [EnemyType] {
        var types: [EnemyType] = []
        if wave >= 2 { types.append(.dummy) }
        if wave >= 5 { types.append(.drone) }
        return types
    }
}

// MARK: - Run Stats

struct RunStats {
    var score:           Int = 0
    var obstaclesSliced: Int = 0
    var maxCombo:        Int = 0
    var coinsEarned:     Int = 0
}
