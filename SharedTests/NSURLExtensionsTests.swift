/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Shared

class NSURLExtensionsTests : XCTestCase {
    func testRemovesHTTPFromURL() {
        let url = NSURL(string: "http://google.com")
        if let actual = url?.absoluteDisplayString() {
            XCTAssertEqual(actual, "google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testRemovesHTTPAndTrailingSlashFromURL() {
        let url = NSURL(string: "http://google.com/")
        if let actual = url?.absoluteDisplayString() {
            XCTAssertEqual(actual, "google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testRemovesHTTPButNotTrailingSlashFromURL() {
        let url = NSURL(string: "http://google.com/foo/")
        if let actual = url?.absoluteDisplayString() {
            XCTAssertEqual(actual, "google.com/foo/")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsHTTPSInURL() {
        let url = NSURL(string: "https://google.com")
        if let actual = url?.absoluteDisplayString() {
            XCTAssertEqual(actual, "https://google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsHTTPSAndRemovesTrailingSlashInURL() {
        let url = NSURL(string: "https://google.com/")
        if let actual = url?.absoluteDisplayString() {
            XCTAssertEqual(actual, "https://google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsHTTPSAndTrailingSlashInURL() {
        let url = NSURL(string: "https://google.com/foo/")
        if let actual = url?.absoluteDisplayString() {
            XCTAssertEqual(actual, "https://google.com/foo/")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsAboutSchemeInURL() {
        let url = NSURL(string: "about:home")
        if let actual = url?.absoluteDisplayString() {
            XCTAssertEqual(actual, "about:home")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    //MARK: Public Suffix
    func testNormalBaseDomainWithSingleSubdomain() {
        // TLD Entry: co.uk
        let url = "http://a.bbc.co.uk".asURL!
        let expected = url.publicSuffix()!
        XCTAssertEqual("co.uk", expected)
    }

    func testCanadaComputers() {
        let url = "http://m.canadacomputers.com".asURL!
        let actual = url.baseDomain()!
        XCTAssertEqual("canadacomputers.com", actual)
    }

    func testMultipleSuffixesInsideURL() {
        let url = "http://com:org@m.canadacomputers.co.uk".asURL!
        let actual = url.baseDomain()!
        XCTAssertEqual("canadacomputers.co.uk", actual)
    }

    func testNormalBaseDomainWithManySubdomains() {
        // TLD Entry: co.uk
        let url = "http://a.b.c.d.bbc.co.uk".asURL!
        let expected = url.publicSuffix()!
        XCTAssertEqual("co.uk", expected)
    }

    func testWildCardDomainWithSingleSubdomain() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.kawasaki.jp".asURL!
        let expected = url.publicSuffix()!
        XCTAssertEqual("a.kawasaki.jp", expected)
    }

    func testWildCardDomainWithManySubdomains() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.b.c.d.kawasaki.jp".asURL!
        let expected = url.publicSuffix()!
        XCTAssertEqual("d.kawasaki.jp", expected)
    }

    func testExceptionDomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = "http://city.kawasaki.jp".asURL!
        let expected = url.publicSuffix()!
        XCTAssertEqual("kawasaki.jp", expected)
    }

    //MARK: Base Domain
    func testNormalBaseSubdomain() {
        // TLD Entry: co.uk
        let url = "http://bbc.co.uk".asURL!
        let expected = url.baseDomain()!
        XCTAssertEqual("bbc.co.uk", expected)
    }

    func testNormalBaseSubdomainWithAdditionalSubdomain() {
        // TLD Entry: co.uk
        let url = "http://a.bbc.co.uk".asURL!
        let expected = url.baseDomain()!
        XCTAssertEqual("bbc.co.uk", expected)
    }

    func testBaseDomainForWildcardDomain() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.b.kawasaki.jp".asURL!
        let expected = url.baseDomain()!
        XCTAssertEqual("a.b.kawasaki.jp", expected)
    }

    func testBaseDomainForWildcardDomainWithAdditionalSubdomain() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.b.c.kawasaki.jp".asURL!
        let expected = url.baseDomain()!
        XCTAssertEqual("b.c.kawasaki.jp", expected)
    }

    func testBaseDomainForExceptionDomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = "http://city.kawasaki.jp".asURL!
        let expected = url.baseDomain()!
        XCTAssertEqual("city.kawasaki.jp", expected)
    }

    func testBaseDomainForExceptionDomainWithAdditionalSubdomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = "http://a.city.kawasaki.jp".asURL!
        let expected = url.baseDomain()!
        XCTAssertEqual("city.kawasaki.jp", expected)
    }

    func testBugzillaURLDomain() {
        let url = "https://bugzilla.mozilla.org/enter_bug.cgi?format=guided#h=dupes|Data%20%26%20BI%20Services%20Team|"
        let nsURL = url.asURL
        XCTAssertNotNil(nsURL, "URL parses.")

        let host = nsURL!.normalizedHost()
        XCTAssertEqual(host!, "bugzilla.mozilla.org")
        XCTAssertEqual(nsURL!.fragment!, "h=dupes%7CData%20%26%20BI%20Services%20Team%7C")
    }
}