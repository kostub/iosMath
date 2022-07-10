// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "IosMath",
  defaultLocalization: "en",
  platforms: [.iOS(.v10), .macOS(.v11)],
  products: [
    .library(
      name: "IosMath",
      targets: ["IosMath"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "IosMath",
      dependencies: [],
      path: "./IosMath",
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
      name: "IosMathTests",
      dependencies: ["IosMath"],
      path: "IosMathTests",
      cSettings: [
        .headerSearchPath("../IosMath/render"),
        .headerSearchPath("../IosMath/lib"),
        .headerSearchPath("../IosMath/render/internal"),
      ]
    ),
  ]
)
