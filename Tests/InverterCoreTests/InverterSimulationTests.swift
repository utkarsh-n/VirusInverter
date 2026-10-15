import Foundation
import Testing
@testable import InverterCore

private func near(_ actual: Double, _ expected: Double, tolerance: Double = 0.000_001,
                  sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(abs(actual - expected) <= tolerance, "\(actual) differs from \(expected)", sourceLocation: sourceLocation)
}

private func powered(_ config: InverterConfiguration = .init(batteryResistance: 0, batteryConnected: true)) -> InverterSimulation {
    var model = InverterSimulation(configuration: config)
    model.setPower(true)
    return model
}

@Suite("Inverter physics and protective behavior")
struct InverterSimulationTests {
    @Test("Nominal sine is 230 V RMS, bipolar, and periodic at 50 Hz")
    func nominalSine() {
        let model = powered()
        let snap = model.snapshot
        near(snap.outputRMSVoltage, 230)
        near(snap.outputPeakVoltage, 230 * sqrt(2))
        near(snap.frequency, 50)
        near(snap.voltage(at: 0.005), snap.outputPeakVoltage)
        near(snap.voltage(at: 0.015), -snap.outputPeakVoltage)
        near(snap.voltage(at: 0.025), snap.voltage(at: 0.005))
        near(snap.voltage(at: 0), 0)
        #expect(snap.isEnergized)
        #expect(snap.status == .running)
    }

    @Test("A sampled cycle agrees with reported RMS for both waveforms", arguments: Waveform.allCases)
    func measuredRMS(waveform: Waveform) {
        var config = InverterConfiguration(batteryResistance: 0, batteryConnected: true)
        config.waveform = waveform
        let snap = powered(config).snapshot
        let samples = 2_000
        let squareSum = (0..<samples).reduce(0.0) { total, index in
            let t = (Double(index) + 0.5) / Double(samples) / snap.frequency
            return total + pow(snap.voltage(at: t), 2)
        }
        near(sqrt(squareSum / Double(samples)), snap.outputRMSVoltage)
        near(snap.voltage(at: 0.25 / snap.frequency), snap.outputPeakVoltage)
        near(snap.voltage(at: 0.75 / snap.frequency), -snap.outputPeakVoltage)
    }

    @Test("Changing sine to square preserves peak and changes RMS by sqrt(2)")
    func waveformScaling() {
        let sine = powered().snapshot
        var config = InverterConfiguration(batteryResistance: 0, batteryConnected: true)
        config.waveform = .square
        let square = powered(config).snapshot
        near(square.outputPeakVoltage, sine.outputPeakVoltage)
        near(square.outputRMSVoltage / sine.outputRMSVoltage, sqrt(2))
        near(square.outputPower / sine.outputPower, 2)
    }

    @Test("An open stage delivers no voltage, current, light, or power", arguments: 0..<5)
    func brokenPaths(stage: Int) {
        var config = InverterConfiguration(batteryConnected: true)
        var model = InverterSimulation(configuration: config)
        switch stage {
        case 0: config.batteryConnected = false
        case 1: config.oscillatorEnabled = false
        case 2: config.powerStageEnabled = false
        case 3: config.transformerConnected = false
        default: break
        }
        model.configuration = config
        if stage != 4 { model.setPower(true) }
        model.tick(seconds: 10)
        let snap = model.snapshot
        #expect(!snap.isEnergized)
        near(snap.outputRMSVoltage, 0)
        near(snap.outputPeakVoltage, 0)
        near(snap.batteryCurrent, 0)
        near(snap.outputPower, 0)
        near(snap.inputPower, 0)
        near(snap.lampBrightness, 0)
        near(snap.voltage(at: 0.005), 0)
        near(model.stateOfCharge, 1)
    }

    @Test("Efficiency, idle draw and internal battery heat conserve source power")
    func conservedPower() {
        let model = powered(.init(batteryConnected: true))
        let snap = model.snapshot
        near(snap.inputPower, snap.outputPower + snap.lossPower)
        near(snap.inputPower, snap.outputPower / 0.85 + 5)
        near(snap.inputPower, snap.batteryTerminalVoltage * snap.batteryCurrent)
        near(12 * snap.batteryCurrent, snap.outputPower + snap.lossPower + snap.batteryHeatPower)
        #expect(snap.lossPower > 0)
        #expect(snap.batteryHeatPower > 0)
    }

    @Test("Terminal sag obeys Ohm's law and reduces resistive load power")
    func sag() {
        let ideal = powered().snapshot
        let realistic = powered(.init(batteryConnected: true)).snapshot
        near(realistic.batteryTerminalVoltage, 12 - 0.02 * realistic.batteryCurrent)
        #expect(realistic.outputRMSVoltage < ideal.outputRMSVoltage)
        #expect(realistic.outputPower < ideal.outputPower)
        near(realistic.outputPower, 60 * pow(realistic.outputRMSVoltage / 230, 2))
    }

