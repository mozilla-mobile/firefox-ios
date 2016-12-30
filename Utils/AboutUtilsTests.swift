/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

class AboutUtilsTests: XCTestCase {

    func testisAboutHomeURL() {
        let goodurls = [
            "http://localhost:1234/about/home/#panel=0",
            "http://localhost:6571/errors/error.html?url=http%3A//localhost%3A6571/about/home/%23panel%3D1",

        ]
        let badurls = [
            "http://google.com",
            "http://localhost:6571/sessionrestore.html",
            "http://localhost:6571/errors/error.html?url=http%3A//mozilla.com",
            "http://localhost:6571/errors/error.html?url=http%3A//mozilla.com/about/home/%23panel%3D1",
        ]

        goodurls.forEach { XCTAssertTrue(AboutUtils.isAboutHomeURL(NSURL(string:$0)), $0) }
        badurls.forEach { XCTAssertFalse(AboutUtils.isAboutHomeURL(NSURL(string:$0)), $0) }
    }

    func testisAboutURL() {
        let goodurls = [
            "http://localhost:1234/about/home/#panel=0",
            "http://localhost:1234/about/firefox"
        ]
        let badurls = [
            "http://google.com",
            "http://localhost:6571/sessionrestore.html",
            "http://localhost:6571/errors/error.html?url=http%3A//mozilla.com",
            "http://localhost:6571/errors/error.html?url=http%3A//mozilla.com/about/home/%23panel%3D1",
        ]

        goodurls.forEach { XCTAssertTrue(AboutUtils.isAboutURL(NSURL(string:$0)), $0) }
        badurls.forEach { XCTAssertFalse(AboutUtils.isAboutURL(NSURL(string:$0)), $0) }
    }

    func testisErrorPage() {
        let goodurls = [
            "http://localhost:6571/errors/error.html?url=http%3A//mozilla.com",
            "http://localhost:6572/errors/error.html?url=blah",
        ]
        let badurls = [
            "http://google.com",
            "http://localhost:6571/sessionrestore.html",
            "http://localhost:1234/about/home/#panel=0"
            ]

        goodurls.forEach { XCTAssertTrue(AboutUtils.isErrorPageURL(NSURL(string:$0)!), $0) }
        badurls.forEach { XCTAssertFalse(AboutUtils.isErrorPageURL(NSURL(string:$0)!), $0) }
    }
}
