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
                .headerSearchPath("."),
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
                .headerSearchPath("../iosMath"),
                .headerSearchPath("../iosMath/lib"),
                .headerSearchPath("../iosMath/render"),
                .headerSearchPath("../iosMath/render/internal"),
            ]
        ),
        .testTarget(
            name: "iosMathSwiftTests",
            dependencies: ["iosMath"],
            path: "iosMathSwiftTests",
            cSettings: [
                .headerSearchPath("../iosMath"),
                .headerSearchPath("../iosMath/lib"),
                .headerSearchPath("../iosMath/render"),
                .headerSearchPath("../iosMath/render/internal"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        // Regression guard for issue #215. Imports `iosMath` purely as a Clang
        // module with NO header search paths, reproducing how an external SPM
        // consumer builds the module. If a public header reintroduces a bare
        // cross-directory `#import`, this target fails to compile.
        .testTarget(
            name: "iosMathConsumerTests",
            dependencies: ["iosMath"],
            path: "iosMathConsumerTests"
        ),
    ]
)
