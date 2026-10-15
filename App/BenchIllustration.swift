import SwiftUI
import Foundation

/// An interpreted workshop prop. All electrical behavior is supplied by the model.
struct BenchIllustration: View {
    let batteryConnected: Bool
    let powered: Bool
    let outputVoltage: Double
    let lampBrightness: Double
    let motorSpeed: Double
    let motorConnected: Bool
    let tripped: Bool
    var phase: Double = 0
    let reduceMotion: Bool

    private var voltageDescription: String {
        outputVoltage.formatted(.number.precision(.fractionLength(0)))
    }

    var body: some View {
        Canvas { context, size in
            var drawing = context
            let scale = min(size.width / 390, size.height / 340)
            drawing.translateBy(x: (size.width - 390 * scale) / 2,
                                y: (size.height - 340 * scale) / 2)
            drawing.scaleBy(x: scale, y: scale)
            drawBench(in: &drawing)
            drawLamp(in: &drawing)
            drawBatteryLeads(in: &drawing)
            drawEnclosure(in: &drawing)
            drawBattery(in: &drawing)
            drawVacuum(in: &drawing)
            drawEnergy(in: &drawing)
        }
        .frame(height: 340)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ViruS Inverter workbench")
        .accessibilityValue("Battery \(batteryConnected ? "connected" : "disconnected"). Inverter \(tripped ? "tripped" : powered ? "on" : "off"). Output \(voltageDescription) volts AC. Lamp \(Int(lampBrightness.clamped(to: 0...1) * 100)) percent. Vacuum \(motorConnected ? "connected" : "disconnected"), \(Int(motorSpeed.clamped(to: 0...1) * 100)) percent speed.")
    }

