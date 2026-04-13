// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iosMath",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "iosMath",
            targets: ["iosMath"]
        ),
    ],
    targets: [
        .target(
            name: "iosMath",
            path: "iosMath",
            resources: [
                .copy("fonts"),
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("lib"),
                .headerSearchPath("render"),
                .headerSearchPath("render/internal"),
            ]
        ),
        .testTarget(
            name: "iosMathTests",
            dependencies: ["iosMath"],
            path: "iosMathTests",
            exclude: ["en.lproj"],
            cSettings: [
                .headerSearchPath("../iosMath/lib"),
                .headerSearchPath("../iosMath/render"),
                .headerSearchPath("../iosMath/render/internal"),
            ]
        ),
    ]
)
