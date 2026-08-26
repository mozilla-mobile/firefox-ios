// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class FxAPairingURLParserTests: XCTestCase {
    func testPairingURLReturnsProductionPairingURLWithFragmentCredentials() {
        let url = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .pairing(url))
    }

    func testPairingURLReturnsStagePairingURLWithFragmentCredentials() {
        let url = URL(
            string: "https://accounts.stage.mozaws.net/pair#channel_id=channel&channel_key=key&v=2"
        )!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .pairing(url))
    }

    func testPairingURLAcceptsTrailingSlash() {
        let url = URL(string: "https://accounts.firefox.com/pair/#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .pairing(url))
    }

    func testPairingURLRejectsUntrustedHost() {
        let url = URL(string: "https://example.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .notPairing)
    }

    func testPairingURLRejectsHTTP() {
        let url = URL(string: "http://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .invalidPairing)
    }

    func testPairingURLRejectsEmbeddedCredentials() {
        let url = URL(
            string: "https://user:password@accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2"
        )!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .invalidPairing)
    }

    func testPairingURLRejectsMissingChannelCredentials() {
        let url = URL(string: "https://accounts.firefox.com/pair#v=2")!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .invalidPairing)
    }

    func testPairingURLWithoutVersionUsesExistingBehavior() {
        let url = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key")!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .notPairing)
    }

    func testPairingURLWithUnsupportedVersionUsesExistingBehavior() {
        let url = URL(string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=1")!

        XCTAssertEqual(FxAPairingURLParser.parse(url), .notPairing)
    }

    func testPairingURLWithNonEntryPathUsesExistingBehavior() {
        let paths = ["pair/supp", "poc_pair_init", "poc_pair_start"]

        for path in paths {
            let url = URL(
                string: "https://accounts.stage.mozaws.net/\(path)#channel_id=channel&channel_key=key&v=2"
            )!
            XCTAssertEqual(FxAPairingURLParser.parse(url), .notPairing)
        }
    }
}
