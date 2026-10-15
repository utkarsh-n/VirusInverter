import SwiftUI
import InverterCore

struct InsideView: View {
    let session: InverterSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Follow one cycle.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("The battery supplies the energy. The oscillator supplies the timing. A power stage does the heavy work.")
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    Label(session.snapshot.status.title, systemImage: session.snapshot.isEnergized ? "bolt.fill" : "circle.dashed")
                    Spacer()
                    Text("\(session.snapshot.outputRMSVoltage, specifier: "%.1f") V RMS")
                        .monospacedDigit()
                }
                .font(.subheadline.weight(.semibold)).foregroundStyle(BenchTheme.amber)
                .accessibilityElement(children: .combine)
                stage(number: "01", title: "Battery · steady DC", subtitle: "\(session.snapshot.batteryTerminalVoltage.formatted(.number.precision(.fractionLength(2)))) V at the terminals",
                      symbol: "battery.100percent", key: \.batteryConnected)
                arrow
                stage(number: "02", title: "Oscillator · the clock", subtitle: "\(session.simulation.configuration.frequency.formatted(.number.precision(.fractionLength(0)))) cycles per second · low-power timing signal",
                      symbol: "waveform.path", key: \.oscillatorEnabled)
                arrow
                stage(number: "03", title: "Power stage · alternating drive", subtitle: "An ideal amplified sine, or a bipolar square wave. This necessary stage is added to the PDF’s outline.",
                      symbol: "bolt.horizontal.fill", key: \.powerStageEnabled)
                arrow
                stage(number: "04", title: "Transformer · voltage gain", subtitle: "\(session.simulation.configuration.turnsRatio.formatted(.number.precision(.fractionLength(1)))) secondary turns per primary turn · same frequency, same waveform",
                      symbol: "point.3.connected.trianglepath.dotted", key: \.transformerConnected)
                waveformControls
                InstrumentPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("AT THE OUTPUT").font(.caption.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
                        WaveformPlot(snapshot: session.snapshot)
                            .frame(height: 180)
                        HStack {
                            BenchMetric(title: "Effective voltage", value: session.snapshot.outputRMSVoltage, unit: "V RMS", color: BenchTheme.amber)
                            BenchMetric(title: "Highest magnitude", value: session.snapshot.outputPeakVoltage, unit: "V peak", color: BenchTheme.teal)
                        }
                        Text("A transformer can step an alternating voltage up. Steady DC has no repeating cycle to transform.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                InstrumentPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The waveform matters.").font(.headline)
                        Text("Sine: RMS = peak ÷ √2\nSquare: RMS = peak\nSecondary voltage = primary voltage × turns ratio")
                            .font(.system(.subheadline, design: .monospaced)).foregroundStyle(BenchTheme.teal)
                        Text("At 12 V DC, this ideal sine driver has an 8.49 V RMS primary. Its nominal 27.1:1 transformer yields 230 V RMS before battery sag. Switch to square without changing the ratio and the RMS voltage rises.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("Frequency affects the real transformer’s magnetics. Here it controls timing only; this toy does not model saturation or winding design.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20).padding(.bottom, 20).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }
        .background(BenchTheme.background)
        .navigationTitle("Inside the box").navigationBarTitleDisplayMode(.inline)
    }

    private var arrow: some View {
        Image(systemName: "arrow.down").foregroundStyle(session.snapshot.isEnergized ? BenchTheme.amber : .secondary)
            .frame(maxWidth: .infinity).accessibilityHidden(true)
    }

    private func stage(number: String, title: String, subtitle: String, symbol: String,
                       key: WritableKeyPath<InverterConfiguration, Bool>) -> some View {
        InstrumentPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(number).font(.caption.monospaced()).foregroundStyle(BenchTheme.amber)
                    Image(systemName: symbol).foregroundStyle(BenchTheme.teal)
                    Spacer()
                    Text(session.simulation.configuration[keyPath: key] ? "CONNECTED" : "OPEN")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
                Toggle(title, isOn: Binding(
                    get: { session.simulation.configuration[keyPath: key] },
                    set: { enabled in session.edit { $0[keyPath: key] = enabled } }))
                    .font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var waveformControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare drive shapes").font(.headline)
            Picker("Waveform", selection: Binding(
                get: { session.simulation.configuration.waveform },
                set: { shape in session.edit { $0.waveform = shape } })) {
                Text("Ideal sine").tag(Waveform.sine)
                Text("Square").tag(Waveform.square)
            }.pickerStyle(.segmented).accessibilityIdentifier("waveformPicker")
        }
    }
}

struct WaveformPlot: View {
    let snapshot: InverterSnapshot
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("+\(snapshot.outputPeakVoltage, specifier: "%.0f") V")
                Spacer()
                Text("40 ms window")
            }.font(.caption.monospaced()).foregroundStyle(.secondary)
            Canvas { context, size in
                let center = size.height / 2
                for part in 0...4 {
                    var line = Path()
                    let x = size.width * Double(part) / 4
                    line.move(to: CGPoint(x: x, y: 0)); line.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(line, with: .color(.white.opacity(0.09)), lineWidth: 1)
                }
                var zero = Path()
                zero.move(to: CGPoint(x: 0, y: center)); zero.addLine(to: CGPoint(x: size.width, y: center))
                context.stroke(zero, with: .color(.white.opacity(0.22)), lineWidth: 1)
                var trace = Path()
                let amplitude = max(1, snapshot.outputPeakVoltage)
                for index in 0...400 {
                    let x = Double(index) / 400
                    let voltage = snapshot.voltage(at: x * 0.04)
                    let point = CGPoint(x: x * size.width,
                                        y: center - voltage / amplitude * size.height * 0.42)
                    if index == 0 { trace.move(to: point) } else { trace.addLine(to: point) }
                }
                context.stroke(trace, with: .color(BenchTheme.teal), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
            }
            HStack {
                Text("−\(snapshot.outputPeakVoltage, specifier: "%.0f") V")
                Spacer()
                Text("0 → 40 ms")
            }.font(.caption.monospaced()).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Output waveform across forty milliseconds")
        .accessibilityValue(snapshot.isEnergized
            ? "\(snapshot.frequency.formatted()) hertz, plus and minus \(snapshot.outputPeakVoltage.formatted()) volts peak"
            : "No AC output")
    }
}
