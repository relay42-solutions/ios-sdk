// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Relay42TrackingSwiftSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Relay42TrackingSwiftSDK",
            targets: ["SwiftRelay42SDK"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftRelay42SDK",
            path: "Sources/SwiftRelay42SDK"
        ),
        .testTarget(
            name: "Relay42TrackingSwiftSDKTests",
            dependencies: ["SwiftRelay42SDK"],
            path: "Tests/SwiftRelay42SDKTests"
        ),
    ]
)