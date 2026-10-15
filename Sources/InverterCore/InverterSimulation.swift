import Foundation

public enum Waveform: String, CaseIterable, Sendable, Equatable {
    case sine
    case square

    public var title: String { self == .sine ? "Sine" : "Square" }

    fileprivate var rmsPerPeak: Double { self == .sine ? 1 / sqrt(2) : 1 }
}

public struct InverterConfiguration: Sendable, Equatable {
    public var batteryVoltage: Double
    public var batteryResistance: Double
    public var frequency: Double
    public var turnsRatio: Double
    public var efficiency: Double
    public var lampConnected: Bool
    public var motorConnected: Bool
    public var motorRatedWatts: Double
    public var batteryConnected: Bool
    public var oscillatorEnabled: Bool
    public var powerStageEnabled: Bool
    public var transformerConnected: Bool
    public var waveform: Waveform
    public var capacityAh: Double

    public init(
        batteryVoltage: Double = 12,
        batteryResistance: Double = 0.02,
        frequency: Double = 50,
        turnsRatio: Double = InverterSimulation.defaultTurnsRatio,
        efficiency: Double = 0.85,
        lampConnected: Bool = true,
        motorConnected: Bool = false,
        motorRatedWatts: Double = 600,
        batteryConnected: Bool = false,
        oscillatorEnabled: Bool = true,
        powerStageEnabled: Bool = true,
        transformerConnected: Bool = true,
        waveform: Waveform = .sine,
        capacityAh: Double = 45
    ) {
        self.batteryVoltage = batteryVoltage
        self.batteryResistance = batteryResistance
        self.frequency = frequency
        self.turnsRatio = turnsRatio
        self.efficiency = efficiency
        self.lampConnected = lampConnected
        self.motorConnected = motorConnected
        self.motorRatedWatts = motorRatedWatts
        self.batteryConnected = batteryConnected
        self.oscillatorEnabled = oscillatorEnabled
        self.powerStageEnabled = powerStageEnabled
        self.transformerConnected = transformerConnected
        self.waveform = waveform
        self.capacityAh = capacityAh
    }

    /// Bounds are the toy's supported exploration range, not component specifications.
    public func sanitized() -> Self {
        var result = self
        result.batteryVoltage = Self.finite(batteryVoltage, fallback: 12, range: 10...14)
        result.batteryResistance = Self.finite(batteryResistance, fallback: 0.02, range: 0...0.2)
        result.frequency = Self.finite(frequency, fallback: 50, range: 20...80)
        result.turnsRatio = Self.finite(turnsRatio, fallback: InverterSimulation.defaultTurnsRatio, range: 10...40)
        result.efficiency = Self.finite(efficiency, fallback: 0.85, range: 0.1...1)
        result.motorRatedWatts = Self.finite(motorRatedWatts, fallback: 600, range: 100...1_000)
        result.capacityAh = Self.finite(capacityAh, fallback: 45, range: 0.001...200)
        return result
    }

    private static func finite(_ value: Double, fallback: Double, range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return fallback }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}

public enum InverterFault: String, Sendable, Equatable {
    case lowBattery
    case overload

    public var title: String { self == .lowBattery ? "Low battery" : "Overload" }

    public var detail: String {
        switch self {
        case .lowBattery: "Battery terminal voltage fell below 10.5 V, or its modeled charge ran out. Switch off to reset."
        case .overload: "The toy's power or battery-current limit was exceeded. Switch off, reduce the load, then reset."
        }
    }
}

public enum InverterStatus: String, Sendable, Equatable {
    case off
    case batteryDisconnected
    case oscillatorDisabled
    case powerStageDisabled
    case transformerDisconnected
    case lowBattery
    case overload
    case idle
    case running
    case starting

