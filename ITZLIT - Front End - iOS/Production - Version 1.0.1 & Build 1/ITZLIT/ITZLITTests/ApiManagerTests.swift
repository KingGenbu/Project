//
//  ApiManagerTests.swift
//  ITZLITTests
//
//  Unit tests for ApiManager networking layer.
//
//  Because ApiManager uses Alamofire directly (without a protocol seam) we stub
//  at the URLProtocol level so that Alamofire's session picks up our fake
//  responses without any production code changes.
//

import XCTest
@testable import ITZLIT

// MARK: - URLProtocol stub

/// A minimal URLProtocol subclass that returns a canned HTTP response.
final class StubURLProtocol: URLProtocol {

    /// Install a handler before each test; tear it down after.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError:
                NSError(domain: "StubURLProtocol", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No handler installed"]))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private func makeJSONResponse(url: URL, statusCode: Int, body: [String: Any]) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(url: url, statusCode: statusCode,
                                   httpVersion: nil, headerFields: nil)!
    let data = try! JSONSerialization.data(withJSONObject: body)
    return (response, data)
}

// MARK: - Test suite

class ApiManagerTests: XCTestCase {

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Singleton

    func testInstanceIsSingleton() {
        let a = ApiManager.Instance
        let b = ApiManager.Instance
        XCTAssertTrue(a === b, "ApiManager.Instance must always return the same object")
    }

    // MARK: - x-auth-token header injection

    /// Verifies that authenticated requests carry the x-auth-token header whose
    /// value is set via setToken().  We inspect the outgoing URLRequest captured
    /// by StubURLProtocol.
    func testAuthenticatedGetRequestInjectsAuthToken() {
        let expectation = self.expectation(description: "request received by stub")
        var capturedRequest: URLRequest?

        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            expectation.fulfill()
            let url = request.url ?? URL(string: "http://localhost")!
            return makeJSONResponse(url: url, statusCode: 200, body: ["status": true])
        }

        ApiManager.Instance.setToken(token: "test-jwt-token-abc")
        // sendHttpGetWithHeader fires an authenticated GET request
        ApiManager.Instance.sendHttpGetWithHeader(
            url: "http://localhost/test",
            params: nil,
            onCompletion: { _, _, _ in }
        )

        waitForExpectations(timeout: 2)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "x-auth-token"),
                       "test-jwt-token-abc",
                       "Authenticated GET must include x-auth-token header")
    }

    // MARK: - GET without header

    func testGetWithoutHeaderSucceeds() {
        let expectation = self.expectation(description: "completion called")

        StubURLProtocol.requestHandler = { request in
            let url = request.url ?? URL(string: "http://localhost")!
            return makeJSONResponse(url: url, statusCode: 200, body: ["key": "value"])
        }

        ApiManager.Instance.sendHttpGetWithoutHeader(
            url: "http://localhost/public",
            params: nil
        ) { json, error, _ in
            XCTAssertNil(error)
            XCTAssertEqual(json["key"].string, "value")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    // MARK: - POST without header

    func testPostWithoutHeaderSucceeds() {
        let expectation = self.expectation(description: "completion called")

        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            let url = request.url ?? URL(string: "http://localhost")!
            return makeJSONResponse(url: url, statusCode: 200, body: ["created": true])
        }

        ApiManager.Instance.httpPostRequestWithoutHeader(
            url: "http://localhost/login",
            params: ["email": "a@b.com", "password": "secret"]
        ) { json, error, _ in
            XCTAssertNil(error)
            XCTAssertTrue(json["created"].boolValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    // MARK: - POST with header

    func testAuthenticatedPostInjectsToken() {
        let expectation = self.expectation(description: "request captured")
        var capturedRequest: URLRequest?

        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            expectation.fulfill()
            let url = request.url ?? URL(string: "http://localhost")!
            return makeJSONResponse(url: url, statusCode: 200, body: [:])
        }

        ApiManager.Instance.setToken(token: "my-secure-token")
        ApiManager.Instance.httpPostRequestWithHeader(
            url: "http://localhost/protected",
            params: ["key": "val"]
        ) { _, _, _ in }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "x-auth-token"),
                       "my-secure-token")
    }

    // MARK: - Server error propagated

    func testGetWithHeaderPropagatesServerError() {
        let expectation = self.expectation(description: "error callback called")

        StubURLProtocol.requestHandler = { request in
            let url = request.url ?? URL(string: "http://localhost")!
            return makeJSONResponse(url: url, statusCode: 500, body: ["error": "Internal"])
        }

        ApiManager.Instance.sendHttpGetWithHeader(
            url: "http://localhost/boom",
            params: nil
        ) { _, error, response in
            let httpResponse = response as? HTTPURLResponse
            XCTAssertEqual(httpResponse?.statusCode, 500)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    // MARK: - setToken

    func testSetTokenIsReflectedInSubsequentRequests() {
        var firstToken: String?
        var secondToken: String?

        let exp1 = expectation(description: "first request")
        StubURLProtocol.requestHandler = { req in
            firstToken = req.value(forHTTPHeaderField: "x-auth-token")
            exp1.fulfill()
            return makeJSONResponse(url: req.url!, statusCode: 200, body: [:])
        }
        ApiManager.Instance.setToken(token: "token-one")
        ApiManager.Instance.sendHttpGetWithHeader(url: "http://localhost/a", params: nil, onCompletion: { _, _, _ in })
        waitForExpectations(timeout: 2)

        let exp2 = expectation(description: "second request")
        StubURLProtocol.requestHandler = { req in
            secondToken = req.value(forHTTPHeaderField: "x-auth-token")
            exp2.fulfill()
            return makeJSONResponse(url: req.url!, statusCode: 200, body: [:])
        }
        ApiManager.Instance.setToken(token: "token-two")
        ApiManager.Instance.sendHttpGetWithHeader(url: "http://localhost/b", params: nil, onCompletion: { _, _, _ in })
        waitForExpectations(timeout: 2)

        XCTAssertEqual(firstToken, "token-one")
        XCTAssertEqual(secondToken, "token-two")
    }
}
