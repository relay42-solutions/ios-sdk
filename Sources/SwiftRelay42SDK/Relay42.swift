import Foundation

// MARK: - Configuration

/// Configuration for the Relay42 pixel SDK.
public struct Relay42PixelConfig {
    /// Your site id used in t-<siteId>, e.g. "1232" -> /t-1232
    public let siteId: String

    /// Default partner id for mappings (ca_partner). Can be overridden per call.
    public let defaultPartnerId: String?

    /// Base host for the pixel endpoints, e.g. https://t.svtrd.com
    public let baseURL: URL

    /// Create a new config.
    public init(
        siteId: String,
        defaultPartnerId: String? = nil,
        baseURL: URL = URL(string: "https://t.svtrd.com")!
    ) {
        self.siteId = siteId
        self.defaultPartnerId = defaultPartnerId
        self.baseURL = baseURL
    }
}

// MARK: - Errors

public enum Relay42PixelError: Error {
    case notConfigured
    case invalidURL
    case httpStatus(Int)
    case unknown
}

// MARK: - SDK

/// Main entry point for sending engagements, facts and mappings using pixel endpoints.
public final class Relay42Pixel {

    public static let shared = Relay42Pixel()

    private var config: Relay42PixelConfig?
    private let session: URLSession

    // MARK: - Init

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Configuration

    /// Configure the SDK. Call once at app startup.
    public func configure(_ config: Relay42PixelConfig) {
        self.config = config
    }

    // MARK: - Public API

    // MARK: Engagements

    /// Send an engagement event.
    ///
    /// Generates a URL like:
    /// https://t.svtrd.com/t-<siteId>?i=<uuid>&e=true&et=<type>&cup=key%3Avalue...&cb=<cachebuster>
    ///
    /// - Parameters:
    ///   - uuid: The UUID for the profile (`i` parameter).
    ///   - type: The engagement type (`et` parameter).
    ///   - properties: Additional properties for `cup` parameters (max 32).
    ///   - completion: Optional callback with result.
    public func trackEngagement(
        uuid: String,
        type: String,
        properties: [String: String] = [:],
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard let config = config else {
            completion?(.failure(Relay42PixelError.notConfigured))
            return
        }

        let cachebuster = Self.cachebuster()

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "i", value: uuid),
            URLQueryItem(name: "e", value: "true"),
            URLQueryItem(name: "et", value: type),
            URLQueryItem(name: "cb", value: cachebuster)
        ]

        // Each property -> cup=key:value
        for (key, value) in properties.prefix(32) {
            let cupValue = "\(key):\(value)"     // ":" will be percent-encoded
            queryItems.append(URLQueryItem(name: "cup", value: cupValue))
        }

        sendPixelRequest(
            path: "/t-\(config.siteId)",
            queryItems: queryItems,
            completion: completion
        )
    }

    // MARK: Facts

    /// Send a fact event.
    ///
    /// Generates a URL like:
    /// https://t.svtrd.com/t-<siteId>?i=<uuid>&f=true&ft=<type>&fttl=<ttl>&cup=...&cb=<cachebuster>
    ///
    /// - Parameters:
    ///   - uuid: The UUID for the profile (`i` parameter).
    ///   - type: The fact type (`ft` parameter).
    ///   - ttlSeconds: Time to live in seconds (`fttl` parameter).
    ///   - properties: Additional properties as `cup` parameters (max 32).
    ///   - completion: Optional callback with result.
    public func trackFact(
        uuid: String,
        type: String,
        ttlSeconds: Int,
        properties: [String: String] = [:],
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard let config = config else {
            completion?(.failure(Relay42PixelError.notConfigured))
            return
        }

        let cachebuster = Self.cachebuster()

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "i", value: uuid),
            URLQueryItem(name: "f", value: "true"),
            URLQueryItem(name: "ft", value: type),
            URLQueryItem(name: "fttl", value: String(ttlSeconds)),
            URLQueryItem(name: "cb", value: cachebuster)
        ]

        for (key, value) in properties.prefix(32) {
            let cupValue = "\(key):\(value)"
            queryItems.append(URLQueryItem(name: "cup", value: cupValue))
        }

        sendPixelRequest(
            path: "/t-\(config.siteId)",
            queryItems: queryItems,
            completion: completion
        )
    }

    // MARK: Mappings

    /// Send a mapping (syncResponse) request.
    ///
    /// Generates a URL like:
    /// https://t.svtrd.com/syncResponse?ca_site=<siteId>&ca_partner=<partnerId>&ca_cookie=<uuid>&pid=<profileId>&cb=<cachebuster>&ca_merge=<0|1>
    ///
    /// - Parameters:
    ///   - uuid: The UUID / cookie (`ca_cookie`).
    ///   - profileId: The ID to map to this profile (`pid`).
    ///   - partnerId: Optional partner type; if nil, uses `defaultPartnerId` from config.
    ///   - merge: Whether to merge into existing profiles with this identifier (`ca_merge` 0/1).
    ///   - completion: Optional callback with result.
    public func syncMapping(
        uuid: String,
        profileId: String,
        partnerId: String? = nil,
        merge: Bool = true,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard let config = config else {
            completion?(.failure(Relay42PixelError.notConfigured))
            return
        }

        guard let actualPartnerId = partnerId ?? config.defaultPartnerId else {
            // Partner id is required for this call; treat as misconfiguration.
            completion?(.failure(Relay42PixelError.invalidURL))
            return
        }

        let cachebuster = Self.cachebuster()

        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "ca_site", value: config.siteId),
            URLQueryItem(name: "ca_partner", value: actualPartnerId),
            URLQueryItem(name: "ca_cookie", value: uuid),
            URLQueryItem(name: "pid", value: profileId),
            URLQueryItem(name: "cb", value: cachebuster),
            URLQueryItem(name: "ca_merge", value: merge ? "1" : "0")
        ]

        sendPixelRequest(
            path: "/syncResponse",
            queryItems: queryItems,
            completion: completion
        )
    }

    // MARK: - Internal helpers

    private static func cachebuster() -> String {
        // Use current time in milliseconds since epoch
        let ms = Int(Date().timeIntervalSince1970 * 1000)
        return String(ms)
    }

    private func sendPixelRequest(
        path: String,
        queryItems: [URLQueryItem],
        completion: ((Result<Void, Error>) -> Void)?
    ) {
        guard let config = config else {
            completion?(.failure(Relay42PixelError.notConfigured))
            return
        }

        var components = URLComponents(
            url: config.baseURL,
            resolvingAgainstBaseURL: false
        )
        components?.path = path
        components?.queryItems = queryItems

        guard let url = components?.url else {
            completion?(.failure(Relay42PixelError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion?(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion?(.failure(Relay42PixelError.unknown))
                return
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                completion?(.failure(Relay42PixelError.httpStatus(httpResponse.statusCode)))
                return
            }

            completion?(.success(()))
        }

        task.resume()
    }
}