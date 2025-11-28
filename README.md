# Relay42SwiftSDK

A lightweight Swift SDK for sending engagement events from iOS apps to Relay42 via your API gateway.

This SDK mirrors the public API of the Relay42 Flutter SDK:

- Configure once at app startup
- Send engagement events with a consistent JSON payload

---

## Installation

### Swift Package Manager (Xcode)

1. In Xcode, go to **File ▸ Add Packages…**
2. Enter the repository URL: https://github.com/relay42-solutions/Relay42SwiftSDK.git
3. Select the **main** branch or a tagged version (e.g. `0.1.0`)
4. Add the **Relay42SwiftSDK** library to your app target.

### Swift Package (Package.swift)

If you manage dependencies manually via `Package.swift`:

```swift
dependencies: [
 .package(
     url: "https://github.com/relay42-solutions/Relay42SwiftSDK.git",
     from: "0.1.0"
 )
],
targets: [
 .target(
     name: "YourApp",
     dependencies: [
         "Relay42SwiftSDK"
     ]
 )
]