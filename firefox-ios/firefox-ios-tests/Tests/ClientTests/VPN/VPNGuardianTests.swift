// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import TestKit
import XCTest
@testable import Client

@MainActor
final class VPNGuardianTests: XCTestCase {
    private var session: URLSession!

    override func setUp() async throws {
        try await super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() async throws {
        URLProtocolStub.removeStub()
        session = nil
        try await super.tearDown()
    }

    // MARK: - getPass

    func testGetPass_withValidToken_returnsPassWithClaims() async throws {
        let token = makeJWT(nbf: 1_700_000_000, exp: 1_700_003_600)
        stubResponse(statusCode: 200, body: tokenBody(token))
        let subject = createSubject()

        let pass = try await subject.getPass()

        XCTAssertEqual(pass.bearerToken, token)
        XCTAssertEqual(pass.notBefore, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(pass.expiresAt, Date(timeIntervalSince1970: 1_700_003_600))
        XCTAssertNil(pass.usage)
    }

    func testGetPass_sendsRequestToTokenEndpointWithAuthHeaders() async throws {
        let mockURLProtocol = MockURLProtocol()
        defer {
            mockURLProtocol.response = nil
            mockURLProtocol.data = nil
        }
        mockURLProtocol.data = tokenBody(makeJWT(nbf: 0, exp: 1))
        var capturedRequest: URLRequest?
        mockURLProtocol.response = { _, request in capturedRequest = request }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let subject = createSubject(
            authHeaders: ["secret": "shh"],
            configuration: .prod,
            session: URLSession(configuration: configuration)
        )

        _ = try await subject.getPass()

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.url, URL(string: "https://vpn.mozilla.com/api/v1/foxfooding/token"))
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "secret"), "shh")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testGetPass_withNon200Status_throwsHTTPError() async {
        stubResponse(statusCode: 403, body: Data())
        let subject = createSubject()

        do {
            _ = try await subject.getPass()
            XCTFail("Expected getPass to throw")
        } catch VPNGuardian.GuardianError.http(let status) {
            XCTAssertEqual(status, 403)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetPass_withMalformedBody_throwsBodyInvalid() async {
        stubResponse(statusCode: 200, body: Data("not json".utf8))

        await assertGetPassThrowsBodyInvalid()
    }

    func testGetPass_withTokenMissingSegments_throwsBodyInvalid() async {
        stubResponse(statusCode: 200, body: tokenBody("header.payload"))

        await assertGetPassThrowsBodyInvalid()
    }

    func testGetPass_withPayloadMissingClaims_throwsBodyInvalid() async {
        let payload = base64URLEncode(Data("{\"sub\":\"user\"}".utf8))
        stubResponse(statusCode: 200, body: tokenBody("header.\(payload).signature"))

        await assertGetPassThrowsBodyInvalid()
    }

    func testGetPass_withPayloadNotBase64_throwsBodyInvalid() async {
        stubResponse(statusCode: 200, body: tokenBody("header.!!!.signature"))

        await assertGetPassThrowsBodyInvalid()
    }

    // MARK: - passRotation

    func testPassRotation_nearExpiry_emitsRotatedPass() async throws {
        let rotatedToken = makeJWT(nbf: 0, exp: Date().addingTimeInterval(3600).timeIntervalSince1970)
        stubResponse(statusCode: 200, body: tokenBody(rotatedToken))
        let subject = createSubject()
        let initial = makePass(expiresAt: Date())

        var iterator = subject.passRotation(after: initial).makeAsyncIterator()
        let rotated = await iterator.next()

        XCTAssertEqual(rotated?.bearerToken, rotatedToken)
    }

    func testPassRotation_onTerminalFailure_finishesStream() async {
        stubResponse(statusCode: 401, body: Data())
        let subject = createSubject()
        let initial = makePass(expiresAt: Date())

        var emitted: [VPNGuardian.ProxyPass] = []
        for await pass in subject.passRotation(after: initial) {
            emitted.append(pass)
        }

        XCTAssertTrue(emitted.isEmpty)
    }

    // MARK: - Helpers

    private func createSubject(
        authHeaders: [String: String] = [:],
        configuration: VPNGuardian.Configuration = .staging,
        session: URLSession? = nil
    ) -> VPNGuardian {
        let subject = VPNGuardian(
            authHeaders: authHeaders,
            configuration: configuration,
            session: session ?? self.session,
            logger: MockLogger()
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func assertGetPassThrowsBodyInvalid(file: StaticString = #filePath, line: UInt = #line) async {
        let subject = createSubject()
        do {
            _ = try await subject.getPass()
            XCTFail("Expected getPass to throw", file: file, line: line)
        } catch VPNGuardian.GuardianError.bodyInvalid {
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

    private func stubResponse(statusCode: Int, body: Data) {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        URLProtocolStub.stub(data: body, response: response, error: nil)
    }

    private func makePass(expiresAt: Date) -> VPNGuardian.ProxyPass {
        return VPNGuardian.ProxyPass(bearerToken: "initial", notBefore: Date(), expiresAt: expiresAt, usage: nil)
    }

    private func tokenBody(_ token: String) -> Data {
        return Data("{\"token\":\"\(token)\"}".utf8)
    }

    /// Builds an unsigned JWT whose payload is base64url-encoded without padding, as Guardian
    /// returns it.
    private func makeJWT(nbf: TimeInterval, exp: TimeInterval) -> String {
        let payload = Data("{\"nbf\":\(nbf),\"exp\":\(exp)}".utf8)
        return "header.\(base64URLEncode(payload)).signature"
    }

    private func base64URLEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
