# ViruS Inverter

An iPhone-only SwiftUI electrical toy for iOS 27, with native Liquid Glass navigation and controls around an original illustrated workshop bench. Follow energy from a car battery through timing, a power stage and a transformer to a bulb and simplified vacuum motor.

## Play

- Connect the battery, then switch on. Watch output voltage, current, load power and conversion loss respond together.
- Connect the default 200 W motor and watch its two-second startup demand. Raise its rating to explore a latched protection trip; switch off, reduce the load and reset protection.
- In **Inside**, disconnect individual stages to break the energy path. Compare sine and square drive, or change frequency and transformer ratio.
- Select 60× or 600× simulation time to spend the battery. When it empties, choose **Replace virtual battery**, then switch on again. Replacement preserves the bench settings.
- The bench menu includes light/motor scenarios, pause and reset. **Notes** includes source boundaries and optional switch haptics and inverter hum. The hum is a sonification; simulation pauses and audio stops while the app is inactive.

## Sources and model

The exterior follows [the film's inverter shot at 6:18](https://www.youtube.com/watch?v=cd7Q8ixYC9A&t=378s): a teal-looking front plate, uneven VIRUS / INVERTER lettering, pale analog meter, red-surround switch and exposed hardware. This is actual film footage hosted by a third party; colors are interpreted under night lighting. [The battery lineup at 5:22](https://www.youtube.com/watch?v=cd7Q8ixYC9A&t=322s) shows clamps and multiple leads without establishing the complete electrical topology. See [Research/FilmResearch.md](Research/FilmResearch.md) for the screenplay and observation record.

The supplied three-page PDF contains [Syam Sanal's 28 June 2014 article](https://syamsanal.blogspot.com/2014/06/virus-inverter.html) and comments. It proposes a 12 V battery, 50 Hz RC phase-shift oscillator and 230 V step-up transformer, without a circuit schematic or component values. The app adds the missing load-driving power stage. Sine drive represents ideal amplification/waveform shaping; square drive represents simple alternating switching. Neither is a measured specification of the film prop.

Teaching assumptions include one 45 Ah battery, 0.02 Ω internal resistance, 85% conversion efficiency plus 5 W idle draw, a fixed-resistance 60 W bulb, and a motor resistance with 3× startup demand for two seconds. Voltage sag, RMS, terminal power balance, charge counting and latched protection are modeled. Battery chemistry, winding saturation, transistor switching and real motor mechanics are excluded. This is not a hardware construction schematic or a simulation of the film's medical procedure.

## Build

Open `VirusInverter.xcodeproj` in Xcode with the iOS 27 SDK and select the **VirusInverter** scheme. The application bundle ID is `com.utkarsh.virusinverter`; automatic signing currently uses development team `YOUR_TEAM_ID`. Change the team for another Apple developer account. The app target supports iPhone only.

`project.yml` is the XcodeGen source. Optional regeneration, from this directory:

```sh
xcodegen generate --spec project.yml
```

The Foundation-only physics package can be tested separately on macOS, with build and module caches outside the Documents checkout:

```sh
swift test --scratch-path /private/tmp/virus-inverter-core-tests \
  -Xswiftc -module-cache-path \
  -Xswiftc /private/tmp/virus-inverter-core-tests/.clangcache
```

## Validation recorded

- Native iOS 27 simulator build and launch passed without warnings.
- Physics validation passed: 21 test functions, 26 cases. Temporary validation/build copies were checked for SHA source parity with the workspace.
- Live simulator UI interaction confirmed battery connection and power-on: bulb output **227.6 V RMS**, battery draw **6.2 A**. Connecting the 200 W motor settled at **220.5 V RMS**, **24.9 A**.
- Native navigation to Inside and its stage layout was also observed. Simulator automation was intermittent; broken-stage toggles, square drive and trip/reset UI remain unverified as direct scenarios. See [Research/Validation.md](Research/Validation.md) for the exact evidence and remaining checks.
- Build 2 removes the two-line “A little box. A very bright idea.” headline. A signed Release build was installed and launched on the connected iPhone 15 Pro Max running iOS 27.2; the installed app reports version 1.0 / build 2, and its running process was confirmed. Audible sound and felt haptics still need hands-on testing.


## Public snapshot

See [PUBLICATION.md](PUBLICATION.md) for publication exclusions and setup requirements.
