// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SettingsFeature",
    platforms: [.macOS(.v14)],
    products: [.library(name: "SettingsFeature", targets: ["SettingsFeature"])],
    targets: [.target(name: "SettingsFeature")]
)
