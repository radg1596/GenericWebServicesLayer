// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GenericNetworkingLayer",
    platforms: [.iOS(.v15),
                .watchOS(.v10)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GenericNetworkingLayer",
            targets: ["GenericNetworkingLayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.4.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GenericNetworkingLayer",
            dependencies: ["Alamofire"]),
        .testTarget(
            name: "GenericNetworkingLayerTests",
            dependencies: ["GenericNetworkingLayer", "Alamofire"]),
    ]
)
