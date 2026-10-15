import SwiftUI

enum BenchTheme {
    static let amber = Color(red: 0.96, green: 0.66, blue: 0.29)
    static let teal = Color(red: 0.34, green: 0.81, blue: 0.78)
    static let panel = Color(red: 0.13, green: 0.14, blue: 0.15)
    static let background = Color(red: 0.055, green: 0.064, blue: 0.075)
}

struct InstrumentPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BenchTheme.panel, in: .rect(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.07), lineWidth: 1))
    }
}

struct BenchMetric: View {
    let title: String
    let value: Double
    let unit: String
    var color: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value, format: .number.precision(.fractionLength(1)))
                .font(.system(.title2, design: .rounded, weight: .semibold)).monospacedDigit()
                .foregroundStyle(color)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct DialSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    var step: Double = 1
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(value, specifier: step < 1 ? "%.1f" : "%.0f") \(unit)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(BenchTheme.amber)
            }
            Slider(value: $value, in: range, step: step) { Text(title) }
                .accessibilityValue("\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)")
        }
    }
}
