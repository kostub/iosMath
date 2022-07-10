// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "iosMath",
  defaultLocalization: "en",
  platforms: [.iOS(.v10), .macOS(.v11)],
  products: [
    .library(
      name: "iosMath",
      targets: ["iosMath"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "iosMath",
      dependencies: [],
      path: "./iosMath",
      resources: [
        .process("fonts")
      ],
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath("./render"),
        .headerSearchPath("./lib"),
        .headerSearchPath("./render/internal"),
      ]
    ),
    .testTarget(
      name: "iosMathTests",
      dependencies: ["iosMath"],
      path: "iosMathTests",
      cSettings: [
        .headerSearchPath("../iosMath/render"),
        .headerSearchPath("../iosMath/lib"),
        .headerSearchPath("../iosMath/render/internal"),
      ]
    ),
  ]
)
