// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class FxAPairingURLParserTests: XCTestCase {
    private let production = URL(string: "https://accounts.firefox.com")!
    private let stage = URL(string: "https://accounts.stage.mozaws.net")!
    private let localStack = URL(string: "http://localhost:3030")!

    func testPairingURLReturnsProductionPairingURLWithFragmentCredentials() {
        let url = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .pairing(url))
    }

    func testPairingURLReturnsStagePairingURLWithFragmentCredentials() {
        let url = URL(
            string: "https://accounts.stage.mozaws.net/pair#channel_id=channel&channel_key=key&v=2"
        )!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: stage), .pairing(url))
    }

    func testPairingURLAcceptsTrailingSlash() {
        let url = URL(string: "https://accounts.firefox.com/pair/#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .pairing(url))
    }

    func testPairingURLRejectsUntrustedHost() {
        let url = URL(string: "https://example.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .notPairing)
    }

    func testPairingURLRejectsHTTP() {
        let url = URL(string: "http://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .invalidPairing)
    }

    func testPairingURLRejectsEmbeddedCredentials() {
        let url = URL(
            string: "https://user:password@accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2"
        )!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .invalidPairing)
    }

    func testPairingURLRejectsMissingChannelCredentials() {
        let url = URL(string: "https://accounts.firefox.com/pair#v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .invalidPairing)
    }

    func testPairingURLWithoutVersionUsesExistingBehavior() {
        let url = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .notPairing)
    }

    func testPairingURLWithUnsupportedVersionUsesExistingBehavior() {
        let url = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=1")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .notPairing)
    }

    func testPairingURLWithNonEntryPathUsesExistingBehavior() {
        let paths = ["pair/supp", "poc_pair_init", "poc_pair_start"]

        for path in paths {
            let url = URL(
                string: "https://accounts.stage.mozaws.net/\(path)#channel_id=channel&channel_key=key&v=2"
            )!
            XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: stage), .notPairing)
        }
    }

    // MARK: - Content server scoping

    func testPairingURLRejectsServerTheAppIsNotConfiguredAgainst() {
        let url = URL(
            string: "https://accounts.stage.mozaws.net/pair#channel_id=channel&channel_key=key&v=2"
        )!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .notPairing)
    }

    func testPairingURLAcceptsLocalStackOverHTTP() {
        let url = URL(string: "http://localhost:3030/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: localStack), .pairing(url))
    }

    func testPairingURLRejectsLocalStackOnAnotherPort() {
        let url = URL(string: "http://localhost:9999/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: localStack), .invalidPairing)
    }

    // MARK: - Default port normalization

    /// The returned URL becomes the web view's `baseURL`, which the WebChannel bridge compares
    /// against `WKSecurityOrigin`. That reports port 0 for a scheme default, so an explicit `:443`
    /// must be stripped here or the bridge silently ignores every message from the page.
    func testPairingURLStripsAnExplicitDefaultPort() {
        let url = URL(string: "https://accounts.firefox.com:443/pair#channel_id=channel&channel_key=key&v=2")!
        let expected = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .pairing(expected))
    }

    /// Same reason: `WKSecurityOrigin` reports a lowercased host and scheme.
    func testPairingURLLowercasesSchemeAndHost() {
        let url = URL(string: "HTTPS://ACCOUNTS.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!
        let expected = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .pairing(expected))
    }

    func testPairingURLKeepsANonDefaultPort() {
        let server = URL(string: "http://localhost:3030")!
        let url = URL(string: "http://localhost:3030/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: server), .pairing(url))
    }

    func testPairingURLAcceptsImplicitPortWhenServerStatesTheDefault() {
        let server = URL(string: "https://accounts.firefox.com:443")!
        let url = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: server), .pairing(url))
    }

    func testPairingURLRejectsNonDefaultPortAgainstDefaultPortServer() {
        let url = URL(string: "https://accounts.firefox.com:8443/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: production), .invalidPairing)
    }

    // MARK: - Cleartext is confined to loopback

    func testPairingURLRejectsHTTPForRemoteCustomContentServer() {
        let server = URL(string: "http://fxa.example.com")!
        let url = URL(string: "http://fxa.example.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: server), .invalidPairing)
    }

    func testPairingURLAcceptsLoopbackAddressOverHTTP() {
        let server = URL(string: "http://127.0.0.1:3030")!
        let url = URL(string: "http://127.0.0.1:3030/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url, contentServer: server), .pairing(url))
    }
}
