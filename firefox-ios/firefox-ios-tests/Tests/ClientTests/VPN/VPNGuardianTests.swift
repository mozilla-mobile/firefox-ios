// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import TestKit
import XCTest
@testable import Client
@testable import VPNKit

@MainActor
final class VPNGuardianTests: XCTestCase {
    private var mockTokenProvider: MockVPNTokenProvider!

    override func setUp() async throws {
        try await super.setUp()
        mockTokenProvider = MockVPNTokenProvider()
    }

    override func tearDown() async throws {
        mockTokenProvider = nil
        try await super.tearDown()
    }

    // MARK: - getPass

    func testGetPass_returnsProviderPass() async throws {
        let expected = makePass(expiresAt: Date().addingTimeInterval(3600))
        mockTokenProvider.results = [.success(expected)]
        let subject = createSubject()

        let pass = try await subject.getPass()

        XCTAssertEqual(pass, expected)
        XCTAssertEqual(mockTokenProvider.proxyTokenCalled, 1)
    }

    func testGetPass_whenTokenProviderFails_throwsProviderError() async {
        mockTokenProvider.results = [.failure(AppAttestServiceError.serverError(statusCode: 401, description: ""))]
        let subject = createSubject()

        do {
            _ = try await subject.getPass()
            XCTFail("Expected getPass to throw")
        } catch AppAttestServiceError.serverError(let status, _) {
            XCTAssertEqual(status, 401)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - passRotation

    func testPassRotation_nearExpiry_emitsRotatedPass() async throws {
        let rotatedPass = makePass(token: "rotated", expiresAt: Date().addingTimeInterval(3600))
        mockTokenProvider.results = [.success(rotatedPass)]
        let subject = createSubject()
        let initial = makePass(expiresAt: Date())

        var iterator = subject.passRotation(after: initial).makeAsyncIterator()
        let rotated = try await iterator.next()

        XCTAssertEqual(rotated, rotatedPass)
    }

    func testPassRotation_afterServerError_retriesAndEmitsRotatedPass() async throws {
        let rotatedPass = makePass(token: "rotated", expiresAt: Date().addingTimeInterval(3600))
        mockTokenProvider.results = [
            .failure(AppAttestServiceError.serverError(statusCode: 503, description: "")),
            .success(rotatedPass)
        ]
        let subject = createSubject()
        let initial = makePass(expiresAt: Date())

        var iterator = subject.passRotation(after: initial).makeAsyncIterator()
        let rotated = try await iterator.next()

        XCTAssertEqual(rotated, rotatedPass)
        XCTAssertEqual(mockTokenProvider.proxyTokenCalled, 2)
    }

    func testPassRotation_onTerminalFailure_throws() async {
        mockTokenProvider.results = [.failure(AppAttestServiceError.serverError(statusCode: 401, description: ""))]
        let subject = createSubject()
        let initial = makePass(expiresAt: Date())

        var emitted: [VPNProxyPass] = []
        do {
            for try await pass in subject.passRotation(after: initial) {
                emitted.append(pass)
            }
            XCTFail("Expected rotation to throw")
        } catch AppAttestServiceError.serverError(let status, _) {
            XCTAssertEqual(status, 401)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(emitted.isEmpty)
        XCTAssertEqual(mockTokenProvider.proxyTokenCalled, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> VPNGuardian {
        let subject = VPNGuardian(tokenProvider: mockTokenProvider, logger: MockLogger())
        trackForMemoryLeaks(subject)
        return subject
    }

    private func makePass(token: String = "initial", expiresAt: Date) -> VPNProxyPass {
        return VPNProxyPass(bearerToken: token, notBefore: Date(), expiresAt: expiresAt, usage: nil)
    }
}

/// Returns `results` in order, repeating the last one once exhausted.
private final class MockVPNTokenProvider: VPNTokenProviding, @unchecked Sendable {
    var results: [Result<VPNProxyPass, Error>] = []
    var proxyTokenCalled = 0

    func proxyToken() async throws -> VPNProxyPass {
        let index = min(proxyTokenCalled, results.count - 1)
        proxyTokenCalled += 1
        return try results[index].get()
    }
}