    @Test("An unloaded live inverter retains voltage and uses only its stated idle power")
    func idle() {
        let model = powered(.init(batteryResistance: 0, lampConnected: false, batteryConnected: true))
        let snap = model.snapshot
        #expect(snap.isEnergized)
        #expect(snap.status == .idle)
        near(snap.outputRMSVoltage, 230)
        near(snap.outputPower, 0)
        near(snap.inputPower, 5)
        near(snap.batteryCurrent, 5 / 12)
        #expect(snap.runtimeMinutesRemaining != nil)
    }

    @Test("The assumed motor demand is threefold for two seconds then settles")
    func motorStartup() {
        var model = powered(.init(batteryResistance: 0, motorRatedWatts: 200, batteryConnected: true))
        model.setMotorConnected(true)
        #expect(model.snapshot.motorStarting)
        near(model.snapshot.outputPower, 60 + 3 * 200)
        near(model.snapshot.motorSpeed, 0)
        model.tick(seconds: 1)
        #expect(model.snapshot.motorStarting)
        near(model.snapshot.motorSpeed, 0.5)
        model.tick(seconds: 1)
        #expect(!model.snapshot.motorStarting)
        near(model.snapshot.outputPower, 60 + 200)
        near(model.snapshot.motorSpeed, 1)
        model.toggleMotor()
        #expect(!model.configuration.motorConnected)
        near(model.motorStartingRemaining, 0)
        near(model.snapshot.motorSpeed, 0)
        near(model.snapshot.outputPower, 60)
    }

    @Test("Motor connection while off begins startup when power is switched on")
    func offMotorConnection() {
        var model = InverterSimulation(configuration: .init(batteryResistance: 0, motorConnected: true,
                                                           motorRatedWatts: 200, batteryConnected: true))
        near(model.motorStartingRemaining, 0)
        model.setPower(true)
        near(model.motorStartingRemaining, 2)
        #expect(model.snapshot.motorStarting)
        model.setPower(false)
        near(model.motorStartingRemaining, 0)
        model.setPower(true)
        near(model.motorStartingRemaining, 2)
    }

    @Test("Low-battery faults latch and require the power switch off before resetting")
    func latchedLowBattery() {
        var model = powered(.init(batteryConnected: true))
        model.toggleMotor()
        #expect(model.fault == .lowBattery)
        #expect(model.snapshot.status == .lowBattery)
        #expect(!model.snapshot.isEnergized)
        near(model.snapshot.outputPower, 0)
        model.configuration.batteryVoltage = 14
        model.setMotorConnected(false)
        model.resetFault()
        #expect(model.fault == .lowBattery)
        model.setPower(false)
        model.resetFault()
        #expect(model.fault == nil)
        model.setPower(true)
        #expect(model.snapshot.isEnergized)
    }

    @Test("Overload disconnects output rather than clamping or inventing power")
    func overload() {
        let config = InverterConfiguration(batteryVoltage: 14, batteryResistance: 0, turnsRatio: 40,
                                           motorConnected: true, motorRatedWatts: 1_000,
                                           batteryConnected: true, waveform: .square)
        let model = powered(config)
        #expect(model.fault == .overload)
        #expect(model.snapshot.status == .overload)
        #expect(!model.snapshot.isEnergized)
        near(model.snapshot.outputPower, 0)
        near(model.snapshot.batteryCurrent, 0)
    }

    @Test("The steady 1000 W limit applies after startup has finished")
    func steadyPowerLimit() {
        var model = powered(.init(batteryResistance: 0, motorConnected: true,
                                  motorRatedWatts: 200, batteryConnected: true))
        model.tick(seconds: 2)
        #expect(model.fault == nil)
        #expect(!model.snapshot.motorStarting)
        model.configuration.motorRatedWatts = 1_000
        // At 230 V this requests 1060 W total, with only about 104 A battery current.
        model.tick(seconds: 0)
        #expect(model.fault == .overload)
    }

    @Test("The 150 A battery-current limit can trip below the startup power limit")
    func batteryCurrentLimit() {
        let model = powered(.init(batteryResistance: 0, efficiency: 0.1, motorConnected: true,
                                  motorRatedWatts: 200, batteryConnected: true))
        // Startup output requests 660 W, but poor conversion efficiency requests > 500 A.
        #expect(model.fault == .overload)
        #expect(!model.snapshot.isEnergized)
        near(model.snapshot.inputPower, 0)
    }

    @Test("A zero-time refresh evaluates protection after configuration edits")
    func zeroTick() {
        var model = powered()
        model.configuration.batteryVoltage = 10
        model.tick(seconds: 0)
        #expect(model.fault == .lowBattery)
        near(model.elapsed, 0)
    }

