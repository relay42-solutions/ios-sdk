# Relay42SwiftSDK

A lightweight Swift SDK for sending engagement events from iOS apps to Relay42 via your API gateway.

- Configure once at app startup
- Send engagement events with a consistent JSON payload

---

## Installation

### Swift Package Manager (Xcode)

1. In Xcode, go to **File ▸ Add Packages…**
2. Enter the repository URL: https://github.com/relay42-solutions/ios-sdk.git
3. Select the **main** branch or a tagged version (e.g. `0.1.0`)
4. Add the **Relay42SwiftSDK** library to your app target.

### Swift Package (Package.swift)

If you manage dependencies manually via `Package.swift`:

```swift
dependencies: [
 .package(
     url: "https://github.com/relay42-solutions/ios-sdk.git",
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

🚀 Usage: Sending Engagements, Facts & Mappings

The Relay42 Pixel Swift SDK provides a simple native interface for firing the same pixel-based tracking calls used on websites (t.svtrd.com).
All events are sent as GET requests with the correct Relay42 parameters and automatic cachebusters.

After calling:

Relay42Pixel.shared.configure(config)

…you can send the following events:

📍 Engagements

Use Engagements to track actions such as product views, button clicks, page views, or any behavioral event.

Example

Relay42Pixel.shared.trackEngagement(
    uuid: "522a5323-b3ff-44df-8624-a22edf8d2800",
    type: "ProductView",
    properties: [
        "productId": "1630",
        "categoryId": "249"
    ]
) { result in
    switch result {
    case .success:
        print("Engagement sent successfully")
    case .failure(let error):
        print("Engagement failed:", error)
    }
}

What the SDK generates

https://t.svtrd.com/t-<siteId>?
    i=<uuid>
    &e=true
    &et=ProductView
    &cup=productId%3A1630
    &cup=categoryId%3A249
    &cb=<timestamp>

Notes
	•	et = engagement type
	•	Each properties item becomes a cup=key:value parameter
	•	Maximum of 32 properties (Relay42 limit)
	•	cb is a unique timestamp to prevent caching

📍 Facts

Use Facts to store longer-lived profile attributes — e.g. last viewed products, preferences, or attributes that should persist.

Example

Relay42Pixel.shared.trackFact(
    uuid: "30154a8e-67ec-4437-8fde-d673c93090b5",
    type: "LastProduct",
    ttlSeconds: 157784630,   // ~5 years
    properties: [
        "LastProduct": "1630",
        "SecondProduct": "1631"
    ]
) { result in
    switch result {
    case .success:
        print("Fact sent successfully")
    case .failure(let error):
        print("Fact failed:", error)
    }
}

What the SDK generates

https://t.svtrd.com/t-<siteId>?
    i=<uuid>
    &f=true
    &ft=LastProduct
    &fttl=<ttlSeconds>
    &cup=LastProduct%3A1630
    &cup=SecondProduct%3A1631
    &cb=<timestamp>

Notes
	•	ft = fact type
	•	fttl = fact time-to-live in seconds
	•	cup parameters encode your properties
	•	Facts allow building persistent profile traits within Relay42

⸻

📍 Mappings (ID Sync)

Use Mappings to associate your own identifiers (e.g. CRM ID, loyalty ID) with Relay42 profiles.
This is typically used for:
	•	Logged-in users
	•	Offline-to-online identity resolution
	•	Cross-device linking

Example

Relay42Pixel.shared.syncMapping(
    uuid: "30154a8e-67ec-4437-8fde-d673c93090b5",
    profileId: "123456789",
    partnerId: "2001",     // optional if set in config
    merge: true
) { result in
    switch result {
    case .success:
        print("Mapping sent successfully")
    case .failure(let error):
        print("Mapping failed:", error)
    }
}

What the SDK generates

https://t.svtrd.com/syncResponse?
    ca_site=<siteId>
    &ca_partner=2001
    &ca_cookie=<uuid>
    &ca_read=pid
    &pid=123456789
    &ca_merge=1
    &cb=<timestamp>

🔎 Summary of When to Use Each Call

DK Method                 Purpose                        Example Use Cases
trackEngagement           Behavioral events              Product view, page view, button click, add-to-cart
trackFact                 Persistent profile attributes  Last viewed product, gender, preferences, segmentation
syncMapping               Identity resolution            Link CRM ID, loyalty ID, email hash, app user ID

🧪 Common Testing Workflow
	1.	Generate a UUID (or reuse the same one)
	2.	Fire an Engagement → check in pixel debugger / relay logs
	3.	Fire a Fact → confirm profile fields update
	4.	Fire a Mapping → confirm identity resolution works