    public var title: String {
        switch self {
        case .off: "Switched off"
        case .batteryDisconnected: "Connect the battery"
        case .oscillatorDisabled: "Oscillator stopped"
        case .powerStageDisabled: "Power stage stopped"
        case .transformerDisconnected: "Transformer disconnected"
        case .lowBattery: InverterFault.lowBattery.title
        case .overload: InverterFault.overload.title
        case .idle: "AC ready"
        case .running: "Making AC"
        case .starting: "Motor starting"
        }
    }

    public var detail: String {
        switch self {
        case .off: "Close the power switch to begin."
        case .batteryDisconnected: "The battery supplies the energy; the oscillator only controls the timing."
        case .oscillatorDisabled: "Steady DC does not produce continuous transformer output in this model."
        case .powerStageDisabled: "An oscillator needs a power switching stage to drive a useful load."
        case .transformerDisconnected: "The alternating primary is disconnected from the step-up transformer."
        case .lowBattery: InverterFault.lowBattery.detail
        case .overload: InverterFault.overload.detail
        case .idle: "No load is attached. The modeled power stage still uses 5 W at idle."
        case .running: "Battery DC drives an alternating primary; the transformer raises its voltage."
        case .starting: "Toy assumption: 3 times the motor load for a 2-second start."
        }
    }
}

public struct InverterSnapshot: Sendable, Equatable {
    public let batteryTerminalVoltage: Double
    public let outputRMSVoltage: Double
    public let outputPeakVoltage: Double
    public let frequency: Double
    public let batteryCurrent: Double
    /// Power delivered at the battery terminals. It excludes internal battery heating.
    public let inputPower: Double
    public let outputPower: Double
    /// Conversion loss plus the explicit 5 W idle demand.
    public let lossPower: Double
    public let batteryHeatPower: Double
    public let lampBrightness: Double
    /// A visual proxy based on voltage and elapsed start time, not electromechanics.
    public let motorSpeed: Double
    public let runtimeMinutesRemaining: Double?
    public let isEnergized: Bool
    public let status: InverterStatus
    public let motorStarting: Bool
    public let waveform: Waveform

    public func voltage(at timeSeconds: Double) -> Double {
        guard isEnergized, timeSeconds.isFinite else { return 0 }
        // Reduce time before multiplication so even very large finite times stay finite.
        let phase = timeSeconds.remainder(dividingBy: 1 / frequency) * frequency * 2 * Double.pi
        let sine = sin(phase)
        return waveform == .sine ? outputPeakVoltage * sine : (sine >= 0 ? outputPeakVoltage : -outputPeakVoltage)
    }
}

/// Educational steady-state model, not a hardware design or an implementation of the film prop.
/// The supplied PDF names an RC oscillator and transformer but omits the power stage.
/// Here an ideal alternating power stage is explicit. Primary peak equals terminal DC voltage.
/// Loads use fixed resistance: a 60 W / 230 V lamp, and a motor-demand proxy. Frequency does
/// not change ideal-transformer gain; magnetics, transistor ratings and real motor dynamics
/// require circuit details that the source does not provide.
public struct InverterSimulation: Sendable, Equatable {
    public static let defaultTurnsRatio: Double = 230 * sqrt(2) / 12
    public static let lampRatedWatts: Double = 60
    public static let ratedVoltage: Double = 230
    public static let idlePower: Double = 5
    public static let motorStartDuration: Double = 2
    public static let motorStartMultiplier: Double = 3

    public var configuration: InverterConfiguration {
        didSet {
            let old = oldValue.sanitized()
            let new = configuration.sanitized()
            if !new.motorConnected || !Self.pathComplete(new) {
                motorStartingRemaining = 0
            } else if isSwitchedOn, fault == nil,
                      !old.motorConnected || !Self.pathComplete(old) {
                motorStartingRemaining = Self.motorStartDuration
            }
        }
    }
    public private(set) var isSwitchedOn = false
    public private(set) var elapsed: Double = 0
    public private(set) var stateOfCharge: Double = 1
    public private(set) var motorStartingRemaining: Double = 0
    public private(set) var fault: InverterFault?

    public init(configuration: InverterConfiguration = .init()) {
        self.configuration = configuration.sanitized()
    }

