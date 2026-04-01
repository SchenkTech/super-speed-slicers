import AVFoundation
import UIKit

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private var engine = AVAudioEngine()
    private lazy var mixer = engine.mainMixerNode

    var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: SlicersKeys.soundEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SlicersKeys.soundEnabled) }
    }

    var hapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: SlicersKeys.hapticsEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: SlicersKeys.hapticsEnabled) }
    }

    private init() {
        mixer.outputVolume = 0.5
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            // Audio unavailable — game works silently
        }
    }

    private func playTone(frequency: Float, duration: Float, volume: Float = 0.4) {
        guard soundEnabled else { return }
        let sampleRate: Double = 44_100
        let frameCount = AVAudioFrameCount(sampleRate * Double(duration))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Float(i) / Float(sampleRate)
            let envelope = max(0, 1.0 - t / duration)
            data[i] = sinf(2.0 * .pi * frequency * t) * volume * envelope
        }
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mixer, format: buffer.format)
        player.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.main.async { self?.engine.detach(player) }
        }
        player.play()
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - Sound Events

    func playSlice() {
        playTone(frequency: 820, duration: 0.06)
        haptic(.light)
    }

    func playObstacleDestroyed(_ type: ObstacleType) {
        switch type {
        case .glassPane:
            for i in 0...3 {
                let delay = Double(i) * 0.04
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.playTone(frequency: Float(1600 - i * 220), duration: 0.08, volume: 0.3)
                }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        default:
            playTone(frequency: 480, duration: 0.12)
            haptic(.medium)
        }
    }

    func playPlayerHit() {
        playTone(frequency: 190, duration: 0.35, volume: 0.6)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func playPowerUpPickup() {
        for (i, freq) in [600, 750, 950].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) { [weak self] in
                self?.playTone(frequency: Float(freq), duration: 0.09)
            }
        }
        haptic(.medium)
    }

    func playJump() {
        playTone(frequency: 340, duration: 0.12)
        haptic(.light)
    }

    func playGameOver() {
        playTone(frequency: 290, duration: 0.25)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.playTone(frequency: 190, duration: 0.45, volume: 0.5)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func playButtonTap() {
        playTone(frequency: 860, duration: 0.03)
        haptic(.light)
    }

    func playCombo(_ count: Int) {
        let freq = 400.0 + Float(min(count, 10)) * 45.0
        playTone(frequency: freq, duration: 0.07)
        haptic(.light)
    }

    func playChainsaw() {
        playTone(frequency: 120, duration: 0.15, volume: 0.3)
        haptic(.rigid)
    }
}
