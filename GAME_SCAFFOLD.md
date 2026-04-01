# Game Design Scaffold

Standard design scaffold for building new physics-puzzle games in this family. Derived from the shared patterns across Fulcrum, Pendulum, and Arch.

---

## 1. Core Identity

Every game in this family is a **physics-based puzzle game** for iOS where the player arranges pieces during a setup phase, then watches physics resolve to determine success. The games share a tactile, minimalist aesthetic with procedural visuals and synthesized audio.

**Defining characteristics:**
- One core physics mechanic explored deeply across 100-150 levels
- Two-phase gameplay: **Place** then **Simulate**
- Difficulty through new constraints, not new controls
- No timers during placement; pressure only during simulation
- Satisfying physicality: things swing, fall, balance, collapse

---

## 2. Tech Stack

| Component | Standard |
|-----------|----------|
| Language | Swift 6.0 |
| Engine | SpriteKit |
| Platform | iOS 16.0+, iPhone + iPad |
| Build system | XcodeGen (`project.yml`) |
| Dependencies | Zero external; Apple frameworks only |
| Physics | SKPhysicsWorld / SKPhysicsBody |
| Audio | AVAudioEngine (real-time sine synthesis) |
| Persistence | UserDefaults + NSUbiquitousKeyValueStore |
| Leaderboards | GameKit (Game Center) |
| Security | CryptoKit (SHA256 score integrity) |
| Testing | XCTest (unit + UI) |
| Orientation | Portrait primary, landscape supported on iPad |

---

## 3. Project Structure

```
<GameName>/
├── <GameName>/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── GameViewController.swift
│   ├── Info.plist
│   ├── <GameName>.entitlements
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/
│   ├── Scenes/
│   │   ├── <Game>WelcomeScene.swift
│   │   ├── <Game>LevelSelectScene.swift
│   │   ├── <Game>GameScene.swift
│   │   ├── <Game>SettingsScene.swift
│   │   └── <Game>TutorialScene.swift
│   ├── Nodes/
│   │   └── (game-specific SKNode subclasses)
│   ├── Models/
│   │   ├── <Game>Models.swift       (level data structs, Codable)
│   │   ├── PhysicsCategory.swift    (UInt32 bitmasks)
│   │   └── SafeArea.swift           (optional helper)
│   └── Managers/
│       ├── <Game>Keys.swift         (UserDefaults key enum)
│       ├── <Game>LevelManager.swift (load levels, track progress)
│       ├── CampaignLevelGenerator.swift
│       ├── ZenLevelGenerator.swift
│       ├── <Game>Checker.swift      (win/loss detection per frame)
│       ├── SoundManager.swift
│       ├── ThemeManager.swift
│       ├── PointsManager.swift
│       ├── CloudSyncManager.swift
│       ├── GameCenterManager.swift
│       └── ScoreIntegrity.swift
├── <GameName>Tests/
│   ├── GameLogicTests.swift
│   ├── LevelGeneratorTests.swift
│   └── ModelTests.swift
├── <GameName>UITests/
│   └── <GameName>UITests.swift
├── project.yml
├── .gitignore
├── .swiftlint.yml
├── .pre-commit-config.yaml
├── generate_icon.swift
└── README.md
```

**Naming convention:** Prefix all public types with the game name (e.g., `ArchGameScene`, `PendulumLevelManager`) to avoid collisions if code is ever shared.

---

## 4. Scene Architecture

Five scenes, each an `SKScene` subclass. Navigation via `SKTransition.push`.

### 4.1 WelcomeScene
- Animated background showcasing the core mechanic (e.g., a swinging pendulum, a balancing beam)
- Mode buttons: **Play/Continue**, **Zen**, **Daily Challenge**
  - If `highestCompletedLevel > 0`, show **"Continue"** instead of "Play" and launch directly into level `highestCompletedLevel + 1` (skip level select). Falls back to level select if all levels are completed.
  - First-time players see **"Play"** and go to LevelSelectScene.
- Secondary buttons: **Tutorial**, **Settings**
- Total points/stars display

