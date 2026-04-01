import Foundation

@MainActor
final class PointsManager {
    static let shared = PointsManager()

    private(set) var highScore: Int
    private(set) var totalCoins: Int
    private(set) var totalRuns: Int

    private init() {
        highScore  = UserDefaults.standard.integer(forKey: SlicersKeys.highScore)
        totalCoins = UserDefaults.standard.integer(forKey: SlicersKeys.totalCoins)
        totalRuns  = UserDefaults.standard.integer(forKey: SlicersKeys.totalRuns)
    }

    func recordRun(score: Int, coins: Int) {
        totalRuns  += 1
        totalCoins += coins
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: SlicersKeys.highScore)
        }
        UserDefaults.standard.set(totalCoins, forKey: SlicersKeys.totalCoins)
        UserDefaults.standard.set(totalRuns,  forKey: SlicersKeys.totalRuns)
    }
}
