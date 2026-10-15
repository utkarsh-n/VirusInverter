import Foundation
import Observation
import InverterCore

@MainActor @Observable
final class InverterSession {
    var simulation: InverterSimulation
    var paused = false
    var soundEnabled = false
    var hapticsEnabled = true
    var timeScale = 1.0
    private var visualElapsed = 0.0
    @ObservationIgnored let feedback = BenchFeedback()

    init() {
        var config = InverterConfiguration()
        config.motorRatedWatts = 200
        simulation = InverterSimulation(configuration: config)
    }

    var snapshot: InverterSnapshot { simulation.snapshot }
    var phase: Double { (visualElapsed * 0.7).truncatingRemainder(dividingBy: 1) }

    func edit(_ change: (inout InverterConfiguration) -> Void) {
        let wasTripped = simulation.fault != nil
        change(&simulation.configuration)
        simulation.tick(seconds: 0)
        signalNewTrip(wasTripped: wasTripped)
        updateSound()
    }

    func setPower() {
        let wasTripped = simulation.fault != nil
        simulation.setPower(!simulation.isSwitchedOn)
        simulation.tick(seconds: 0)
        if !signalNewTrip(wasTripped: wasTripped) { feedback.tap(enabled: hapticsEnabled) }
        updateSound()
    }

    func connectBattery() {
        let wasTripped = simulation.fault != nil
        edit { $0.batteryConnected.toggle() }
        if wasTripped || simulation.fault == nil { feedback.tap(enabled: hapticsEnabled) }
    }

    func toggleMotor() {
        let wasTripped = simulation.fault != nil
        simulation.toggleMotor()
        simulation.tick(seconds: 0)
        if !signalNewTrip(wasTripped: wasTripped) { feedback.tap(enabled: hapticsEnabled) }
        updateSound()
    }

    func step(seconds: Double) {
        guard !paused else { return }
        if snapshot.isEnergized { visualElapsed += seconds }
        let wasTripped = simulation.fault != nil
        simulation.tick(seconds: seconds * timeScale)
        signalNewTrip(wasTripped: wasTripped)
        updateSound()
    }

    func resetTrip() {
        simulation.resetFault()
        updateSound()
    }

    func replaceBattery() {
        simulation.reset()
        visualElapsed = 0
        feedback.stop()
    }

    @discardableResult
    private func signalNewTrip(wasTripped: Bool) -> Bool {
        let newlyTripped = !wasTripped && simulation.fault != nil
        if newlyTripped { feedback.trip(enabled: hapticsEnabled) }
        return newlyTripped
    }

    func resetBench() {
        var config = InverterConfiguration()
        config.motorRatedWatts = 200
        simulation = InverterSimulation(configuration: config)
        paused = false
        timeScale = 1
        visualElapsed = 0
        feedback.stop()
    }

    func updateSound() {
        feedback.update(enabled: soundEnabled && !paused, energized: snapshot.isEnergized,
                        frequency: snapshot.frequency, power: snapshot.outputPower)
    }
}
