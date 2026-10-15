// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VirusInverter",
    platforms: [.macOS(.v13), .iOS("27.0")],
    products: [.library(name: "InverterCore", targets: ["InverterCore"])],
    targets: [
        .target(name: "InverterCore"),
        .testTarget(name: "InverterCoreTests", dependencies: ["InverterCore"])
    ]
)
