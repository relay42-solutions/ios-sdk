# Testing Guide for Relay42 iOS SDK

## Prerequisites

Before you can build and test the SDK, ensure Xcode license agreement is accepted:

```bash
sudo xcodebuild -license
```

## Building the SDK

Build the Swift package to verify compilation:

```bash
swift build
```

## Running Tests

### Run all tests
```bash
swift test
```

### Run tests with verbose output
```bash
swift test --verbose
```

### Run a specific test suite
```bash
swift test --filter ConfigurationTests
swift test --filter EngagementTests
swift test --filter FactTests
swift test --filter MappingTests
```

## Test Coverage

The test suite includes:

### 1. Configuration Tests
- Config initialization with custom values
- Default base URL handling

### 2. Engagement Tests
- URL generation with correct query parameters
- Property encoding (key:value format)
- Property limit enforcement (max 32)
- Error handling when not configured
- HTTP method verification

### 3. Fact Tests
- URL generation with fact-specific parameters
- TTL (time-to-live) parameter encoding
- Property handling

### 4. Mapping Tests
- Sync endpoint URL generation
- Default partner ID usage
- Partner ID override capability
- Error handling when partner ID is missing

### 5. HTTP Response Tests
- Success handling for 2xx status codes
- Error handling for 4xx/5xx status codes
- Status code propagation in errors

## Manual Testing

### Using Xcode Playgrounds

Create a new playground and import the SDK:

```swift
import SwiftRelay42SDK

// Configure the SDK
let config = Relay42PixelConfig(
    siteId: "YOUR_SITE_ID",
    defaultPartnerId: "YOUR_PARTNER_ID"
)
Relay42Pixel.shared.configure(config)

// Generate a test UUID
let testUUID = UUID().uuidString

// Test engagement tracking
Relay42Pixel.shared.trackEngagement(
    uuid: testUUID,
    type: "TestEvent",
    properties: ["key": "value"]
) { result in
    switch result {
    case .success:
        print("✅ Engagement sent successfully")
    case .failure(let error):
        print("❌ Error:", error)
    }
}
```

### Using a Test iOS App

1. Create a new iOS app in Xcode
2. Add the SDK as a local package dependency:
   - File → Add Package Dependencies
   - Click "Add Local..."
   - Select this repository folder
3. Import and use the SDK in your app

### Network Traffic Inspection

Use a network debugging tool to verify requests:

**Option 1: Charles Proxy**
- Install Charles Proxy
- Configure iOS Simulator to use Charles
- Watch for requests to `t.svtrd.com`

**Option 2: Print URLs in Code**
Temporarily add logging to [Relay42.swift:233](Sources/SwiftRelay42SDK/Relay42.swift#L233):

```swift
guard let url = components?.url else {
    completion?(.failure(Relay42PixelError.invalidURL))
    return
}

print("📤 Relay42 Request: \(url.absoluteString)")
```

## Expected Request Formats

### Engagement Request
```
https://t.svtrd.com/t-<siteId>?
    i=<uuid>
    &e=true
    &et=<type>
    &cup=<key>%3A<value>
    &cb=<timestamp>
```

### Fact Request
```
https://t.svtrd.com/t-<siteId>?
    i=<uuid>
    &f=true
    &ft=<type>
    &fttl=<ttlSeconds>
    &cup=<key>%3A<value>
    &cb=<timestamp>
```

### Mapping Request
```
https://t.svtrd.com/syncResponse?
    ca_site=<siteId>
    &ca_partner=<partnerId>
    &ca_cookie=<uuid>
    &ca_read=pid
    &pid=<profileId>
    &ca_merge=<0|1>
    &cb=<timestamp>
```

**Parameter Meanings:**
- `ca_site`: Your Relay42 site ID
- `ca_partner`: Partner type ID (e.g., 2001 for CRM, identifies the source)
- `ca_cookie`: The Relay42 UUID for this user/session
- `ca_read`: Type of ID being synced (always "pid" for profile ID)
- `pid`: The external identifier to map (e.g., CRM ID, hashed email, loyalty ID)
- `ca_merge`: Whether to merge with existing profiles (1=yes, 0=no)
- `cb`: Cachebuster timestamp

## Troubleshooting

### Tests fail with Xcode license error
Run: `sudo xcodebuild -license`

### Tests fail with "module not found"
Clean and rebuild: `swift package clean && swift build`

### Network requests fail
- Check your internet connection
- Verify the base URL is accessible
- Ensure siteId is correct
- Check firewall/proxy settings

### iOS Simulator network issues
- Reset simulator: Device → Erase All Content and Settings
- Check macOS network connectivity
- Disable VPN if active

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: swift build
      - name: Test
        run: swift test
```

## Next Steps

After verifying tests pass:
1. Tag a release version
2. Push to GitHub
3. Distribute via Swift Package Manager
4. Integrate into your iOS app
