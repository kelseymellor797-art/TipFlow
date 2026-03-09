// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TipFlow",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TipFlowModels", targets: ["TipFlowModels"]),
    ],
    targets: [
        .target(
            name: "TipFlowModels",
            path: "TipFlow/Models"
        ),
        .testTarget(
            name: "TipFlowTests",
            dependencies: ["TipFlowModels"],
            path: "TipFlowTests"
        ),
    ]
)