    private func drawBench(in context: inout GraphicsContext) {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 340)
        context.fill(Path(roundedRect: bounds, cornerRadius: 26),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.16, green: 0.15, blue: 0.13), Color(red: 0.07, green: 0.075, blue: 0.07)]),
                                           startPoint: .zero, endPoint: CGPoint(x: 390, y: 340)))

        var warmLight = context
        warmLight.addFilter(.blur(radius: 28))
        warmLight.fill(Path(ellipseIn: CGRect(x: 232, y: -17, width: 142, height: 180)),
                       with: .color(Color.orange.opacity(0.05 + lampBrightness.clamped(to: 0...1) * 0.09)))

        // Quiet marks make the objects sit on a bench, without competing with them.
        var floor = Path()
        floor.move(to: CGPoint(x: 20, y: 253))
        floor.addLine(to: CGPoint(x: 372, y: 253))
        context.stroke(floor, with: .color(.white.opacity(0.045)), lineWidth: 1)
        for offset in [0.0, 31.0, 72.0] {
            var grain = Path()
            grain.move(to: CGPoint(x: 14, y: 273 + offset / 2))
            grain.addCurve(to: CGPoint(x: 372, y: 271 + offset / 2),
                           control1: CGPoint(x: 134, y: 263 + offset / 2),
                           control2: CGPoint(x: 254, y: 287 + offset / 2))
            context.stroke(grain, with: .color(Color(red: 0.60, green: 0.44, blue: 0.25).opacity(0.065)), lineWidth: 1)
        }
        shadow(CGRect(x: 67, y: 226, width: 276, height: 41), opacity: 0.5, in: &context)
        shadow(CGRect(x: 8, y: 309, width: 129, height: 20), opacity: 0.55, in: &context)
        shadow(CGRect(x: 265, y: 311, width: 108, height: 18), opacity: 0.55, in: &context)
        label("A LITTLE POWER, BORROWED.", at: CGPoint(x: 22, y: 25), size: 10,
              color: Color(red: 0.72, green: 0.66, blue: 0.53), anchor: .leading, in: &context)
    }

    private func drawEnclosure(in context: inout GraphicsContext) {
        // The film prop is open behind an upright teal front plate. The exposed
        // assembly is illustrative; it is not a construction schematic.
        let railColor = Color(red: 0.32, green: 0.39, blue: 0.35)
        context.fill(Path(roundedRect: CGRect(x: 77, y: 232, width: 239, height: 15), cornerRadius: 3),
                     with: .linearGradient(Gradient(colors: [railColor, Color(red: 0.13, green: 0.19, blue: 0.17)]),
                                           startPoint: CGPoint(x: 77, y: 232), endPoint: CGPoint(x: 77, y: 247)))
        context.fill(Path(CGRect(x: 78, y: 96, width: 7, height: 139)), with: .color(railColor))
        context.fill(Path(CGRect(x: 83, y: 96, width: 209, height: 5)), with: .color(railColor.opacity(0.5)))
        line(from: CGPoint(x: 82, y: 97), to: CGPoint(x: 132, y: 111), color: .white.opacity(0.16), width: 1, in: &context)
        context.fill(Path(roundedRect: CGRect(x: 84, y: 146, width: 52, height: 69), cornerRadius: 4), with: .color(.black.opacity(0.9)))
        for index in 0..<8 {
            let x = 88.0 + Double(index) * 5.5
            line(from: CGPoint(x: x, y: 149), to: CGPoint(x: x, y: 212),
                 color: Color(red: 0.35, green: 0.37, blue: 0.30).opacity(0.5), width: 1.6, in: &context)
        }
        context.fill(Path(roundedRect: CGRect(x: 84, y: 163, width: 42, height: 34), cornerRadius: 7), with: .color(Color(red: 0.36, green: 0.20, blue: 0.12)))
        for index in 0..<9 {
            let y = 166.0 + Double(index) * 3.3
            line(from: CGPoint(x: 87, y: y), to: CGPoint(x: 123, y: y),
                 color: Color(red: 0.75, green: 0.42, blue: 0.21).opacity(0.65), width: 1.5, in: &context)
        }
        context.fill(Path(CGRect(x: 97, y: 158, width: 15, height: 45)), with: .color(Color(red: 0.12, green: 0.14, blue: 0.12)))
        context.fill(Path(roundedRect: CGRect(x: 90, y: 111, width: 43, height: 25), cornerRadius: 2), with: .color(Color(red: 0.10, green: 0.29, blue: 0.22)))
        for x in [96.0, 104.0, 112.0, 120.0] {
            line(from: CGPoint(x: x, y: 116), to: CGPoint(x: x + 5, y: 129),
                 color: Color(red: 0.71, green: 0.55, blue: 0.24).opacity(0.7), width: 1, in: &context)
            context.fill(Path(ellipseIn: CGRect(x: x, y: 118, width: 3, height: 3)), with: .color(Color(red: 0.79, green: 0.68, blue: 0.40)))
        }
        var redWire = Path()
        redWire.move(to: CGPoint(x: 114, y: 121))
        redWire.addCurve(to: CGPoint(x: 105, y: 218), control1: CGPoint(x: 64, y: 117), control2: CGPoint(x: 62, y: 191))
        context.stroke(redWire, with: .color(Color(red: 0.75, green: 0.26, blue: 0.18)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        var yellowWire = Path()
        yellowWire.move(to: CGPoint(x: 128, y: 119))
        yellowWire.addCurve(to: CGPoint(x: 137, y: 212), control1: CGPoint(x: 160, y: 104), control2: CGPoint(x: 153, y: 203))
        context.stroke(yellowWire, with: .color(Color(red: 0.75, green: 0.61, blue: 0.22)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        let plate = Path(roundedRect: CGRect(x: 132, y: 101, width: 183, height: 142), cornerRadius: 3)
        context.fill(plate, with: .linearGradient(Gradient(colors: [Color(red: 0.21, green: 0.63, blue: 0.63),
                                                                               Color(red: 0.11, green: 0.46, blue: 0.46),
                                                                               Color(red: 0.12, green: 0.35, blue: 0.35)]),
                                                 startPoint: CGPoint(x: 136, y: 102), endPoint: CGPoint(x: 305, y: 247)))
        context.stroke(plate, with: .color(Color(red: 0.58, green: 0.85, blue: 0.80).opacity(0.43)), lineWidth: 1)
        line(from: CGPoint(x: 134, y: 103), to: CGPoint(x: 312, y: 103), color: .white.opacity(0.23), width: 1, in: &context)
        line(from: CGPoint(x: 315, y: 107), to: CGPoint(x: 315, y: 239), color: .black.opacity(0.45), width: 2, in: &context)
        for mark in [CGRect(x: 154, y: 111, width: 23, height: 1), CGRect(x: 283, y: 182, width: 12, height: 1), CGRect(x: 144, y: 225, width: 9, height: 1)] {
            context.fill(Path(mark), with: .color(Color(red: 0.72, green: 0.82, blue: 0.65).opacity(0.25)))
        }
        for point in [CGPoint(x: 141, y: 109), CGPoint(x: 306, y: 109), CGPoint(x: 141, y: 234), CGPoint(x: 306, y: 234)] {
            drawScrew(at: point, in: &context)
        }
        for x in [91.0, 277.0] {
            context.fill(Path(roundedRect: CGRect(x: x, y: 246, width: 24, height: 8), cornerRadius: 2), with: .color(Color(red: 0.065, green: 0.07, blue: 0.065)))
        }
        drawMeter(in: &context)
        drawLettering(in: &context)
        drawSwitch(in: &context)

        // Small modeled output connector, placed below the prop's lettering.
        context.fill(Path(ellipseIn: CGRect(x: 279, y: 222, width: 18, height: 18)), with: .color(.black))
        context.stroke(Path(ellipseIn: CGRect(x: 278, y: 221, width: 20, height: 20)), with: .color(Color(red: 0.57, green: 0.67, blue: 0.55)), lineWidth: 1)
        context.fill(Path(roundedRect: CGRect(x: 283, y: 227, width: 10, height: 9), cornerRadius: 2), with: .color(Color(red: 0.21, green: 0.22, blue: 0.18)))
        drawTerminal(at: CGPoint(x: 101, y: 218), color: Color(red: 0.70, green: 0.22, blue: 0.13), in: &context)
        drawTerminal(at: CGPoint(x: 125, y: 218), color: Color(red: 0.11, green: 0.12, blue: 0.11), in: &context)
    }

    private func drawMeter(in context: inout GraphicsContext) {
        // A white rectangular face in the verified upper-right position. The
        // scale here is a teaching instrument rather than a reading of the prop.
        let meterFrame = CGRect(x: 221, y: 119, width: 80, height: 58)
        context.fill(Path(roundedRect: meterFrame, cornerRadius: 2), with: .color(Color(red: 0.91, green: 0.93, blue: 0.85)))
        context.stroke(Path(roundedRect: meterFrame, cornerRadius: 2), with: .color(.black.opacity(0.6)), lineWidth: 1)
        let face = CGRect(x: 225, y: 123, width: 72, height: 50)
        context.fill(Path(roundedRect: face, cornerRadius: 4),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.89, green: 0.92, blue: 0.85), Color(red: 0.70, green: 0.79, blue: 0.72)]),
                                           startPoint: face.origin, endPoint: CGPoint(x: 292, y: 173)))
        let center = CGPoint(x: 261, y: 163)
        for index in 0...10 {
            let angle = (-150 + Double(index) * 12) * .pi / 180
            let outer = polar(center: center, radius: 29, angle: angle)
            let inner = polar(center: center, radius: index.isMultiple(of: 5) ? 23 : 26, angle: angle)
            line(from: inner, to: outer, color: .black.opacity(0.72), width: 1, in: &context)
        }
        label("0", at: CGPoint(x: 235, y: 154), size: 7, color: .black.opacity(0.75), in: &context)
        label("280", at: CGPoint(x: 285, y: 153), size: 7, color: .black.opacity(0.75), in: &context)
        label("V RMS", at: CGPoint(x: 261, y: 168), size: 7, color: .black.opacity(0.7), in: &context)
        let angle = (-150 + outputVoltage.clamped(to: 0...280) / 280 * 120) * .pi / 180
        line(from: center, to: polar(center: center, radius: 27, angle: angle),
             color: Color(red: 0.51, green: 0.13, blue: 0.08), width: 1.5, in: &context)
        context.fill(Path(ellipseIn: CGRect(x: 258.5, y: 160.5, width: 5, height: 5)), with: .color(Color(red: 0.22, green: 0.20, blue: 0.15)))
        var highlight = Path()
        highlight.move(to: CGPoint(x: 229, y: 124))
        highlight.addLine(to: CGPoint(x: 265, y: 124))
        highlight.addLine(to: CGPoint(x: 242, y: 172))
        highlight.addLine(to: CGPoint(x: 227, y: 172))
        highlight.closeSubpath()
        context.fill(highlight, with: .color(.white.opacity(0.08)))
    }

    private func drawLettering(in context: inout GraphicsContext) {
        // Irregular positioning evokes the hand-painted capitals in the film.
        let ink = Color(red: 0.045, green: 0.095, blue: 0.09)
        for (index, character) in Array("VIRUS").enumerated() {
            var letter = context
            letter.translateBy(x: 164 + Double(index) * 24, y: 189 + (index.isMultiple(of: 2) ? 0 : 2))
            letter.rotate(by: .degrees([-5.0, 2.0, -2.0, 4.0, -3.0][index]))
            letter.draw(Text(String(character)).font(.system(size: 27, weight: .heavy, design: .rounded)).foregroundStyle(ink), at: .zero)
        }
        for (index, character) in Array("INVERTER").enumerated() {
            var letter = context
            letter.translateBy(x: 153 + Double(index) * 19.5, y: 215 + (index.isMultiple(of: 2) ? 0 : -1))
            letter.rotate(by: .degrees(index.isMultiple(of: 3) ? -4 : 1))
            letter.draw(Text(String(character)).font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(ink), at: .zero)
        }
    }

    private func drawSwitch(in context: inout GraphicsContext) {
        let lightColor: Color = tripped ? .red : powered ? Color(red: 0.66, green: 0.87, blue: 0.51) : Color(red: 0.29, green: 0.32, blue: 0.23)
        if powered || tripped {
            var glow = context
            glow.addFilter(.blur(radius: 5))
            glow.fill(Path(ellipseIn: CGRect(x: 200, y: 165, width: 10, height: 10)), with: .color(lightColor.opacity(0.55)))
        }
        context.fill(Path(ellipseIn: CGRect(x: 201, y: 166, width: 8, height: 8)), with: .color(.black.opacity(0.7)))
        context.fill(Path(ellipseIn: CGRect(x: 203, y: 168, width: 4, height: 4)), with: .color(lightColor))
        let switchBase = Path(roundedRect: CGRect(x: 193, y: 125, width: 23, height: 37), cornerRadius: 2)
        context.fill(switchBase, with: .linearGradient(Gradient(colors: [Color(red: 0.82, green: 0.20, blue: 0.15), Color(red: 0.42, green: 0.085, blue: 0.075)]),
                                                      startPoint: CGPoint(x: 193, y: 125), endPoint: CGPoint(x: 216, y: 162)))
        context.stroke(switchBase, with: .color(.black.opacity(0.35)), lineWidth: 1)
        context.fill(Path(roundedRect: CGRect(x: 197, y: 129, width: 15, height: 29), cornerRadius: 2), with: .color(Color(red: 0.15, green: 0.14, blue: 0.11)))
        let rocker = CGRect(x: 198, y: powered ? 130 : 141, width: 13, height: 15)
        context.fill(Path(roundedRect: rocker, cornerRadius: 3),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.90, green: 0.91, blue: 0.84), Color(red: 0.55, green: 0.61, blue: 0.55)]),
                                           startPoint: rocker.origin, endPoint: CGPoint(x: rocker.maxX, y: rocker.maxY)))
        line(from: CGPoint(x: rocker.minX + 2, y: rocker.minY + 3), to: CGPoint(x: rocker.maxX - 2, y: rocker.minY + 3), color: .white.opacity(0.4), width: 1, in: &context)
    }

    private func drawBatteryLeads(in context: inout GraphicsContext) {
        let red = Color(red: 0.73, green: 0.24, blue: 0.12)
        var redLead = Path()
        redLead.move(to: CGPoint(x: 101, y: 218))
        redLead.addCurve(to: CGPoint(x: 42, y: 257), control1: CGPoint(x: 48, y: 209), control2: CGPoint(x: 6, y: 211))
        var blackLead = Path()
        blackLead.move(to: CGPoint(x: 125, y: 218))
        blackLead.addCurve(to: CGPoint(x: batteryConnected ? 99 : 121, y: batteryConnected ? 257 : 291),
                           control1: CGPoint(x: 140, y: 265), control2: CGPoint(x: 142, y: 285))
        for (lead, color) in [(redLead, red), (blackLead, Color(red: 0.12, green: 0.13, blue: 0.12))] {
            context.stroke(lead, with: .color(.black.opacity(0.7)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            context.stroke(lead, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
        if !batteryConnected {
            var clip = context
            clip.translateBy(x: 122, y: 290)
            clip.rotate(by: .degrees(27))
            clip.fill(Path(roundedRect: CGRect(x: -4, y: -11, width: 8, height: 18), cornerRadius: 2), with: .color(Color(red: 0.28, green: 0.30, blue: 0.25)))
            clip.fill(Path(CGRect(x: -3, y: -15, width: 6, height: 6)), with: .color(Color(red: 0.60, green: 0.57, blue: 0.43)))
        }
    }

    private func drawBattery(in context: inout GraphicsContext) {
        let front = Path(roundedRect: CGRect(x: 19, y: 265, width: 99, height: 53), cornerRadius: 6)
        context.fill(front, with: .linearGradient(Gradient(colors: [Color(red: 0.42, green: 0.45, blue: 0.40), Color(red: 0.17, green: 0.20, blue: 0.18)]),
                                                 startPoint: CGPoint(x: 21, y: 265), endPoint: CGPoint(x: 100, y: 318)))
        context.stroke(front, with: .color(Color(red: 0.47, green: 0.52, blue: 0.43).opacity(0.28)), lineWidth: 1)
        context.fill(Path(roundedRect: CGRect(x: 16, y: 258, width: 105, height: 14), cornerRadius: 4),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.22, green: 0.44, blue: 0.58), Color(red: 0.10, green: 0.23, blue: 0.32)]),
                                           startPoint: CGPoint(x: 20, y: 258), endPoint: CGPoint(x: 20, y: 273)))
        context.fill(Path(roundedRect: CGRect(x: 17, y: 261, width: 103, height: 4), cornerRadius: 1), with: .color(Color(red: 0.62, green: 0.21, blue: 0.14)))
        for x in [51.0, 59.0, 67.0, 75.0, 83.0, 91.0] {
            context.fill(Path(ellipseIn: CGRect(x: x - 2.5, y: 256, width: 6, height: 4)), with: .color(Color(red: 0.91, green: 0.93, blue: 0.81)))
            line(from: CGPoint(x: x - 0.5, y: 257), to: CGPoint(x: x + 1.5, y: 257), color: .black.opacity(0.25), width: 0.6, in: &context)
        }
        for x in [37.0, 94.0] {
            context.fill(Path(roundedRect: CGRect(x: x, y: 251, width: 10, height: 10), cornerRadius: 2), with: .color(Color(red: 0.52, green: 0.52, blue: 0.42)))
            context.fill(Path(ellipseIn: CGRect(x: x, y: 249, width: 10, height: 5)), with: .color(Color(red: 0.68, green: 0.67, blue: 0.55)))
        }
        context.fill(Path(roundedRect: CGRect(x: 33, y: 253, width: 18, height: 9), cornerRadius: 3), with: .color(Color(red: 0.70, green: 0.25, blue: 0.15)))
        if batteryConnected {
            context.fill(Path(roundedRect: CGRect(x: 90, y: 253, width: 18, height: 9), cornerRadius: 3), with: .color(Color(red: 0.13, green: 0.48, blue: 0.47)))
        }
        label("+", at: CGPoint(x: 42, y: 263), size: 11, color: .white.opacity(0.6), in: &context)
        label("−", at: CGPoint(x: 99, y: 263), size: 11, color: .white.opacity(0.6), in: &context)
        context.fill(Path(roundedRect: CGRect(x: 34, y: 280, width: 70, height: 25), cornerRadius: 2), with: .color(Color(red: 0.76, green: 0.70, blue: 0.52)))
        label("12 V", at: CGPoint(x: 69, y: 290), size: 17, color: Color(red: 0.15, green: 0.20, blue: 0.15), weight: .bold, in: &context)
        label("CAR BATTERY", at: CGPoint(x: 69, y: 301), size: 6.5, color: Color(red: 0.25, green: 0.28, blue: 0.20), in: &context)
        for x in [25.0, 111.0] {
            line(from: CGPoint(x: x, y: 278), to: CGPoint(x: x, y: 312), color: .white.opacity(0.06), width: 2, in: &context)
        }
    }

    private func drawLamp(in context: inout GraphicsContext) {
        let brightness = lampBrightness.clamped(to: 0...1)
        var cable = Path()
        cable.move(to: CGPoint(x: 288, y: 231))
        cable.addCurve(to: CGPoint(x: 333, y: 127), control1: CGPoint(x: 349, y: 224), control2: CGPoint(x: 350, y: 170))
        cable.addCurve(to: CGPoint(x: 333, y: 95), control1: CGPoint(x: 324, y: 118), control2: CGPoint(x: 335, y: 108))
        context.stroke(cable, with: .color(.black.opacity(0.8)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        context.stroke(cable, with: .color(Color(red: 0.38, green: 0.28, blue: 0.16)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        if brightness > 0.01 {
            var glow = context
            glow.addFilter(.blur(radius: 21))
            glow.fill(Path(ellipseIn: CGRect(x: 296, y: 31, width: 76, height: 80)),
                      with: .color(Color(red: 1, green: 0.66, blue: 0.21).opacity(brightness * 0.7)))
            glow.fill(Path(ellipseIn: CGRect(x: 313, y: 45, width: 42, height: 48)),
                      with: .color(Color(red: 1, green: 0.83, blue: 0.42).opacity(brightness * 0.6)))
        }
        var bulb = Path()
        bulb.move(to: CGPoint(x: 323, y: 89))
        bulb.addCurve(to: CGPoint(x: 313, y: 62), control1: CGPoint(x: 323, y: 79), control2: CGPoint(x: 313, y: 79))
        bulb.addCurve(to: CGPoint(x: 353, y: 62), control1: CGPoint(x: 313, y: 34), control2: CGPoint(x: 353, y: 34))
        bulb.addCurve(to: CGPoint(x: 343, y: 89), control1: CGPoint(x: 353, y: 79), control2: CGPoint(x: 343, y: 79))
        bulb.closeSubpath()
        context.fill(bulb, with: .linearGradient(Gradient(colors: [Color(red: 0.68 + brightness * 0.32, green: 0.66 + brightness * 0.22, blue: 0.50 + brightness * 0.06).opacity(0.40 + brightness * 0.6),
                                                                               Color(red: 0.32 + brightness * 0.63, green: 0.32 + brightness * 0.35, blue: 0.24).opacity(0.55 + brightness * 0.45)]),
                                                 startPoint: CGPoint(x: 320, y: 45), endPoint: CGPoint(x: 349, y: 90)))
        context.stroke(bulb, with: .color(Color(red: 0.98, green: 0.88, blue: 0.59).opacity(0.27 + brightness * 0.4)), lineWidth: 1)
        var filament = Path()
        filament.move(to: CGPoint(x: 327, y: 85))
        filament.addLine(to: CGPoint(x: 325, y: 64))
        filament.addLine(to: CGPoint(x: 329, y: 68))
        filament.addLine(to: CGPoint(x: 333, y: 62))
        filament.addLine(to: CGPoint(x: 337, y: 68))
        filament.addLine(to: CGPoint(x: 341, y: 64))
        filament.addLine(to: CGPoint(x: 338, y: 85))
        context.stroke(filament, with: .color(Color(red: 1, green: 0.81, blue: 0.37).opacity(0.3 + brightness * 0.7)), lineWidth: 1)
        for index in 0..<4 {
            let y = 89.0 + Double(index) * 3.5
            context.fill(Path(roundedRect: CGRect(x: 322, y: y, width: 22, height: 3), cornerRadius: 1),
                         with: .linearGradient(Gradient(colors: [Color(red: 0.59, green: 0.48, blue: 0.30), Color(red: 0.22, green: 0.20, blue: 0.13)]),
                                               startPoint: CGPoint(x: 322, y: y), endPoint: CGPoint(x: 344, y: y)))
        }
        context.fill(Path(roundedRect: CGRect(x: 328, y: 103, width: 10, height: 5), cornerRadius: 2), with: .color(Color(red: 0.12, green: 0.13, blue: 0.10)))
        var glassHighlight = Path()
        glassHighlight.move(to: CGPoint(x: 320, y: 62))
        glassHighlight.addQuadCurve(to: CGPoint(x: 325, y: 48), control: CGPoint(x: 319, y: 51))
        context.stroke(glassHighlight, with: .color(.white.opacity(0.24)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private func drawVacuum(in context: inout GraphicsContext) {
        let speed = motorSpeed.clamped(to: 0...1)
        var cord = Path()
        cord.move(to: CGPoint(x: 288, y: 231))
        cord.addCurve(to: CGPoint(x: motorConnected ? 288 : 259, y: motorConnected ? 288 : 312),
                      control1: CGPoint(x: 321, y: 238), control2: CGPoint(x: 238, y: 292))
        context.stroke(cord, with: .color(Color(red: 0.24, green: 0.23, blue: 0.17)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        if !motorConnected {
            context.fill(Path(roundedRect: CGRect(x: 251, y: 308, width: 11, height: 8), cornerRadius: 2), with: .color(Color(red: 0.31, green: 0.29, blue: 0.20)))
            line(from: CGPoint(x: 250, y: 310), to: CGPoint(x: 246, y: 310), color: .white.opacity(0.45), width: 1, in: &context)
            line(from: CGPoint(x: 250, y: 314), to: CGPoint(x: 246, y: 314), color: .white.opacity(0.45), width: 1, in: &context)
        }
        var hose = Path()
        hose.move(to: CGPoint(x: 342, y: 289))
        hose.addCurve(to: CGPoint(x: 370, y: 269), control1: CGPoint(x: 366, y: 300), control2: CGPoint(x: 376, y: 284))
        hose.addCurve(to: CGPoint(x: 356, y: 248), control1: CGPoint(x: 364, y: 254), control2: CGPoint(x: 356, y: 257))
        context.stroke(hose, with: .color(.black.opacity(0.8)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
        context.stroke(hose, with: .color(Color(red: 0.24, green: 0.28, blue: 0.23)), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [2, 2]))
        context.fill(Path(roundedRect: CGRect(x: 346, y: 243, width: 24, height: 8), cornerRadius: 3), with: .color(Color(red: 0.39, green: 0.42, blue: 0.33)))
        context.fill(Path(roundedRect: CGRect(x: 296, y: 265, width: 38, height: 14), cornerRadius: 7), with: .color(Color(red: 0.23, green: 0.27, blue: 0.22)))
        let body = Path(roundedRect: CGRect(x: 279, y: 279, width: 70, height: 35), cornerRadius: 16)
        context.fill(body, with: .linearGradient(Gradient(colors: [Color(red: 0.53, green: 0.63, blue: 0.52), Color(red: 0.21, green: 0.34, blue: 0.29)]),
                                                startPoint: CGPoint(x: 284, y: 280), endPoint: CGPoint(x: 346, y: 315)))
        context.stroke(body, with: .color(.white.opacity(0.16)), lineWidth: 1)
        context.fill(Path(ellipseIn: CGRect(x: 285, y: 302, width: 16, height: 16)), with: .color(Color(red: 0.08, green: 0.12, blue: 0.10)))
        context.fill(Path(ellipseIn: CGRect(x: 328, y: 302, width: 16, height: 16)), with: .color(Color(red: 0.08, green: 0.12, blue: 0.10)))
        context.fill(Path(ellipseIn: CGRect(x: 290, y: 307, width: 6, height: 6)), with: .color(Color(red: 0.39, green: 0.44, blue: 0.34)))
        context.fill(Path(ellipseIn: CGRect(x: 333, y: 307, width: 6, height: 6)), with: .color(Color(red: 0.39, green: 0.44, blue: 0.34)))
        let rotorCenter = CGPoint(x: 317, y: 294)
        context.fill(Path(ellipseIn: CGRect(x: 307, y: 284, width: 20, height: 20)), with: .color(Color(red: 0.13, green: 0.23, blue: 0.18)))
        var rotor = context
        rotor.translateBy(x: rotorCenter.x, y: rotorCenter.y)
        rotor.rotate(by: .radians(reduceMotion || speed < 0.01 ? 0 : phase * .pi * 2))
        for angle in [0.0, 120.0, 240.0] {
            var blade = rotor
            blade.rotate(by: .degrees(angle))
            blade.fill(Path(ellipseIn: CGRect(x: -2, y: -8, width: 4, height: 8)),
                       with: .color(Color(red: 0.67, green: 0.74, blue: 0.59).opacity(0.45 + speed * 0.35)))
        }
        context.fill(Path(ellipseIn: CGRect(x: 315, y: 292, width: 4, height: 4)), with: .color(Color(red: 0.75, green: 0.78, blue: 0.63)))
        if speed > 0.1 && !reduceMotion {
            var airflow = Path()
            airflow.move(to: CGPoint(x: 355, y: 234))
            airflow.addQuadCurve(to: CGPoint(x: 362, y: 226), control: CGPoint(x: 362, y: 232))
            airflow.move(to: CGPoint(x: 345, y: 235))
            airflow.addQuadCurve(to: CGPoint(x: 348, y: 225), control: CGPoint(x: 350, y: 231))
            context.stroke(airflow, with: .color(Color(red: 0.62, green: 0.78, blue: 0.67).opacity(speed * 0.4)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
    }

    private func drawEnergy(in context: inout GraphicsContext) {
        guard powered, batteryConnected, !tripped, outputVoltage > 1 else { return }
        // A subtle traveling glint follows the battery lead. A static cue remains
        // with Reduce Motion so animation never carries essential information.
        let progress = reduceMotion ? 0.5 : phase.clamped(to: 0...1)
        let t = 1 - progress
        let inverse = 1 - t
        let x = inverse * inverse * inverse * 101 + 3 * inverse * inverse * t * 48 + 3 * inverse * t * t * 6 + t * t * t * 42
        let y = inverse * inverse * inverse * 218 + 3 * inverse * inverse * t * 209 + 3 * inverse * t * t * 211 + t * t * t * 257
        var spark = context
        spark.addFilter(.shadow(color: .orange.opacity(0.7), radius: 4))
        spark.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)), with: .color(Color(red: 1, green: 0.74, blue: 0.34)))
    }

    private func drawTerminal(at point: CGPoint, color: Color, in context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: point.x - 5.5, y: point.y - 5.5, width: 11, height: 11)), with: .color(color))
        context.fill(Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)), with: .color(Color(red: 0.57, green: 0.53, blue: 0.38)))
    }

    private func drawScrew(at point: CGPoint, in context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.59, green: 0.61, blue: 0.52), Color(red: 0.22, green: 0.25, blue: 0.21)]),
                                           startPoint: CGPoint(x: point.x - 3, y: point.y - 3), endPoint: CGPoint(x: point.x + 3, y: point.y + 3)))
        line(from: CGPoint(x: point.x - 1.5, y: point.y + 1.5), to: CGPoint(x: point.x + 1.5, y: point.y - 1.5), color: .black.opacity(0.7), width: 0.8, in: &context)
    }

    private func shadow(_ rect: CGRect, opacity: Double, in context: inout GraphicsContext) {
        var shadowContext = context
        shadowContext.addFilter(.blur(radius: 9))
        shadowContext.fill(Path(ellipseIn: rect), with: .color(.black.opacity(opacity)))
    }

    private func line(from start: CGPoint, to end: CGPoint, color: Color, width: CGFloat, in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func label(_ text: String, at point: CGPoint, size: CGFloat, color: Color,
                       weight: Font.Weight = .medium, anchor: UnitPoint = .center, in context: inout GraphicsContext) {
        context.draw(Text(text).font(.system(size: size, weight: weight, design: .monospaced)).foregroundStyle(color),
                     at: point, anchor: anchor)
    }

    private func polar(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
