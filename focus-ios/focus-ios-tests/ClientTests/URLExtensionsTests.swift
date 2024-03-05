/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import Foundation

class URLExtensionsTests: XCTestCase {

    private let validURLwithIPv4Address = [
        "http://0.0.0.0",
        "http://255.255.255.255",
        "http://127.0.0.1",
        "http://127.0.0.1:80",
        "http://user:password@127.0.0.1:80",
        "http://127.0.0.1:80/a/path",
        "http://127.0.0.1:80/a/path?q=aquery",
        "telnet://192.0.2.16:80/"
    ]

    private let invalidURLwithIPv4Address = [
        "127.0.0.1", // No scheme -> cannot extract host
        "http://127.0.0.0.1", // Too many segments
        "https://www.mozilla.com", // Does not include an address
        "http://256.256.256.256", // Number too big
        "http://256.0.0.1:80", // Number too big
        "http://256.0.0.1:80/a/path", // Number too big
        "http://256.0.0.1:80/a/path?q=aquery" // Number too big
    ]

    private let validURLwithIPv6Address = [
        "http://[::1]",
        "http://[1:2:3:4:5:6:7:8]",
        "http://[1:2:3:4:5:6::8]",
        "http://[1:2:3:4:5::8]",
        "http://[1:2:3:4::8]",
        "http://[1:2:3::8]",
        "http://[1:2::8]",
        "http://[1::8]",
        "http://[1::]",
        "http://[1:2:3:4:5:6:7:8%en0]",
        "http://[fe80::7:8%1]",
        "http://[2001:0db8:0000:0000:0000:ff00:0042:8329]",
        "http://[2001:db8:0:0:0:ff00:42:8329]",
        "http://[2001:db8::ff00:42:8329]",
        "http://[fe80::1]",
        "http://[64:ff9b::192.0.2.128]",
        "http://[::1]:80",
        "http://[::1]:80/a/path",
        "ldap://[2001:db8::7]/c=GB?objectClass?one"
    ]

    private let invalidURLwithIPv6Address = [
        "https://www.mozilla.com", // Does not include an address
        "::1", // No scheme -> cannot extract host
        "http://[1:]", // Too little ':'
        "http://[1:::]", // Too many ':'
        "http://[1::3::8]", // Two '0' blocks
        "http://[1:2:3:4:5:6:7:8:9]", // Too many segments
        "http://[fe80::7:8en0]", // % missing before interface
        "http://[2001:0db8:0000:0000::0000:ff00:0042:8329]" // :: even though all 0 written
    ]

    func testValidIPv4Addresses() throws {
        try validURLwithIPv4Address.forEach {
            let url = try XCTUnwrap(URL(string: $0))
            XCTAssertTrue(url.isIPv4, "No IPv4 address in URL: '\(url)'")
        }
    }

    func testInvalidIPv4Addresses() throws {
        try invalidURLwithIPv4Address.forEach {
            let url = try XCTUnwrap(URL(string: $0))
            XCTAssertFalse(url.isIPv4, "Unexpected IPv4 address in URL: '\(url)'")
        }
    }

    func testValidIPv6Addresses() throws {
        try validURLwithIPv6Address.forEach {
            let url = try XCTUnwrap(URL(string: $0))
            XCTAssertTrue(url.isIPv6, "No IPv& address in URL: '\(url)'")
        }
    }

    func testInvalidIPv6Addresses() throws {
        try invalidURLwithIPv6Address.forEach {
            let url = try XCTUnwrap(URL(string: $0))
            XCTAssertFalse(url.isIPv6, "Unexpected IPv6 address in URL: '\(url)'")
        }
    }
}
