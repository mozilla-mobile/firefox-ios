// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class URLExtensionTests: XCTestCase {
    private var webServerPort = 1234

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

    func testNormalizedHostReturnsOriginalHost() {
        let url = URL(string: "https://mobile.co.uk")!
        let host = url.normalizedHost
        XCTAssertEqual(host, "mobile.co.uk")
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

    func testGetSubdomainAndHost() {
        let testCases = [
            ("https://www.google.com", (nil, "google.com")),
            ("https://blog.engineering.company.com", ("blog.engineering.", "blog.engineering.company.com")),
            ("https://long-extended-subdomain-name-containing-many-letters-and-dashes.badssl.com", ("long-extended-subdomain-name-containing-many-letters-and-dashes.", "long-extended-subdomain-name-containing-many-letters-and-dashes.badssl.com")),
            ("http://com:org@m.canadacomputers.co.uk", (nil, "canadacomputers.co.uk")),
            ("https://www.wix.com/blog/what-is-a-subdomain", (nil, "wix.com")),
            ("nothing", (nil, "nothing")),
            ("https://super-long-url-with-dashes-and-things.badssl.com/xyz-something", ("super-long-url-with-dashes-and-things.", "super-long-url-with-dashes-and-things.badssl.com")),
            ("https://accounts.firefox.com", ("accounts.", "accounts.firefox.com")),
            ("http://username:password@subdomain.example.com:8080", ("subdomain.", "subdomain.example.com")),
            ("https://example.com:8080#fragment", (nil, "example.com")),
            ("http://username:password@subdomain.example.com:8080#fragment", ("subdomain.", "subdomain.example.com")),
            ("https://www.amazon.co.uk", (nil, "amazon.co.uk")),
            ("https://mobile.co.uk", (nil, "mobile.co.uk"))
        ]

        for testCase in testCases {
            let (urlString, expected) = testCase
            let result = URL.getSubdomainAndHost(from: urlString)
            XCTAssertEqual(result.subdomain, expected.0, "Unexpected subdomain for URL: \(urlString)")
            XCTAssertEqual(result.normalizedHost, expected.1, "Unexpected normalized host for URL: \(urlString)")
        }
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

    // MARK: getQuery tests

    func testGetQueryWhenTheresParametersThenGetQueryReturnsTheRightParameters() {
        let url = URL(string: "http://example.com/path?a=1&b=2&c=3")!

        let urlParams = url.getQuery()

        let expectedParams = ["a": "1", "b": "2", "c": "3"]
        XCTAssertEqual(urlParams["a"], expectedParams["a"])
        XCTAssertEqual(urlParams["b"], expectedParams["b"])
        XCTAssertEqual(urlParams["c"], expectedParams["c"])
    }

    func testGetQueryWhenPercentEncodedParamsThenGetQueryReturnsTheRightParameters() {
        let url = URL(string: "http://example.com/path?a=%20")!

        let urlParams = url.getQuery()

        XCTAssertEqual(urlParams["a"], "%20")
    }

    // MARK: isWebPage

    func testIsWebPageGivenReaderModeURLThenisWebPage() {
        let url = URL(string: "http://localhost:\(webServerPort)/reader-mode/page")!
        XCTAssertTrue(url.isWebPage())
    }

    func testIsWebPageGivenSessionRestoreHTMLThenisWebPage() {
        let url = URL(string: "https://127.0.0.1:\(webServerPort)/sessionrestore.html")!
        XCTAssertTrue(url.isWebPage())
    }

    func testIsWebPageGivenDataSessionRestoreThenisWebPage() {
        let url = URL(string: "data://:\(webServerPort)/sessionrestore.html")!
        XCTAssertTrue(url.isWebPage())
    }

    func testIsWebPageGivenAboutURLThenisNotWebPage() {
        let url = URL(string: "about://google.com")!
        XCTAssertFalse(url.isWebPage())
    }

    func testIsWebPageGivenTelURLThenisNotWebPage() {
        let url = URL(string: "tel:6044044004")!
        XCTAssertFalse(url.isWebPage())
    }

    func testIsWebPageGivenLocalHostURLThenisNotWebPage() {
        let url = URL(string: "hax://localhost:\(webServerPort)/about")!
        XCTAssertFalse(url.isWebPage())
    }

    // MARK: Host port

    func testHostPortGivenExampleHostThenIsEqual() {
        let givenURL = URL(string: "https://www.example.com")!
        XCTAssertEqual(givenURL.hostPort, "www.example.com")
    }

    func testHostPortGivenUserPassHostThenIsEqual() {
        let givenURL = URL(string: "https://user:pass@www.example.com")!
        XCTAssertEqual(givenURL.hostPort, "www.example.com")
    }

    func testHostPortGivenLocalHostThenIsEqual() {
        let givenURL = URL(string: "http://localhost:6000/blah")!
        XCTAssertEqual(givenURL.hostPort, "localhost:6000")
    }

    func testHostPortGivenBlahURLThenIsNil() {
        let givenURL = URL(string: "blah")!
        XCTAssertNil(givenURL.hostPort)
    }

    func testHostPortGivenEmptyURLThenIsNil() {
        let givenURL = URL(string: "http://")!
        XCTAssertNil(givenURL.hostPort)
    }

    // MARK: Origin

    func testOriginGivenExampleIndexURLThenOriginIsExample() {
        let givenURL = URL(string: "https://www.example.com/index.html")!
        XCTAssertEqual(givenURL.origin, "https://www.example.com")

        let badurls = [
            "data://google.com"
        ]
        badurls.forEach { XCTAssertNil(URL(string: $0)!.origin) }
    }

    func testOriginGivenUserPassURLThenOriginIsFoo() {
        let givenURL = URL(string: "https://user:pass@m.foo.com/bar/baz?noo=abc#123")!
        XCTAssertEqual(givenURL.origin, "https://m.foo.com")
    }

    func testOriginGivenDataURLThenOriginIsNil() {
        let givenURL = URL(string: "data://google.com")!
        XCTAssertNil(givenURL.origin)
    }

    // MARK: isReaderModeURL tests

    func testIsReaderModeURLGivenGoogleURLThenFalse() {
        let url = URL(string: "https://google.com")!
        XCTAssertFalse(url.isReaderModeURL)
    }

    func testIsReaderModeURLGivenHTTPSchemeURLThenFalse() {
        let url = URL(string: "http://google.com")!
        XCTAssertFalse(url.isReaderModeURL)
    }

    func testIsReaderModeURLGivenLocalHostURLThenFalse() {
        let url = URL(string: "http://localhost")!
        XCTAssertFalse(url.isReaderModeURL)
    }

    func testIsReaderModeURLGivenReaderModeURLThenTrue() {
        let url = URL(string: "http://localhost:\(webServerPort)/reader-mode/page")!
        XCTAssertTrue(url.isReaderModeURL)
    }

    // MARK: isSyncedReaderModeURL tests

    func testIsSyncedReaderModeURLWhenEmptyURLThenIsTrue() {
        let url = "about:reader?url="
        XCTAssertTrue(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenSimpleURLThenIsTrue() {
        let url = "about:reader?url=http://example.com"
        XCTAssertTrue(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenComplicatedURLThenIsTrue() {
        let url = "about:reader?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage"
        XCTAssertTrue(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenGoogleURLThenIsFalse() {
        let url = "http://google.com"
        XCTAssertFalse(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenLocalHostURLThenIsFalse() {
        let url = "http://localhost:\(webServerPort)/sessionrestore.html"
        XCTAssertFalse(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenAboutURLThenIsFalse() {
        let url = "about:reader"
        XCTAssertFalse(URL(string: url)!.isSyncedReaderModeURL)
    }

    // MARK: decodeReaderModeURL tests

    func testDecodeReaderModeURLWhenLocalReaderModeThenGivesWikiPage() {
        let readerModeURL = "http://localhost:\(webServerPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage&uuidkey=AAAAA"
        let url = URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")

        XCTAssertEqual(URL(string: readerModeURL)!.decodeReaderModeURL, url)
    }

    func testDecodeReaderModeURLWhenReaderModeThenGivesWikiPage() {
        let readerModeURL = "about:reader?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage&uuidkey=AAAAA"
        let url = URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")

        XCTAssertEqual(URL(string: readerModeURL)!.decodeReaderModeURL, url)
    }

    func testDecodeReaderModeURLWhenParameterURLThenGivesCorrectParameterURL() {
        let readerModeURL = "about:reader?url=http%3A%2F%2Fexample%2Ecom%3Furl%3Dparam%26key%3Dvalue&uuidkey=AAAAA"
        let url = URL(string: "http://example.com?url=param&key=value")

        XCTAssertEqual(URL(string: readerModeURL)!.decodeReaderModeURL, url)
    }

    func testDecodeReaderModeURLGivenNotAReaderModeURLThenNil() {
        let url = "http://google.com"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenLocalHostSessionRestoreURLThenNil() {
        let url = "http://localhost:\(webServerPort)/sessionrestore.html"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenLocalAboutHomeURLThenNil() {
        let url = "http://localhost:1234/about/home/#panel=0"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenLocalHostReaderModePageThenNil() {
        let url = "http://localhost:\(webServerPort)/reader-mode/page"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenAboutReaderURLThenNil() {
        let url = "about:reader?url="
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    // MARK: safeEncodedUrl tests

    func testSafeEncodedUrlGivenJavaScriptSanitization() {
        // reader mode generic url sanitized JS to prevent XSS alert
        let url = URL(string: "http://localhost:1234/reader-mode/page?url=javascript:alert('ALERT')")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(
            genericUrl!.absoluteString.contains("javascript:alert(%26%2339;ALERT%26%2339;)")
        )
    }

    func testSafeEncodedUrlGivenScriptInnerHtmlTextSanitization() {
        // reader mode generic url script tags are sanitized to prevent body change
        let url = URL(string: "http://localhost:1234/reader-mode/page?url=javascript:document.body.innerText='Hello';")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(
            genericUrl!.absoluteString.contains("javascript:document.body.innerText%3D%26%2339;Hello%26%2339;;")
        )
    }

    func testSafeEncodedUrlGivenHTMLFontSanitization() {
        // reader mode generic url with HTML is sanitized
        let url = URL(string: "http://localhost:1234/reader-mode/page?url=javascript:document.body.style.fontSize='50px';")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(
            genericUrl!.absoluteString.contains("javascript:document.body.style.fontSize%3D%26%2339;50px%26%2339;;")
        )
    }

    func testSafeEncodedUrlGivenJavaScriptSanitizationNonLocalhost() {
        // Check if JavaScript code in a non-localhost URL is sanitized
        let url = URL(string: "http://example.com/reader-mode/page?url=javascript:alert('XSS')")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(genericUrl!.absoluteString.contains("javascript:alert(%26%2339;XSS%26%2339;)"))
    }

    func testSafeEncodedUrlGivenEmptyPath() {
        let url = URL(string: "http://localhost:1234")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNotNil(safeUrl)
    }

    func testSafeEncodedUrlGivenEmptyScheme() {
        let url = URL(string: "//localhost:1234/page")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNil(safeUrl)
    }

    func testSafeEncodedUrlGivenMissingComponentsJS() {
        let url = URL(string: "javascript:blob")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNil(safeUrl)
    }

    func testSafeEncodedUrlGivenMissingComponents() {
        let url = URL(string: "/page?url=javascript")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNil(safeUrl)
    }

    func testFaviconRootDirectoryURL() {
        let url1 = URL(string: "https://some.domain.com/path/subpath")
        let favicon1 = url1?.faviconUrl()
        XCTAssertEqual(favicon1, URL(string: "https://some.domain.com/favicon.ico")!)

        let url2 = URL(string: "http://website.org////")
        let favicon2 = url2?.faviconUrl()
        XCTAssertEqual(favicon2, URL(string: "http://website.org/favicon.ico")!)

        let url3 = URL(string: "scheme://another.website.net/path/")
        let favicon3 = url3?.faviconUrl()
        XCTAssertEqual(favicon3, URL(string: "scheme://another.website.net/favicon.ico")!)
    }
}
