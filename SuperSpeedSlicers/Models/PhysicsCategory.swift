import Foundation

struct PhysicsCategory {
    static let none:     UInt32 = 0
    static let player:   UInt32 = 0b0000001
    static let obstacle: UInt32 = 0b0000010  // sliceable
    static let hazard:   UInt32 = 0b0000100  // must dodge
    static let powerUp:  UInt32 = 0b0001000
    static let ground:   UInt32 = 0b0010000
    static let enemy:    UInt32 = 0b0100000
    static let coin:     UInt32 = 0b1000000
}
