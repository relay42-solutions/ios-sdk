import Testing
import Foundation
@testable import SwiftRelay42SDK

// MARK: - Mock URLSession

final class MockURLSession: URLSession, @unchecked Sendable {
    var lastRequest: URLRequest?
    var mockResponse: HTTPURLResponse?
    var mockData: Data?
    var mockError: Error?

    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        lastRequest = request
        return MockURLSessionDataTask {
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
    }
}

final class MockURLSessionDataTask: URLSessionDataTask, @unchecked Sendable {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
        super.init()
    }

    override func resume() {
        closure()
    }
}

// MARK: - Configuration Tests

@Suite("Relay42Pixel Configuration Tests")
struct ConfigurationTests {

    @Test("Config initializes with correct values")
    func testConfigInitialization() {
        let config = Relay42PixelConfig(
            siteId: "1234",
            defaultPartnerId: "2001",
            baseURL: URL(string: "https://t.svtrd.com")!
        )

        #expect(config.siteId == "1234")
        #expect(config.defaultPartnerId == "2001")
        #expect(config.baseURL.absoluteString == "https://t.svtrd.com")
    }

    @Test("Config uses default base URL")
    func testDefaultBaseURL() {
        let config = Relay42PixelConfig(siteId: "1234")
        #expect(config.baseURL.absoluteString == "https://t.svtrd.com")
    }
}

// MARK: - Engagement Tests

@Suite("Relay42Pixel Engagement Tests")
struct EngagementTests {

    @Test("Engagement request generates correct URL")
    func testEngagementURL() async {
        let mockSession = MockURLSession()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://t.svtrd.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let pixel = Relay42Pixel(session: mockSession)
        let config = Relay42PixelConfig(siteId: "1234")
        pixel.configure(config)

        await withCheckedContinuation { continuation in
            pixel.trackEngagement(
                uuid: "test-uuid-123",
                type: "ProductView",
                properties: ["productId": "1630", "categoryId": "249"]
            ) { _ in
                continuation.resume()
            }
        }

        guard let request = mockSession.lastRequest,
              let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Request URL is nil")
            return
        }

        #expect(components.path == "/t-1234")
        #expect(request.httpMethod == "GET")

        let queryItems = components.queryItems ?? []
        #expect(queryItems.contains(where: { $0.name == "i" && $0.value == "test-uuid-123" }))
        #expect(queryItems.contains(where: { $0.name == "e" && $0.value == "true" }))
        #expect(queryItems.contains(where: { $0.name == "et" && $0.value == "ProductView" }))
        #expect(queryItems.contains(where: { $0.name == "cup" && $0.value == "productId:1630" }))
        #expect(queryItems.contains(where: { $0.name == "cup" && $0.value == "categoryId:249" }))
        #expect(queryItems.contains(where: { $0.name == "cb" }))
    }

    @Test("Engagement returns error when not configured")
    func testEngagementNotConfigured() async {
        let pixel = Relay42Pixel()

        let result = await withCheckedContinuation { continuation in
            pixel.trackEngagement(uuid: "test", type: "test") { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error is Relay42PixelError)
            if let pixelError = error as? Relay42PixelError {
                #expect(pixelError == .notConfigured)
            }
        }
    }

    @Test("Engagement limits properties to 32")
    func testEngagementPropertyLimit() async {
        let mockSession = MockURLSession()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://t.svtrd.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let pixel = Relay42Pixel(session: mockSession)
        let config = Relay42PixelConfig(siteId: "1234")
        pixel.configure(config)

        var properties: [String: String] = [:]
        for i in 1...50 {
            properties["prop\(i)"] = "value\(i)"
        }

        await withCheckedContinuation { continuation in
            pixel.trackEngagement(uuid: "test", type: "test", properties: properties) { _ in
                continuation.resume()
            }
        }

        guard let url = mockSession.lastRequest?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Request URL is nil")
            return
        }

        let cupCount = components.queryItems?.filter { $0.name == "cup" }.count ?? 0
        #expect(cupCount == 32)
    }
}

// MARK: - Fact Tests

@Suite("Relay42Pixel Fact Tests")
struct FactTests {

    @Test("Fact request generates correct URL")
    func testFactURL() async {
        let mockSession = MockURLSession()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://t.svtrd.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let pixel = Relay42Pixel(session: mockSession)
        let config = Relay42PixelConfig(siteId: "1234")
        pixel.configure(config)

        await withCheckedContinuation { continuation in
            pixel.trackFact(
                uuid: "test-uuid-456",
                type: "LastProduct",
                ttlSeconds: 157784630,
                properties: ["LastProduct": "1630", "SecondProduct": "1631"]
            ) { _ in
                continuation.resume()
            }
        }

        guard let request = mockSession.lastRequest,
              let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Request URL is nil")
            return
        }

        #expect(components.path == "/t-1234")

