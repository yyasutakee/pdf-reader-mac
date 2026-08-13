// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "PDFReaderFeature",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PDFReaderFeature", targets: ["PDFReaderFeature"])],
    targets: [.target(name: "PDFReaderFeature")]
)