### 4.2 LevelSelectScene
- Grid of level buttons organized into **10 worlds** of 10-15 levels each
- World names reflecting the mechanic progression (e.g., "First Steps" -> "Grand Master")
- Each level button shows star/gem rating (0-3)
- World unlock gates based on cumulative stars/gems
- Gate thresholds increase non-linearly (e.g., 0, 15, 40, 70, 105, 145, 190, 240, 300, 370)
- Sequential level unlock within a world

### 4.3 GameScene (main gameplay)
- The largest file (~1000-2200 lines); contains the game loop
- **Layout layers** (by zPosition):
  - Background (z=0)
  - Play area / game objects (z=1-10)
  - Hand panel with draggable pieces (z=5-10)
  - HUD: level label, points, progress indicators, action buttons (z=15-25)
  - Overlays: win/loss cards, tutorials, directions (z=50)
- **Game phase state machine** (see Section 5)
- Touch handling: drag from hand to play area, two-finger tap to undo
- Buttons: GO/BUILD/SWING, Reset, Shuffle, Hint, Back

### 4.4 SettingsScene
- Theme toggle (dark/light)
- Sound toggle
- Haptics toggle
- Reset progress (with confirmation)

### 4.5 TutorialScene
- Multi-page (5-7 pages) interactive walkthrough
- Page dots for navigation
- Auto-shown on first launch (`sawTutorial` flag)
- Accessible from WelcomeScene at any time

---

## 5. Game Phase State Machine

Every game follows a two-phase model with four states:

```
                 ┌──────────┐
        ┌────────│  PLACING  │◄────────┐
        │        └────┬─────┘         │
        │             │ (trigger)     │ (retry)
        │             ▼               │
        │     ┌──────────────┐        │
        │     │  SIMULATING  │────────┤
        │     └──┬───────┬───┘        │
        │        │       │            │
        │        ▼       ▼            │
        │  ┌────────┐ ┌────────┐      │
        │  │  WIN   │ │  LOSE  │──────┘
        │  └───┬────┘ └────────┘
        │      │ (next level)
        └──────┘
```

### Placing Phase
- Beam/arm/arch is frozen (no physics)
- Hand panel visible with draggable pieces
- Shuffle and hint buttons available
- Undo stack tracks placement order
- No time pressure

### Simulating Phase
- Physics enabled; game objects respond to forces
- Hand panel hidden
- Progress indicator shows stability/balance timer
- **Checker** evaluates win/loss conditions each frame
- No player interaction (watch and wait)

### Win
- Overlay with score, stars/gems, celebration animation
- Points awarded, progress saved, leaderboard submitted
- Buttons: Next Level, Replay, Level Select

### Lose
- Overlay with failure message
- Visual feedback (flash red, shake, collapse particles)
- Buttons: Retry, Level Select
- Zen mode: streak resets

---

## 6. Level Design System

### 6.1 Data Model

Every game defines a `Level` struct (Codable) containing at minimum:

```swift
struct Level: Codable {
    let id: Int
    let description: String

    // Game-specific geometry/configuration
    // ...

    // Pieces dealt to the player
    let hand: [Int]           // values/weights

    // Physics modifiers
    let gravityModifier: Double
    // ... game-specific modifiers

    // Win condition parameters
    let stabilityTimeRequired: TimeInterval  // typically 2.5-3.0s
    let minimumValue: Int                    // or equivalent threshold

    // Scoring
    let starThresholds: StarThresholds       // 1/2/3 star score targets
}
```

### 6.2 Campaign Levels (100-150 levels)

- **Procedurally generated** using a **seeded RNG** (LCG algorithm)
- Seed derived from level ID: `id * constant + offset` (e.g., `id * 7919 + 31337`)
- Organized into **10 worlds** with progressive mechanics introduction
- Each world introduces or combines one mechanic
- Difficulty curve within each world: `(levelIndex) / (worldSize - 1)` -> 0.0 to 1.0
- Parameters lerp'd between easy and hard values based on difficulty
- **Validation pass** ensures all levels are completable:
  - Symmetric solutions where applicable
  - Reachability checks for targets/slots
  - Weight/force thresholds within hand capabilities

### 6.3 World Progression Template

