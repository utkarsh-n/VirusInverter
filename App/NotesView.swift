import SwiftUI

struct NotesView: View {
    let session: InverterSession
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("All is well.\nThe power still has to come from somewhere.")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("An interactive interpretation of Rancho’s ViruS Inverter in 3 Idiots, built around the technical outline in your Syam Sanal PDF.")
                        .foregroundStyle(.secondary)
                }.padding(.vertical, 8)
            }
            Section("Try these") {
                experiment("01 · Restore the light", text: "Connect the battery and switch on. Watch the bulb light up and the meter settle below the nominal 230 V because the battery has internal resistance.")
                experiment("02 · Feel a motor start", text: "Connect the vacuum while the bulb is on. Its first two seconds demand three times its rated load. Increase the motor rating, disconnect and reconnect it, and observe protection trip.")
                experiment("03 · Break the chain", text: "Open Inside and disconnect the oscillator, power stage, or transformer. The output becomes zero. Restore the stage to restore the energy path.")
                experiment("04 · Different shape, different RMS", text: "With only the bulb connected, compare sine and square in Inside. At a fixed primary peak, square has a higher RMS voltage. Here the extra power draw also causes more battery sag, so the peak changes slightly too.")
                experiment("05 · Spend the battery", text: "Choose 600× time on the bench to see charge drain. When it is empty, use Replace virtual battery. Runtime is a simple amp-hour estimate at the present draw, rather than a battery lifetime prediction.")
            }
            Section("What the film actually shows") {
                Text("The box has a blue-green front plate, uneven VIRUS / INVERTER lettering, a pale analog meter, a red-surround switch, and exposed parts behind it. A bank of car batteries with clamps and colorful leads powers it.")
                Text("The switch restores selected lighting, a computer and a vacuum. The film does not reveal a complete circuit, reliable meter scale, or measured electrical ratings. This toy focuses on the light and motor loads.")
                    .foregroundStyle(.secondary)
                Link("View the inverter shot · 6:18", destination: URL(string: "https://www.youtube.com/watch?v=cd7Q8ixYC9A&t=378s")!)
                Link("View the battery lineup · 5:22", destination: URL(string: "https://www.youtube.com/watch?v=cd7Q8ixYC9A&t=322s")!)
                Text("Visual references are actual film footage hosted by a third-party uploader. Prop details are interpreted from night-lit frames.")
                    .font(.caption).foregroundStyle(.secondary)
                Link("Read the published screenplay", destination: URL(string: "https://images.assettype.com/filmcompanion/2022-10/6f236251-fb66-4788-83f3-071d80db443d/3_idiots_final_1.pdf")!)
            }
            Section("What the PDF supplies") {
                Text("Syam Sanal’s article, 28 June 2014: a 12 V car battery, a 50 Hz RC phase-shift oscillator, and a step-up transformer for 230 V AC. Your three-page PDF includes the article and its comments; it contains no schematic or component values.")
                Link("Original article", destination: URL(string: "https://syamsanal.blogspot.com/2014/06/virus-inverter.html")!)
            }
            Section("What we add to make the logic complete") {
                Text("The oscillator is a timing source. A load-driving power stage is necessary between it and the transformer. The ideal sine option represents amplification and waveform shaping; square represents a simple alternating drive. A transformer preserves the input waveform and frequency.")
                Text("A multivibrator can generate square waves, and an inverter need not output a sine. The article’s optional phase-converter suggestion is not part of this single-phase model.")
                Text("Teaching assumptions: one 45 Ah battery, 0.02 Ω internal resistance, 85% conversion efficiency plus 5 W idle draw; a fixed-resistance 60 W bulb; a simplified motor resistance with 3× startup demand for 2 seconds. The small motor starts at a nominal 200 W rating.")
                Text("Protection assumptions: 10.5 V terminal cutoff, 150 A battery-current ceiling, 1,000 W steady or 1,800 W startup output limit. Trips latch until the power switch is off and protection is reset. These are toy settings, not specifications of the film prop.")
                Text("The model conserves terminal power. Conversion loss is separate from I²R heating inside the battery. It does not model chemistry, Peukert effects, winding saturation, feedback regulation, transistor switching, or real motor mechanics.")
                Link("Power-stage background · Microchip", destination: URL(string: "https://www.microchip.com/content/dam/mchp/documents/APID/ProductDocuments/DataSheets/MIC4604-Data-Sheet-DS20005852.pdf")!)
                Text("This is an electrical simulation, not a construction schematic or a simulation of the film’s medical procedure.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Feel and listen") {
                Toggle("Tactile switches", isOn: Binding(get: { session.hapticsEnabled }, set: { session.hapticsEnabled = $0 }))
                Toggle("Inverter hum", isOn: Binding(get: { session.soundEnabled }, set: { session.soundEnabled = $0 }))
                Text("Optional hum follows the oscillator setting and delivered power. It is a sonification, not a recording or physical acoustic simulation. It stops when the app is inactive or the simulation is paused.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(BenchTheme.background)
        .navigationTitle("Field notes").navigationBarTitleDisplayMode(.inline)
    }

    private func experiment(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(BenchTheme.amber)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }.padding(.vertical, 6)
    }
}
