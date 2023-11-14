// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class URLExtensionTests: XCTestCase {
    func testNormalBaseDomainWithSingleSubdomain() {
        // TLD Entry: co.uk
        let url = URL(string: "http://a.bbc.co.uk")!
        let expected = url.publicSuffix!
        XCTAssertEqual("co.uk", expected)
    }

    func testCanadaComputers() {
        let url = URL(string: "http://m.canadacomputers.com")!
        let actual = url.baseDomain!
        XCTAssertEqual("canadacomputers.com", actual)
    }

    func testMultipleSuffixesInsideURL() {
        let url = URL(string: "http://com:org@m.canadacomputers.co.uk")!
        let actual = url.baseDomain!
        XCTAssertEqual("canadacomputers.co.uk", actual)
    }

    func testNormalBaseDomainWithManySubdomains() {
        // TLD Entry: co.uk
        let url = URL(string: "http://a.b.c.d.bbc.co.uk")!
        let expected = url.publicSuffix!
        XCTAssertEqual("co.uk", expected)
    }

    func testWildCardDomainWithSingleSubdomain() {
        // TLD Entry: *.kawasaki.jp
        let url = URL(string: "http://a.kawasaki.jp")!
        let expected = url.publicSuffix!
        XCTAssertEqual("a.kawasaki.jp", expected)
    }

    func testWildCardDomainWithManySubdomains() {
        // TLD Entry: *.kawasaki.jp
        let url = URL(string: "http://a.b.c.d.kawasaki.jp")!
        let expected = url.publicSuffix!
        XCTAssertEqual("d.kawasaki.jp", expected)
    }

    func testExceptionDomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = URL(string: "http://city.kawasaki.jp")!
        let expected = url.publicSuffix!
        XCTAssertEqual("kawasaki.jp", expected)
    }

    // MARK: Base Domain
    func testNormalBaseSubdomain() {
        // TLD Entry: co.uk
        let url = URL(string: "http://bbc.co.uk")!
        let expected = url.baseDomain!
        XCTAssertEqual("bbc.co.uk", expected)
    }

    func testNormalBaseSubdomainWithAdditionalSubdomain() {
        // TLD Entry: co.uk
        let url = URL(string: "http://a.bbc.co.uk")!
        let expected = url.baseDomain!
        XCTAssertEqual("bbc.co.uk", expected)
    }

    func testBaseDomainForWildcardDomain() {
        // TLD Entry: *.kawasaki.jp
        let url = URL(string: "http://a.b.kawasaki.jp")!
        let expected = url.baseDomain!
        XCTAssertEqual("a.b.kawasaki.jp", expected)
    }

    func testBaseDomainForWildcardDomainWithAdditionalSubdomain() {
        // TLD Entry: *.kawasaki.jp
        let url = URL(string: "http://a.b.c.kawasaki.jp")!
        let expected = url.baseDomain!
        XCTAssertEqual("b.c.kawasaki.jp", expected)
    }

    func testBaseDomainForExceptionDomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = URL(string: "http://city.kawasaki.jp")!
        let expected = url.baseDomain!
        XCTAssertEqual("city.kawasaki.jp", expected)
    }

    func testBaseDomainForExceptionDomainWithAdditionalSubdomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = URL(string: "http://a.city.kawasaki.jp")!
        let expected = url.baseDomain!
        XCTAssertEqual("city.kawasaki.jp", expected)
    }

    func testBugzillaURLDomain() {
        let url = URL(string: "https://bugzilla.mozilla.org/enter_bug.cgi?format=guided#h=dupes%7CData%20%26%20BI%20Services%20Team%7C")
        XCTAssertNotNil(url, "URL parses.")

        let host = url!.normalizedHost
        XCTAssertEqual(host!, "bugzilla.mozilla.org")
        XCTAssertEqual(url!.fragment!, "h=dupes%7CData%20%26%20BI%20Services%20Team%7C")
    }

    func testIPv6Domain() {
        let url = URL(string: "http://[::1]/foo/bar")!
        XCTAssertTrue(url.isIPv6)
        XCTAssertNil(url.baseDomain)
        XCTAssertEqual(url.normalizedHost!, "[::1]")
    }

    func testDomainURL() {
        let urls = [
            ("https://www.example.com/index.html", "https://example.com/"),
            ("https://mail.example.com/index.html", "https://mail.example.com/"),
            ("https://mail.example.co.uk/index.html", "https://mail.example.co.uk/"),
        ]
        urls.forEach { XCTAssertEqual(URL(string: $0.0)!.domainURL.absoluteString, $0.1) }
    }

    func testnormalizedHostAndPath() {
        let goodurls = [
            ("https://www.example.com/index.html", "example.com/index.html"),
            ("https://mail.example.com/index.html", "mail.example.com/index.html"),
            ("https://mail.example.co.uk/index.html", "mail.example.co.uk/index.html"),
            ("https://m.example.co.uk/index.html", "example.co.uk/index.html")
        ]
        let badurls = [
            "http:///errors/error.html",
            "http://:8080/about/home",
        ]

        goodurls.forEach { XCTAssertEqual(URL(string: $0.0)!.normalizedHostAndPath, $0.1) }
        badurls.forEach { XCTAssertNil(URL(string: $0)!.normalizedHostAndPath) }
    }

    func testShortDisplayString() {
        let urls = [
            ("https://www.example.com/index.html", "example"),
            ("https://m.foo.com/bar/baz?noo=abc#123", "foo"),
            ("https://user:pass@m.foo.com/bar/baz?noo=abc#123", "foo"),
            ("https://accounts.foo.com/bar/baz?noo=abc#123", "accounts.foo"),
            ("https://accounts.what.foo.co.za/bar/baz?noo=abc#123", "accounts.what.foo"),
        ]
        urls.forEach { XCTAssertEqual(URL(string: $0.0)!.shortDisplayString, $0.1) }
    }

    func testBlobURLGetHost() {
        let url = URL(string: "blob:https://example.blob.com")!

        XCTAssertNil(url.host)
    }

    func testRemoveBlobFromUrl_WithBlob() {
        let url = URL(string: "blob:https://example.blob.com")!

        let originalURL = url.removeBlobFromUrl()
        XCTAssertEqual(originalURL, URL(string: "https://example.blob.com"))
    }

    func testRemoveBlobFromUrl_WithoutBlob() {
        let url = URL(string: "https://example.blob.com")!

        let originalURL = url.removeBlobFromUrl()
        XCTAssertEqual(originalURL, URL(string: "https://example.blob.com"))
    }
}
