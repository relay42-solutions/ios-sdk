// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Relay42TrackingSwiftSDK",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "Relay42TrackingSwiftSDK",
            targets: ["Relay42TrackingSwiftSDK"]
        ),
    ],
    targets: [
        .target(
            name: "Relay42TrackingSwiftSDK",
            path: "Sources"
        ),
        .testTarget(
            name: "Relay42TrackingSwiftSDKTests",
            dependencies: ["Relay42TrackingSwiftSDK"],
            path: "Tests"
        ),
    ]
)