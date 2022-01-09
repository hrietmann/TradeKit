// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TradeKit",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v15),
        .macOS(SupportedPlatform.MacOSVersion.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "TradeKit", targets: ["TradeKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0"),
        .package(url: "https://github.com/hrietmann/CodableKit.git", branch: "main"),
        
        // WebSocket client library built on SwiftNIO
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.0.0")
        
//        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0")
//        .package(url: "https://github.com/hrietmann/StreamKit.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TradeKit",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
                .product(name: "CodableKit", package: "CodableKit"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
//                .product(name: "Starscream", package: "Starscream"),
//                .product(name: "StreamKit", package: "StreamKit")
            ]
        ),
        .testTarget(
            name: "TradeKitTests",
            dependencies: ["TradeKit"]
        ),
    ]
)
