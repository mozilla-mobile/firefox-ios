// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class SecurityManagerTests: XCTestCase {
    let secureURL = URL(string: "https://foo.com")!
    let insecureURL = URL(string: "http://bar.com")!
    let secureFrameScheme = "https"
    let insecureFrameScheme = "http"

    func test_insecureTopFrame_insecureFrame() {
        let isSecureContext = SecurityContextManager.isSecureContext(webViewURL: insecureURL, frameScheme: insecureFrameScheme)
        XCTAssertFalse(isSecureContext)
    }

    func test_insecureTopFrame_secureFrame() {
        let isSecureContext = SecurityContextManager.isSecureContext(webViewURL: insecureURL, frameScheme: secureFrameScheme)
        XCTAssertFalse(isSecureContext)
    }

    func test_secureTopFrame_insecureFrame() {
        let isSecureContext = SecurityContextManager.isSecureContext(webViewURL: secureURL, frameScheme: insecureFrameScheme)
        XCTAssertFalse(isSecureContext)
    }

    func test_secureTopFrame_secureFrame() {
        let isSecureContext = SecurityContextManager.isSecureContext(webViewURL: secureURL, frameScheme: secureFrameScheme)
        XCTAssertFalse(isSecureContext)
    }
}