    @Test("Disconnecting and reconnecting the source pauses discharge and restarts motor demand")
    func sourceReconnect() {
        var model = powered(.init(batteryResistance: 0, motorConnected: true,
                                  motorRatedWatts: 200, batteryConnected: true))
        model.tick(seconds: 0.5)
        model.configuration.batteryConnected = false
        let charge = model.stateOfCharge
        model.tick(seconds: 10)
        near(model.stateOfCharge, charge)
        near(model.motorStartingRemaining, 0)
        #expect(!model.snapshot.isEnergized)
        model.configuration.batteryConnected = true
        #expect(model.snapshot.motorStarting)
        near(model.motorStartingRemaining, 2)
        #expect(model.snapshot.isEnergized)
    }

    @Test("Charge counting agrees with terminal current and predicts runtime")
    func chargeCounting() throws {
        var model = powered()
        let current = model.snapshot.batteryCurrent
        let expectedStartRuntime = 45 / current * 60
        near(try #require(model.snapshot.runtimeMinutesRemaining), expectedStartRuntime)
        model.tick(seconds: 60)
        near(model.stateOfCharge, 1 - current / (60 * 45), tolerance: 0.000_000_001)
        near(try #require(model.snapshot.runtimeMinutesRemaining), expectedStartRuntime - 1)
    }

    @Test("Large ticks and partitioned ticks agree across the startup boundary")
    func timestepInvariance() {
        let config = InverterConfiguration(batteryResistance: 0, motorConnected: true,
                                            motorRatedWatts: 200, batteryConnected: true)
        var large = powered(config)
        var partitioned = powered(config)
        large.tick(seconds: 5.37)
        for _ in 0..<537 { partitioned.tick(seconds: 0.01) }
        near(large.stateOfCharge, partitioned.stateOfCharge, tolerance: 0.000_000_001)
        near(large.motorStartingRemaining, partitioned.motorStartingRemaining)
        near(large.elapsed, partitioned.elapsed)
        #expect(large.snapshot.status == partitioned.snapshot.status)
    }

    @Test("An empty battery remains empty until a fresh experiment reset")
    func emptyBattery() {
        var model = powered(.init(batteryResistance: 0, batteryConnected: true, capacityAh: 0.001))
        model.tick(seconds: 10)
        near(model.stateOfCharge, 0)
        #expect(model.fault == .lowBattery)
        #expect(!model.snapshot.isEnergized)
        #expect(model.snapshot.runtimeMinutesRemaining == 0)
        model.setPower(false)
        model.resetFault()
        model.setPower(true)
        #expect(model.fault == .lowBattery)
        model.reset()
        near(model.stateOfCharge, 1)
        near(model.elapsed, 0)
        #expect(model.fault == nil)
        #expect(!model.isSwitchedOn)
        #expect(model.configuration.capacityAh == 0.001)
    }

    @Test("A huge finite tick uses the exact steady solution and depletes without overflow")
    func hugeTick() {
        var model = powered(.init(batteryResistance: 0, lampConnected: false,
                                  batteryConnected: true, capacityAh: 200))
        model.tick(seconds: Double.greatestFiniteMagnitude)
        near(model.stateOfCharge, 0)
        #expect(model.fault == .lowBattery)
        #expect(model.elapsed.isFinite)
        #expect(model.snapshot.batteryCurrent == 0)
    }

    @Test("Nonfinite settings and invalid time cannot introduce nonfinite state")
    func invalidInputs() {
        var config = InverterConfiguration(batteryConnected: true)
        config.batteryVoltage = .nan
        config.batteryResistance = -.infinity
        config.frequency = .infinity
        config.turnsRatio = .nan
        config.efficiency = 0
        config.motorRatedWatts = -100
        config.capacityAh = .nan
        var model = powered(config)
        let previous = model
        model.tick(seconds: -.infinity)
        model.tick(seconds: .nan)
        model.tick(seconds: -1)
        #expect(model == previous)
        let snap = model.snapshot
        #expect(snap.outputRMSVoltage.isFinite)
        #expect(snap.batteryCurrent.isFinite)
        #expect(model.stateOfCharge.isFinite)
        near(snap.frequency, 50)
        near(snap.voltage(at: .nan), 0)
        #expect(snap.voltage(at: Double.greatestFiniteMagnitude).isFinite)
        #expect(config.sanitized().efficiency == 0.1)
        #expect(config.sanitized().motorRatedWatts == 100)
    }

    @Test("Frequency changes timing, not the ideal transformer voltage")
    func frequencyTiming() {
        var config = InverterConfiguration(batteryResistance: 0, frequency: 80, batteryConnected: true)
        let fast = powered(config).snapshot
        config.frequency = 20
        let slow = powered(config).snapshot
        near(fast.outputRMSVoltage, slow.outputRMSVoltage)
        near(fast.voltage(at: 0.25 / 80), fast.outputPeakVoltage)
        near(slow.voltage(at: 0.25 / 20), slow.outputPeakVoltage)
        #expect(abs(fast.voltage(at: 0.002) - slow.voltage(at: 0.002)) > 1)
    }
}
