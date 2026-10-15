import AVFoundation
import UIKit

/// An optional sonification, not an acoustic model of a physical inverter.
@MainActor
final class BenchFeedback {
    private var player: AVAudioPlayer?

    func update(enabled: Bool, energized: Bool, frequency: Double, power: Double) {
        guard enabled && energized else { stop(); return }
        if player == nil {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                let audio = try AVAudioPlayer(data: Self.hum())
                audio.numberOfLoops = -1
                audio.enableRate = true
                audio.prepareToPlay()
                player = audio
            } catch {
                player = nil
                return
            }
        }
        player?.rate = Float(min(2, max(0.5, frequency / 50)))
        player?.volume = Float(min(0.12, 0.025 + power / 10000))
        if player?.isPlaying == false { player?.play() }
    }

    func stop() { player?.stop() }
    func tap(enabled: Bool) {
        if enabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    }
    func trip(enabled: Bool) {
        if enabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    }

    private static func hum() -> Data {
        let rate = 22050
        var samples = Data(capacity: rate * 2)
        for index in 0..<rate {
            let t = Double(index) / Double(rate)
            let value = 0.65 * sin(2 * .pi * 100 * t) + 0.15 * sin(2 * .pi * 200 * t)
            var sample = Int16(value * 12000).littleEndian
            withUnsafeBytes(of: &sample) { samples.append(contentsOf: $0) }
        }
        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func u32(_ value: UInt32) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        func u16(_ value: UInt16) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        ascii("RIFF"); u32(UInt32(36 + samples.count)); ascii("WAVEfmt ")
        u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        ascii("data"); u32(UInt32(samples.count)); data.append(samples)
        return data
    }
}