| World | Theme | New Mechanic |
|-------|-------|-------------|
| 1 | Tutorial / First Steps | Core mechanic only, minimal complexity |
| 2 | Intermediate basics | Introduce secondary variable (weight, count, etc.) |
| 3 | Movement / variation | Moving elements or modified geometry |
| 4 | Timing / gating | Time-based or conditional elements |
| 5 | Obstacles / constraints | Destructible or blocking elements |
| 6 | Compound / chaining | Multiple instances of the core mechanic |
| 7 | Physics variation | Gravity, friction, or force modifiers |
| 8 | Combination | Mix mechanics from worlds 3-7 |
| 9 | Expert | Tight margins, all mechanics available |
| 10 | Grand Master | Maximum difficulty, full mechanic set |

### 6.4 Zen Mode
- Infinite procedurally-generated levels
- Streak counter (resets on any loss)
- Difficulty scales with streak:
  - Streak 0-3: Minimal complexity
  - Streak 4-9: Moderate
  - Streak 10-15: High
  - Streak 16+: Maximum
- Seeded from random or streak-based value

### 6.5 Daily Challenge
- One level per day, seeded from date: `year * 10000 + month * 100 + day`
- Moderate difficulty (not trivial, not expert)
- Flat reward (e.g., 200 points), no star rating
- Completion tracked by date string in UserDefaults

---

## 7. Scoring & Progression

### 7.1 Per-Level Scoring

```
baseScore     = 100-200 points (completion)
speedBonus    = f(solveTime)     // faster = more points
efficiencyBonus = f(unusedPieces) // fewer pieces used = more points
specialBonus  = f(game-specific) // symmetry, precision, etc.
totalScore    = base + speed + efficiency + special
```

### 7.2 Star/Gem Tiers (3-tier rating)

| Tier | Criteria | Visual |
|------|----------|--------|
| 1 (Bronze/Raw) | Complete the level | Minimal |
| 2 (Silver/Polished) | Good score or speed | Medium |
| 3 (Gold/Diamond) | Excellent score or speed | Full |

Best rating per level is persisted; only improves, never decreases.

### 7.3 Progression Unlocks
- Levels unlock sequentially within a world
- Worlds unlock via cumulative star/gem gates
- Gate thresholds should be achievable with ~1.5 stars average on prior worlds

---

## 8. Manager Singletons

Each manager follows the pattern:
```swift
@MainActor
final class <Name>Manager {
    static let shared = <Name>Manager()
    private init() { ... }
}
```

### 8.1 Required Managers

| Manager | Responsibility |
|---------|---------------|
| **`<Game>LevelManager`** | Load levels, track highestCompletedLevel, per-level stars |
| **`<Game>Checker`** | Per-frame win/loss evaluation during simulation phase |
| **`SoundManager`** | AVAudioEngine sine synthesis, sound event methods |
| **`ThemeManager`** | Dark/light color palette, persisted toggle |
| **`PointsManager`** | Total points accumulator |
| **`CloudSyncManager`** | iCloud NSUbiquitousKeyValueStore, take-max merge strategy |
| **`GameCenterManager`** | Authentication, leaderboard submission |
| **`ScoreIntegrity`** | SHA256 hash of key scores, reset-if-tampered on launch |
| **`<Game>Keys`** | Enum of all UserDefaults key strings |

### 8.2 Initialization Order (AppDelegate)

1. ThemeManager (apply saved theme)
2. SoundManager (configure audio session)
3. PointsManager (load scores)
4. ScoreIntegrity.verify() (reset if tampered)
5. CloudSyncManager.setup() (register for iCloud notifications, pull)
6. GameCenterManager.authenticate()

---

## 9. Rendering & Visual Style

### 9.1 All Procedural Graphics
- **No raster image assets** (except app icon)
- All game objects drawn via `SKShapeNode`, `SKSpriteNode`, `SKLabelNode`
- Colors defined in `ThemeManager` and per-object color functions
- Particle effects via temporary `SKShapeNode` circles or `SKEmitterNode`

### 9.2 Theme System

Two themes: **Dark** (default) and **Light**. ThemeManager provides:

```swift
var background: UIColor
var textPrimary: UIColor
var textSecondary: UIColor
var panelBackground: UIColor
var buttonFill: UIColor
var buttonStroke: UIColor
var successColor: UIColor   // green
var dangerColor: UIColor    // red
var accentColor: UIColor    // game-specific highlight
```

### 9.3 Layout Rules
- Respect `safeAreaInsets` for notch/home indicator
- Hand panel at bottom, HUD at top
- Dynamic sizing based on `scene.size`
- Support both portrait and landscape

### 9.4 Animation Patterns
- `SKAction` sequences and groups
- Timing: `.easeOut` for snappy interactions, `.linear` for steady motion
- Cascading delays for staggered reveals
- Scale pop (1.0 -> 1.3 -> 1.0) for emphasis
- Fade + move for overlays

---

## 10. Audio Design

### 10.1 Synthesis (no audio files)

All sounds generated in real-time via `AVAudioEngine` + `AVAudioPlayerNode`:
- Sine wave generation with quadratic fade-out envelope
- Chords via overlapping tones with staggered start times

### 10.2 Standard Sound Events

| Event | Frequency Range | Duration | Haptic |
|-------|----------------|----------|--------|
| Piece pickup | 600-700 Hz | 40-60ms | Light |
| Piece place | 400-500 Hz | 80-120ms | Medium |
| Piece snap to slot | 500-550 Hz | 60-80ms | Medium |
| Simulation start | 300-400 Hz | 100ms | Light |
| Success event | Chord (C-E-G) | 400-600ms | Success notification |
| Failure event | ~200 Hz | 250-400ms | Error notification |
| Button tap | 800-900 Hz | 30ms | Light |
| Undo | 300-350 Hz | 60ms | Light |

### 10.3 Settings
- `soundEnabled` (default: true)
- `hapticsEnabled` (default: true)
- Independent toggles (haptics work in silent mode)

---

## 11. Persistence & Services

### 11.1 UserDefaults Keys (via `<Game>Keys` enum)

```swift
enum <Game>Keys {
    // Progress
    static let highestCompletedLevel = "<game>.highestCompletedLevel"
    static let currentLevel = "<game>.currentLevel"
    static let totalPoints = "<game>.totalPoints"
    static let levelStars = "<game>.levelStars"      // Dictionary<String, Int>
    static let zenBestStreak = "<game>.zenBestStreak"
    static let zenCurrentStreak = "<game>.zenCurrentStreak"
    static let dailyLastCompleted = "<game>.dailyLastCompleted"

    // Settings
    static let soundEnabled = "<game>.soundEnabled"
    static let hapticsEnabled = "<game>.hapticsEnabled"
    static let theme = "<game>.theme"

    // Onboarding
    static let sawTutorial = "<game>.sawTutorial"

    // Integrity
    static let scoreHash = "<game>.scoreHash"
}
```

### 11.2 iCloud Sync (CloudSyncManager)
- Sync keys: highestCompletedLevel, totalPoints, zenBestStreak, per-level stars
- **Merge strategy: take-max** (never overwrite a higher value)
- Push after each level completion
- Pull on app launch and on `NSUbiquitousKeyValueStore.didChangeExternally`

### 11.3 Game Center (GameCenterManager)
- Authenticate on launch
- Leaderboard IDs: `com.<game>.game.totalpoints`, `com.<game>.game.totalstars`, `com.<game>.game.zenstreak`
- Submit after level complete (points + stars) and zen complete (streak)
- Skip on simulator

### 11.4 Score Integrity (ScoreIntegrity)
- Hash: `SHA256("<salt>:points:\(p),stars:\(s),zen:\(z)")`
- `verify()` on launch; `resetIfTampered()` zeros all scores if mismatch
- `save()` after every score change

---

## 12. Win/Loss Checker Pattern

Each game implements a Checker class that runs every frame during simulation:

