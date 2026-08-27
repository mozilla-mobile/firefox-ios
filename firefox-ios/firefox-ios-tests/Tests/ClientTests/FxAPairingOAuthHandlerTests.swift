// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import enum MozillaAppServices.OAuthScope

@MainActor
final class FxAPairingOAuthHandlerTests: XCTestCase {
    private lazy var handler = FxAPairingOAuthHandler(authenticatorProvider: { nil })

    func testStartUsesPairingConfigurationAndReturnsParameters() throws {
        let authenticator = MockPairingOAuthAuthenticator(result: .success(pairingAuthenticationURL()))
        let handler = FxAPairingOAuthHandler(authenticatorProvider: { authenticator })
        var receivedResult: Result<[String: String], FxAPairingOAuthHandlerError>?

        handler.start { result in
            receivedResult = result
        }

        XCTAssertEqual(authenticator.entrypoint, "webchannel-pairing")
        XCTAssertEqual(
            authenticator.scopes,
            [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session]
        )
        XCTAssertEqual(try XCTUnwrap(receivedResult).get(), handler.parameters(from: pairingAuthenticationURL()))
    }

    func testStartReturnsFailureWhenAuthenticatorIsUnavailable() {
        var receivedResult: Result<[String: String], FxAPairingOAuthHandlerError>?

        handler.start { result in
            receivedResult = result
        }

        assertFailedToStart(receivedResult)
    }

    func testStartReturnsFailureWhenAuthenticationFails() {
        let error = NSError(domain: "FxAPairingOAuthHandlerTests", code: 1)
        let authenticator = MockPairingOAuthAuthenticator(result: .failure(error))
        let handler = FxAPairingOAuthHandler(authenticatorProvider: { authenticator })
        var receivedResult: Result<[String: String], FxAPairingOAuthHandlerError>?

        handler.start { result in
            receivedResult = result
        }

        assertFailedToStart(receivedResult)
    }

    func testStartReturnsFailureWhenParametersAreMissing() {
        let incompleteURL = URL(string: "https://accounts.firefox.com/authorization?state=st8")!
        let authenticator = MockPairingOAuthAuthenticator(result: .success(incompleteURL))
        let handler = FxAPairingOAuthHandler(authenticatorProvider: { authenticator })
        var receivedResult: Result<[String: String], FxAPairingOAuthHandlerError>?

        handler.start { result in
            receivedResult = result
        }

        assertFailedToStart(receivedResult)
    }

    func testParametersReturnsRequiredParameters() {
        XCTAssertEqual(
            handler.parameters(from: pairingAuthenticationURL()),
            [
                "state": "st8",
                "scope": "profile https://identity.mozilla.com/apps/oldsync",
                "code_challenge": "chal8",
                "code_challenge_method": "S256",
                "keys_jwk": "jwk8"
            ]
        )
    }

    func testParametersReturnsNilWhenAParameterIsMissing() {
        let url = URL(string: "https://accounts.firefox.com/authorization?state=st8")!

        XCTAssertNil(handler.parameters(from: url))
    }

    private func pairingAuthenticationURL() -> URL {
        var components = URLComponents(string: "https://accounts.firefox.com/authorization")!
        components.queryItems = [
            URLQueryItem(name: "state", value: "st8"),
            URLQueryItem(name: "scope", value: "profile https://identity.mozilla.com/apps/oldsync"),
            URLQueryItem(name: "code_challenge", value: "chal8"),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "keys_jwk", value: "jwk8")
        ]
        return components.url!
    }

    private func assertFailedToStart(
        _ result: Result<[String: String], FxAPairingOAuthHandlerError>?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let result, case .failure(.failedToStart) = result else {
            XCTFail("Expected the pairing OAuth flow to fail to start", file: file, line: line)
            return
        }
    }
}

private final class MockPairingOAuthAuthenticator: FxAOAuthAuthenticating {
    private let result: Result<URL, Error>
    private(set) var entrypoint: String?
    private(set) var scopes: [String]?

    init(result: Result<URL, Error>) {
        self.result = result
    }

    func beginAuthentication(
        entrypoint: String,
        scopes: [String],
        completionHandler: @escaping @MainActor @Sendable (Result<URL, Error>) -> Void
    ) {
        self.entrypoint = entrypoint
        self.scopes = scopes
        completionHandler(result)
    }
}