        let queryItems = components.queryItems ?? []
        #expect(queryItems.contains(where: { $0.name == "i" && $0.value == "test-uuid-456" }))
        #expect(queryItems.contains(where: { $0.name == "f" && $0.value == "true" }))
        #expect(queryItems.contains(where: { $0.name == "ft" && $0.value == "LastProduct" }))
        #expect(queryItems.contains(where: { $0.name == "fttl" && $0.value == "157784630" }))
        #expect(queryItems.contains(where: { $0.name == "cup" && $0.value == "LastProduct:1630" }))
    }
}

// MARK: - Mapping Tests

@Suite("Relay42Pixel Mapping Tests")
struct MappingTests {

    @Test("Mapping request generates correct URL")
    func testMappingURL() async {
        let mockSession = MockURLSession()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://t.svtrd.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let pixel = Relay42Pixel(session: mockSession)
        let config = Relay42PixelConfig(siteId: "1234", defaultPartnerId: "2001")
        pixel.configure(config)

        await withCheckedContinuation { continuation in
            pixel.syncMapping(
                uuid: "test-uuid-789",
                profileId: "123456789",
                merge: true
            ) { _ in
                continuation.resume()
            }
        }

        guard let request = mockSession.lastRequest,
              let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Request URL is nil")
            return
        }

        #expect(components.path == "/syncResponse")

        let queryItems = components.queryItems ?? []
        #expect(queryItems.contains(where: { $0.name == "ca_site" && $0.value == "1234" }))
        #expect(queryItems.contains(where: { $0.name == "ca_partner" && $0.value == "2001" }))
        #expect(queryItems.contains(where: { $0.name == "ca_cookie" && $0.value == "test-uuid-789" }))
        #expect(queryItems.contains(where: { $0.name == "pid" && $0.value == "123456789" }))
        #expect(queryItems.contains(where: { $0.name == "ca_merge" && $0.value == "1" }))
        #expect(queryItems.contains(where: { $0.name == "ca_read" && $0.value == "pid" }))
    }

    @Test("Mapping uses override partner ID")
    func testMappingOverridePartnerId() async {
        let mockSession = MockURLSession()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://t.svtrd.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let pixel = Relay42Pixel(session: mockSession)
        let config = Relay42PixelConfig(siteId: "1234", defaultPartnerId: "2001")
        pixel.configure(config)

        await withCheckedContinuation { continuation in
            pixel.syncMapping(
                uuid: "test-uuid",
                profileId: "123",
                partnerId: "3000"
            ) { _ in
                continuation.resume()
            }
        }

        guard let url = mockSession.lastRequest?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Request URL is nil")
            return
        }

        let queryItems = components.queryItems ?? []
        #expect(queryItems.contains(where: { $0.name == "ca_partner" && $0.value == "3000" }))
    }

    @Test("Mapping returns error when no partner ID available")
    func testMappingNoPartnerId() async {
        let pixel = Relay42Pixel()
        let config = Relay42PixelConfig(siteId: "1234")
        pixel.configure(config)

        let result = await withCheckedContinuation { continuation in
            pixel.syncMapping(uuid: "test", profileId: "123") { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error is Relay42PixelError)
        }
    }
}

// MARK: - HTTP Status Tests

@Suite("Relay42Pixel HTTP Response Tests")
struct HTTPResponseTests {

    @Test("Success on 2xx status codes")
    func testSuccessStatusCodes() async {
        for statusCode in [200, 201, 204] {
            let mockSession = MockURLSession()
            mockSession.mockResponse = HTTPURLResponse(
                url: URL(string: "https://t.svtrd.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )

            let pixel = Relay42Pixel(session: mockSession)
            let config = Relay42PixelConfig(siteId: "1234")
            pixel.configure(config)

            let result = await withCheckedContinuation { continuation in
                pixel.trackEngagement(uuid: "test", type: "test") { result in
                    continuation.resume(returning: result)
                }
            }

            switch result {
            case .success:
                break // Expected
            case .failure:
                Issue.record("Expected success for status code \(statusCode)")
            }
        }
    }

    @Test("Failure on non-2xx status codes")
    func testErrorStatusCodes() async {
        for statusCode in [400, 404, 500] {
            let mockSession = MockURLSession()
            mockSession.mockResponse = HTTPURLResponse(
                url: URL(string: "https://t.svtrd.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )

            let pixel = Relay42Pixel(session: mockSession)
            let config = Relay42PixelConfig(siteId: "1234")
            pixel.configure(config)

            let result = await withCheckedContinuation { continuation in
                pixel.trackEngagement(uuid: "test", type: "test") { result in
                    continuation.resume(returning: result)
                }
            }

            switch result {
            case .success:
                Issue.record("Expected failure for status code \(statusCode)")
            case .failure(let error):
                if let pixelError = error as? Relay42PixelError,
                   case .httpStatus(let code) = pixelError {
                    #expect(code == statusCode)
                }
            }
        }
    }
}
