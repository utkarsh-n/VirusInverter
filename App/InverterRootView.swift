import SwiftUI
import InverterCore

struct InverterRootView: View {
    let session: InverterSession
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            Tab("Bench", systemImage: "powerplug.fill") {
                NavigationStack { BenchView(session: session) }
            }
            Tab("Inside", systemImage: "waveform.path") {
                NavigationStack { InsideView(session: session) }
            }
            Tab("Notes", systemImage: "book.closed") {
                NavigationStack { NotesView(session: session) }
            }
        }
        .preferredColorScheme(.dark)
        .task(id: scenePhase) {
            guard scenePhase == .active else { session.feedback.stop(); return }
            defer { session.feedback.stop() }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(100)) }
                catch { break }
                session.step(seconds: 0.1)
            }
        }
        .onChange(of: session.soundEnabled) { _, _ in session.updateSound() }
        .onChange(of: session.paused) { _, _ in session.updateSound() }
    }
}

struct BenchView: View {
    let session: InverterSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                introduction
                BenchIllustration(
                    batteryConnected: session.simulation.configuration.batteryConnected,
                    powered: session.snapshot.isEnergized,
                    outputVoltage: session.snapshot.outputRMSVoltage,
                    lampBrightness: session.snapshot.lampBrightness,
                    motorSpeed: session.snapshot.motorSpeed,
                    motorConnected: session.simulation.configuration.motorConnected,
                    tripped: session.simulation.fault != nil,
                    phase: reduceMotion ? 0 : session.phase, reduceMotion: reduceMotion)
                    .frame(height: 340)
                actions
                status
                meters
                loads
                tuning
                battery
                Text("A film-inspired electrical toy · animation slowed to reveal the logic")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(BenchTheme.background)
        .navigationTitle("ViruS Inverter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Bench actions", systemImage: "ellipsis") {
                    Button("Restore the light", systemImage: "lightbulb") { restoreLight() }
                    Button("Start a small vacuum", systemImage: "fan") {
                        restoreLight(); session.toggleMotor()
                    }
                    Button("Try a heavy startup", systemImage: "bolt.trianglebadge.exclamationmark") {
                        restoreLight()
                        session.edit { $0.motorRatedWatts = 1000 }
                        session.toggleMotor()
                    }
                    Divider()
                    Button(session.paused ? "Resume simulation" : "Pause simulation",
                           systemImage: session.paused ? "play" : "pause") { session.paused.toggle() }
                    Button("Reset bench", systemImage: "arrow.counterclockwise") { session.resetBench() }
                }
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MAKE LIGHT FROM A CAR BATTERY")
                .font(.caption.weight(.semibold)).tracking(2).foregroundStyle(BenchTheme.amber)
            Text("Connect the leads. Flip the switch. Follow the energy.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    private var actions: some View {
        GlassEffectContainer(spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { batteryButton; powerButton }
                VStack(spacing: 12) { batteryButton; powerButton }
            }
        }
    }

    private var batteryButton: some View {
        Button(action: session.connectBattery) {
            Label(session.simulation.configuration.batteryConnected ? "Unclip battery" : "Connect battery",
                  systemImage: "cable.connector")
                .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .buttonStyle(.glass).controlSize(.large)
        .accessibilityIdentifier("connectBattery")
    }

    private var powerButton: some View {
        Button(action: session.setPower) {
            Label(session.simulation.isSwitchedOn ? "Switch off" : "Switch on", systemImage: "power")
                .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent).controlSize(.large)
        .accessibilityIdentifier("powerSwitch")
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: session.simulation.fault != nil ? "exclamationmark.triangle.fill" :
                      session.snapshot.isEnergized ? "bolt.fill" : "circle.dashed")
                Text(session.paused ? "Simulation paused" : session.snapshot.status.title).font(.headline)
                Spacer(minLength: 0)
            }
            .foregroundStyle(session.simulation.fault != nil ? .red : BenchTheme.amber)
            Text(session.snapshot.status.detail).font(.subheadline).foregroundStyle(.secondary)
            if session.simulation.fault != nil {
                if session.simulation.stateOfCharge <= 0 {
                    Button("Replace virtual battery") { session.replaceBattery() }
                        .buttonStyle(.glass)
                    Text("The virtual battery is empty. Replace it, then switch on again.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Button("Reset protection") { session.resetTrip() }
                        .buttonStyle(.glass)
                        .disabled(session.simulation.isSwitchedOn)
                    Text("Switch off, remove the cause, then reset protection.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if session.snapshot.motorStarting {
                Label("Motor startup · 3× demand for 2 seconds", systemImage: "fan.fill")
                    .font(.caption).foregroundStyle(BenchTheme.teal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("inverterStatus")
    }

    private var meters: some View {
        InstrumentPanel {
            VStack(alignment: .leading, spacing: 18) {
                Text("LIVE AT THE TERMINALS").font(.caption.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading),
                                         count: typeSize.isAccessibilitySize ? 2 : 3), spacing: 18) {
                    BenchMetric(title: "Output", value: session.snapshot.outputRMSVoltage, unit: "V RMS", color: BenchTheme.amber)
                    BenchMetric(title: "Timing", value: session.snapshot.isEnergized ? session.snapshot.frequency : 0, unit: "Hz", color: BenchTheme.teal)
                    BenchMetric(title: "Battery draw", value: session.snapshot.batteryCurrent, unit: "A DC")
                    BenchMetric(title: "To the load", value: session.snapshot.outputPower, unit: "W")
                    BenchMetric(title: "From battery", value: session.snapshot.inputPower, unit: "W at terminals")
                    BenchMetric(title: "Conversion loss", value: session.snapshot.lossPower, unit: "W")
                }
            }
        }
    }

    private var loads: some View {
        InstrumentPanel {
            VStack(alignment: .leading, spacing: 16) {
                Label("Give it something to power", systemImage: "powerplug").font(.headline)
                Toggle("Room bulb · 60 W at 230 V", isOn: configurationBinding(\.lampConnected))
                    .accessibilityIdentifier("lampLoad")
                Toggle("Vacuum motor", isOn: Binding(
                    get: { session.simulation.configuration.motorConnected },
                    set: { _ in session.toggleMotor() }))
                    .accessibilityIdentifier("motorLoad")
                DialSlider(title: "Motor rating at 230 V", value: configurationBinding(\.motorRatedWatts),
                           range: 100...1000, unit: "W", step: 50)
                Text("The default 200 W motor is a small toy load. Increase its rating to feel the cost of startup.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var tuning: some View {
        InstrumentPanel {
            VStack(alignment: .leading, spacing: 16) {
                Label("Tune the conversion", systemImage: "dial.medium").font(.headline)
                DialSlider(title: "Oscillator", value: configurationBinding(\.frequency), range: 20...80, unit: "Hz")
                DialSlider(title: "Transformer ratio", value: configurationBinding(\.turnsRatio),
                           range: 10...40, unit: ": 1", step: 0.1)
                Text("Timing changes the cycle rate. Turns change voltage. Neither creates power.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Return to 50 Hz / nominal 230 V") {
                    session.edit { $0.frequency = 50; $0.turnsRatio = InverterSimulation.defaultTurnsRatio; $0.waveform = .sine }
                }.buttonStyle(.glass)
            }
        }
    }

    private var battery: some View {
        InstrumentPanel {
            VStack(alignment: .leading, spacing: 16) {
                Label("The energy reservoir", systemImage: "car.side").font(.headline)
                DialSlider(title: "Open-circuit battery", value: configurationBinding(\.batteryVoltage),
                           range: 10...14, unit: "V DC", step: 0.1)
                HStack {
                    Text("Loaded terminal voltage").font(.subheadline)
                    Spacer()
                    Text("\(session.snapshot.batteryTerminalVoltage, specifier: "%.2f") V")
                        .font(.subheadline.monospacedDigit()).foregroundStyle(BenchTheme.amber)
                }
                ProgressView(value: session.simulation.stateOfCharge)
                    .accessibilityLabel("Battery charge")
                    .accessibilityValue("\(Int(session.simulation.stateOfCharge * 100)) percent")
                HStack {
                    Text("\(session.simulation.stateOfCharge * 100, specifier: "%.1f")% · 45 Ah assumed")
                    Spacer()
                    if let minutes = session.snapshot.runtimeMinutesRemaining {
                        Text("≈ \(minutes, specifier: "%.0f") min")
                    }
                }.font(.caption).foregroundStyle(.secondary)
                Picker("Simulation time", selection: timeScaleBinding) {
                    Text("Real time").tag(1.0)
                    Text("60×").tag(60.0)
                    Text("600×").tag(600.0)
                }.pickerStyle(.segmented)
                Text("Runtime is a charge-counting estimate. Battery chemistry, transformer saturation, and real motor dynamics are outside this model.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var timeScaleBinding: Binding<Double> {
        Binding(get: { session.timeScale }, set: { session.timeScale = $0 })
    }

    private func configurationBinding<T>(_ key: WritableKeyPath<InverterConfiguration, T>) -> Binding<T> {
        Binding(get: { session.simulation.configuration[keyPath: key] },
                set: { value in session.edit { $0[keyPath: key] = value } })
    }

    private func restoreLight() {
        session.resetBench()
        session.connectBattery()
        session.setPower()
    }
}