```swift
@MainActor
final class <Game>Checker {
    enum GameState { case playing, levelComplete, gameOver }

    var state: GameState = .playing
    private var stableTime: TimeInterval = 0

    func update(deltaTime: TimeInterval) {
        // 1. Check immediate failure condition
        //    (e.g., beam tipped > 45 deg, stone fell off screen, time expired)
        //    -> state = .gameOver

        // 2. Check success condition
        //    (e.g., balanced within threshold, all targets hit, arch standing)
        //    If met: accumulate stableTime += deltaTime
        //    If not: reset stableTime = 0

        // 3. If stableTime >= requiredTime -> state = .levelComplete
    }

    func reset() {
        state = .playing
        stableTime = 0
    }
}
```

**Key parameters to define per game:**
- Success threshold (angle, velocity, hit count, etc.)
- Required stability duration (typically 2.5-3.0 seconds)
- Failure threshold (max angle, timeout, etc.)
- Maximum simulation time (10-15 seconds)

---

## 13. Touch Handling Pattern

```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // Two-finger tap -> undo last placement
    // Single touch -> check if touching a hand piece or button
}

override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    // If dragging a piece: update position, show snap preview if near slot
}

override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // If over valid slot: snap piece into place, play sound + haptic
    // If over hand panel: return piece to hand
    // If button: execute action
    // Auto-trigger simulation if all slots filled (optional)
}
```

**Standard interactions:**
- Drag from hand panel to play area
- Snap to slot with visual + audio feedback
- Two-finger tap to undo last placement
- Shuffle button randomizes hand order
- Hint button highlights correct placement (optional)

---

## 14. Testing Strategy

### Unit Tests
- **LevelGeneratorTests**: Verify seeded RNG produces identical levels, all levels parseable
- **GameLogicTests**: Checker thresholds, score calculations, star tier boundaries
- **ModelTests**: Codable round-trips, edge cases
- **ScoreIntegrityTests**: Hash verification, tamper detection
- **ManagerTests**: Theme toggle, sound state, key persistence

### UI Tests
- Scene smoke tests (each scene loads without crash)
- Screenshot tests for App Store assets

---

## 15. New Game Checklist

When starting a new game in this family:

1. **Define the core mechanic** - One physics interaction explored in depth
2. **Name the game** - Short, evocative, physics-related (e.g., Lever, Pulley, Spring)
3. **Scaffold the project** - Copy the directory structure from Section 3
4. **Create `project.yml`** - iOS 16+, Swift 6.0, SpriteKit + standard frameworks
5. **Implement Managers** - Copy and adapt Keys, Theme, Sound, Points, CloudSync, GameCenter, ScoreIntegrity
6. **Build WelcomeScene** - Animated demo of the core mechanic
7. **Build GameScene** - Place/Simulate state machine, touch handling, HUD
8. **Define the Level model** - Codable struct with game-specific parameters
9. **Build the Checker** - Per-frame win/loss evaluation for the specific mechanic
10. **Build Node subclasses** - Visual + physics for game-specific objects
11. **Create CampaignLevelGenerator** - Seeded RNG, 10 worlds, difficulty curve, validation
12. **Build LevelSelectScene** - Grid with star display and world gates
13. **Build TutorialScene** - 5-7 pages explaining mechanics
14. **Build SettingsScene** - Theme, sound, haptics, reset
15. **Add ZenLevelGenerator** - Streak-scaling infinite mode
16. **Add Daily Challenge** - Date-seeded single level
17. **Write tests** - Generator determinism, checker logic, score integrity
18. **Verify all levels completable** - Automated or manual playthrough
19. **Generate app icon** - `generate_icon.swift`
20. **Write README.md** - Game design document

---

## 16. Design Principles

1. **One mechanic, deeply explored** - Resist adding unrelated systems
2. **Physics does the work** - The player sets up; physics resolves
3. **Procedural everything** - No image assets, no audio files, no level JSON if possible
4. **Offline-first** - Full game works without network; sync is additive
5. **Respect the platform** - Safe areas, haptics, Game Center, iCloud
6. **Deterministic levels** - Same seed = same level, always
7. **Always completable** - Every generated level must have a valid solution
8. **Progressive disclosure** - One new idea per world, tutorial on first encounter
9. **Satisfying feedback** - Every interaction gets sound + haptic + visual response
10. **No monetization friction** - No ads, no energy, no paywalls
