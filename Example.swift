import Foundation
import SwiftRelay42SDK

// MARK: - Example Usage

/// Example showing how to integrate Relay42 SDK in your iOS app
class Relay42Example {

    // MARK: - Setup (Call once at app launch)

    static func configureSDK() {
        let config = Relay42PixelConfig(
            siteId: "1234",              // Your Relay42 site ID
            defaultPartnerId: "2001",    // Your partner ID for mappings
            baseURL: URL(string: "https://t.svtrd.com")!
        )

        Relay42Pixel.shared.configure(config)
        print("✅ Relay42 SDK configured")
    }

    // MARK: - Example 1: Track Product View (Engagement)

    static func trackProductView(productId: String, categoryId: String, userId: String) {
        Relay42Pixel.shared.trackEngagement(
            uuid: userId,
            type: "ProductView",
            properties: [
                "productId": productId,
                "categoryId": categoryId,
                "source": "ios_app"
            ]
        ) { result in
            switch result {
            case .success:
                print("✅ Product view tracked")
            case .failure(let error):
                print("❌ Failed to track product view:", error)
            }
        }
    }

    // MARK: - Example 2: Track Button Click (Engagement)

    static func trackButtonClick(buttonName: String, screenName: String, userId: String) {
        Relay42Pixel.shared.trackEngagement(
            uuid: userId,
            type: "ButtonClick",
            properties: [
                "buttonName": buttonName,
                "screenName": screenName,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        ) { result in
            switch result {
            case .success:
                print("✅ Button click tracked")
            case .failure(let error):
                print("❌ Failed to track button click:", error)
            }
        }
    }

    // MARK: - Example 3: Store User Preferences (Fact)

    static func storeUserPreferences(userId: String, preferences: [String: String]) {
        Relay42Pixel.shared.trackFact(
            uuid: userId,
            type: "UserPreferences",
            ttlSeconds: 31536000,  // 1 year
            properties: preferences
        ) { result in
            switch result {
            case .success:
                print("✅ User preferences stored")
            case .failure(let error):
                print("❌ Failed to store preferences:", error)
            }
        }
    }

    // MARK: - Example 4: Track Last Viewed Products (Fact)

    static func trackLastViewedProducts(userId: String, lastProductId: String, secondLastProductId: String) {
        Relay42Pixel.shared.trackFact(
            uuid: userId,
            type: "LastProducts",
            ttlSeconds: 157784630,  // ~5 years
            properties: [
                "LastProduct": lastProductId,
                "SecondProduct": secondLastProductId
            ]
        ) { result in
            switch result {
            case .success:
                print("✅ Last viewed products tracked")
            case .failure(let error):
                print("❌ Failed to track last viewed products:", error)
            }
        }
    }

    // MARK: - Example 5: Sync User Login (Mapping)

    static func syncUserLogin(relay42UUID: String, crmUserId: String) {
        Relay42Pixel.shared.syncMapping(
            uuid: relay42UUID,
            profileId: crmUserId,
            merge: true  // Merge with existing profile
        ) { result in
            switch result {
            case .success:
                print("✅ User identity synced")
            case .failure(let error):
                print("❌ Failed to sync identity:", error)
            }
        }
    }

    // MARK: - Example 6: Sync with Custom Partner ID

    static func syncWithCustomPartner(relay42UUID: String, externalId: String, partnerId: String) {
        Relay42Pixel.shared.syncMapping(
            uuid: relay42UUID,
            profileId: externalId,
            partnerId: partnerId,  // Override default partner ID
            merge: false           // Don't merge, create new mapping
        ) { result in
            switch result {
            case .success:
                print("✅ Custom partner sync completed")
            case .failure(let error):
                print("❌ Failed to sync with custom partner:", error)
            }
        }
    }

    // MARK: - Example 7: E-commerce Flow

    static func ecommerceExample(userId: String) {
        // 1. User views product
        trackProductView(productId: "12345", categoryId: "electronics", userId: userId)

        // 2. User adds to cart
        Relay42Pixel.shared.trackEngagement(
            uuid: userId,
            type: "AddToCart",
            properties: [
                "productId": "12345",
                "quantity": "1",
                "price": "99.99"
            ]
        ) { _ in }

        // 3. Store cart state as a fact
        Relay42Pixel.shared.trackFact(
            uuid: userId,
            type: "CartState",
            ttlSeconds: 86400,  // 24 hours
            properties: [
                "totalItems": "1",
                "totalValue": "99.99"
            ]
        ) { _ in }

        // 4. User completes purchase
        Relay42Pixel.shared.trackEngagement(
            uuid: userId,
            type: "Purchase",
            properties: [
                "orderId": "ORDER-123",
                "totalValue": "99.99",
                "paymentMethod": "credit_card"
            ]
        ) { _ in }

        // 5. If user logs in during checkout, sync identity
        syncUserLogin(relay42UUID: userId, crmUserId: "CRM-456")
    }
}

// MARK: - AppDelegate Integration Example

/*
import UIKit
import SwiftRelay42SDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Configure Relay42 SDK at app launch
        Relay42Example.configureSDK()

        return true
    }
}
*/

// MARK: - SwiftUI App Integration Example

/*
import SwiftUI
import SwiftRelay42SDK

@main
struct MyApp: App {

    init() {
        // Configure Relay42 SDK at app launch
        Relay42Example.configureSDK()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
*/

// MARK: - Usage in View Controllers

/*
import UIKit
import SwiftRelay42SDK

class ProductViewController: UIViewController {

    var productId: String = "12345"
    var userId: String = "user-uuid-here"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Track product view when screen appears
        Relay42Example.trackProductView(
            productId: productId,
            categoryId: "electronics",
            userId: userId
        )
    }

    @IBAction func addToCartTapped(_ sender: UIButton) {
        // Track button click
        Relay42Example.trackButtonClick(
            buttonName: "add_to_cart",
            screenName: "ProductDetail",
            userId: userId
        )

        // Track add to cart event
        Relay42Pixel.shared.trackEngagement(
            uuid: userId,
            type: "AddToCart",
            properties: [
                "productId": productId,
                "quantity": "1"
            ]
        ) { result in
            if case .success = result {
                // Show success message
                self.showAlert(message: "Added to cart!")
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
*/

// MARK: - Helper: Generate or Retrieve User UUID

extension Relay42Example {

    /// Get or create a persistent UUID for this device/user
    static func getUserUUID() -> String {
        let key = "relay42_user_uuid"

        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        let newUUID = UUID().uuidString
        UserDefaults.standard.set(newUUID, forKey: key)
        return newUUID
    }
}