    public mutating func setPower(_ on: Bool) {
        let wasOn = isSwitchedOn
        isSwitchedOn = on
        if !on {
            motorStartingRemaining = 0
        } else if !wasOn, fault == nil, configuration.motorConnected,
                  Self.pathComplete(configuration.sanitized()) {
            motorStartingRemaining = Self.motorStartDuration
        }
        evaluateProtection()
    }

    public mutating func toggleMotor() { setMotorConnected(!configuration.motorConnected) }

    public mutating func setMotorConnected(_ connected: Bool) {
        configuration.motorConnected = connected
        evaluateProtection()
    }

    /// Faults are latched until the switch is off. Resetting does not recharge the battery.
    public mutating func resetFault() {
        guard !isSwitchedOn else { return }
        fault = nil
    }

    /// Starts a fresh virtual battery while keeping the current experiment settings.
    public mutating func reset() {
        isSwitchedOn = false
        elapsed = 0
        stateOfCharge = 1
        motorStartingRemaining = 0
        fault = nil
    }

    public mutating func tick(seconds: Double) {
        guard seconds.isFinite, seconds >= 0 else { return }
        evaluateProtection()
        let newElapsed = elapsed + seconds
        let endElapsed = newElapsed.isFinite ? newElapsed : Double.greatestFiniteMagnitude
        var remaining = seconds
        let config = configuration.sanitized()

        // Short steps resolve startup. Once it ends, fixed Voc and resistance make the
        // current constant: exact charge counting replaces arbitrarily many identical
        // substeps and locates the same empty-battery cutoff without a large-tick loop.
        while remaining > 0, isSwitchedOn, fault == nil, Self.pathComplete(config) {
            let electrical = electricalState(config)
            if let protection = protectionFault(electrical) {
                fault = protection
                motorStartingRemaining = 0
                break
            }
            if motorStartingRemaining == 0 {
                let timeToEmpty = stateOfCharge * 3_600 * config.capacityAh / electrical.current
                if remaining >= timeToEmpty {
                    stateOfCharge = 0
                    fault = .lowBattery
                } else {
                    stateOfCharge -= electrical.current * remaining / (3_600 * config.capacityAh)
                }
                break
            }
            let untilStartFinishes = motorStartingRemaining > 0 ? motorStartingRemaining : Double.infinity
            let dt = min(0.05, min(remaining, untilStartFinishes))
            let chargeUsed = electrical.current * dt / (3_600 * config.capacityAh)
            if chargeUsed >= stateOfCharge {
                stateOfCharge = 0
                motorStartingRemaining = 0
                fault = .lowBattery
                break
            }
            stateOfCharge -= chargeUsed
            motorStartingRemaining = max(0, motorStartingRemaining - dt)
            remaining -= dt
        }
        elapsed = endElapsed
        evaluateProtection()
    }

    public var snapshot: InverterSnapshot {
        let config = configuration.sanitized()
        let status = inactiveStatus(config)
        let electrical = status == nil ? electricalState(config) : .inactive(voltage: config.batteryVoltage)
        let activeFault = fault ?? (status == nil ? protectionFault(electrical) : nil)
        let finalStatus = activeFault.map { $0 == .lowBattery ? InverterStatus.lowBattery : .overload }
            ?? status
            ?? (motorStartingRemaining > 0 ? .starting : (config.lampConnected || config.motorConnected ? .running : .idle))
        let energized = status == nil && activeFault == nil
        let current = energized ? electrical.current : 0
        let outputRMS = energized ? electrical.rms : 0
        let input = energized ? electrical.input : 0
        let output = energized ? electrical.output : 0
        let startProgress = 1 - motorStartingRemaining / Self.motorStartDuration
        let speed = energized && config.motorConnected ? min(1, outputRMS / Self.ratedVoltage) * startProgress : 0
        let runtime: Double? = stateOfCharge == 0 ? 0 : (current > 0 ? stateOfCharge * config.capacityAh / current * 60 : nil)

        return InverterSnapshot(
            batteryTerminalVoltage: energized ? electrical.terminal : config.batteryVoltage,
            outputRMSVoltage: outputRMS,
            outputPeakVoltage: energized ? electrical.peak : 0,
            frequency: config.frequency,
            batteryCurrent: current,
            inputPower: input,
            outputPower: output,
            lossPower: input - output,
            batteryHeatPower: current * current * config.batteryResistance,
            lampBrightness: energized && config.lampConnected ? min(1, pow(outputRMS / Self.ratedVoltage, 2)) : 0,
            motorSpeed: speed,
            runtimeMinutesRemaining: runtime,
            isEnergized: energized,
            status: finalStatus,
            motorStarting: energized && config.motorConnected && motorStartingRemaining > 0,
            waveform: config.waveform
        )
    }

