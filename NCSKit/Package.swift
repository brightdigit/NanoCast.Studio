// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NCSKit",
  platforms: [.iOS(.v14), .macOS(.v11), .watchOS(.v7)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NCSKit",
            targets: ["NCSKit"]),
      .executable(name: "ncstudio", targets: ["ncstudio"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
      .package(url: "https://github.com/mxcl/PromiseKit", from: "7.0.0-alpha3"),
      .package(name: "AWSSDKSwift", url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "4.0.0"),
      .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.1")),
      .package(url: "https://github.com/JohnEstropia/CoreStore.git", .branch("newDemo"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NCSKit",
            dependencies: [
              "CryptoSwift",
              "CoreStore",
              .product(name: "S3", package: "AWSSDKSwift")]),
      .target(name: "ncstudio",
              dependencies: ["NCSKit","PromiseKit"]),
        .testTarget(
            name: "NCSKitTests",
            dependencies: ["NCSKit"]),
    ]
)
