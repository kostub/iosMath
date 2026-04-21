// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "iosMath",
  defaultLocalization: "en",
  platforms: [.iOS(.v10), .macOS(.v11)],
  products: [
    .library(
      name: "iosMathCore",
      targets: ["iosMathCore"]),
    .library(
      name: "iosMath",
      targets: ["iosMath"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "iosMathCore",
      dependencies: [],
      path: "./iosMath/lib",
      publicHeadersPath: ""
    ),
    .target(
      name: "iosMath",
      dependencies: ["iosMathCore"],
      path: "./iosMath",
      exclude: ["lib"],
      resources: [
        .process("fonts")
      ],
      cSettings: [
        .headerSearchPath("./render"),
        .headerSearchPath("./lib"),
        .headerSearchPath("./render/internal"),
        // Prevent NSAssert from crashing the app in release builds
        .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release)),
      ]
    ),
    .testTarget(
      name: "iosMathTests",
      dependencies: ["iosMath", "iosMathCore"],
      path: "iosMathTests",
      cSettings: [
        .headerSearchPath("../iosMath/render"),
      ]
    ),
  ]
)