    private static func pathComplete(_ config: InverterConfiguration) -> Bool {
        config.batteryConnected && config.oscillatorEnabled && config.powerStageEnabled && config.transformerConnected
    }

    private func inactiveStatus(_ config: InverterConfiguration) -> InverterStatus? {
        if !isSwitchedOn { return .off }
        if !config.batteryConnected { return .batteryDisconnected }
        if !config.oscillatorEnabled { return .oscillatorDisabled }
        if !config.powerStageEnabled { return .powerStageDisabled }
        if !config.transformerConnected { return .transformerDisconnected }
        return nil
    }

    private mutating func evaluateProtection() {
        guard isSwitchedOn, fault == nil else { return }
        let config = configuration.sanitized()
        guard Self.pathComplete(config) else { return }
        if let protection = protectionFault(electricalState(config)) {
            fault = protection
            motorStartingRemaining = 0
        }
    }

    private func protectionFault(_ electrical: ElectricalState) -> InverterFault? {
        if stateOfCharge <= 0 { return .lowBattery }
        let powerLimit: Double = motorStartingRemaining > 0 ? 1_800 : 1_000
        if electrical.output > powerLimit || electrical.current > 150 { return .overload }
        if electrical.terminal < 10.5 { return .lowBattery }
        return nil
    }

    private struct ElectricalState {
        var terminal: Double
        var peak: Double
        var rms: Double
        var current: Double
        var input: Double
        var output: Double

        static func inactive(voltage: Double) -> Self {
            Self(terminal: voltage, peak: 0, rms: 0, current: 0, input: 0, output: 0)
        }
    }

    private func electricalState(_ config: InverterConfiguration) -> ElectricalState {
        let motorMultiplier = motorStartingRemaining > 0 ? Self.motorStartMultiplier : 1
        let nominalPower = (config.lampConnected ? Self.lampRatedWatts : 0)
            + (config.motorConnected ? config.motorRatedWatts * motorMultiplier : 0)
        let conductance = nominalPower / pow(Self.ratedVoltage, 2)
        let gain = config.turnsRatio * config.waveform.rmsPerPeak
        let inputLoadCoefficient = conductance * gain * gain / config.efficiency

        // Solve Vt = Voc - R * I and I = (A * Vt² + Pidle) / Vt together.
        // The higher root is the stable operating point; absent a real root, protection trips.
        let a = 1 + config.batteryResistance * inputLoadCoefficient
        let discriminant = config.batteryVoltage * config.batteryVoltage
            - 4 * a * config.batteryResistance * Self.idlePower
        guard discriminant >= 0 else { return .inactive(voltage: 0) }
        let terminal = (config.batteryVoltage + sqrt(discriminant)) / (2 * a)
        guard terminal > 0 else { return .inactive(voltage: 0) }
        let peak = terminal * config.turnsRatio
        let rms = peak * config.waveform.rmsPerPeak
        let output = conductance * rms * rms
        let input = output / config.efficiency + Self.idlePower
        return ElectricalState(terminal: terminal, peak: peak, rms: rms,
                               current: input / terminal, input: input, output: output)
    }
}
