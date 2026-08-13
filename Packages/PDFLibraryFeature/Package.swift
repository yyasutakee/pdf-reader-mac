// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "PDFLibraryFeature",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PDFLibraryFeature", targets: ["PDFLibraryFeature"])],
    targets: [.target(name: "PDFLibraryFeature")]
)
