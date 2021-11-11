// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import XCTest
@testable import Shared

class NSURLExtensionsTests: XCTestCase {
    func testRemovesHTTPFromURL() {
        let url = URL(string: "http://google.com")
        if let actual = url?.absoluteDisplayString {
            XCTAssertEqual(actual, "google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testRemovesHTTPAndTrailingSlashFromURL() {
        let url = URL(string: "http://google.com/")
        if let actual = url?.absoluteDisplayString {
            XCTAssertEqual(actual, "google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testRemovesHTTPButNotTrailingSlashFromURL() {
        let url = URL(string: "http://google.com/foo/")
        if let actual = url?.absoluteDisplayString {
            XCTAssertEqual(actual, "google.com/foo/")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsHTTPSInURL() {
        let url = URL(string: "https://google.com")
        if let actual = url?.absoluteDisplayString {
            XCTAssertEqual(actual, "https://google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsHTTPSAndRemovesTrailingSlashInURL() {
        let url = URL(string: "https://google.com/")
        if let actual = url?.absoluteDisplayString {
            XCTAssertEqual(actual, "https://google.com")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsHTTPSAndTrailingSlashInURL() {
        let url = URL(string: "https://google.com/foo/")
        if let actual = url?.absoluteDisplayString {
            XCTAssertEqual(actual, "https://google.com/foo/")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    func testKeepsAboutSchemeInURL() {
        let url = URL(string: "about:home")
        if let actual = url?.absoluteDisplayString {
            XCTAssertEqual(actual, "about:home")
        } else {
            XCTFail("Actual url is nil")
        }
    }

    //MARK: Public Suffix
    func testNormalBaseDomainWithSingleSubdomain() {
        // TLD Entry: co.uk
        let url = "http://a.bbc.co.uk".asURL!
        let expected = url.publicSuffix!
        XCTAssertEqual("co.uk", expected)
    }

    func testCanadaComputers() {
        let url = "http://m.canadacomputers.com".asURL!
        let actual = url.baseDomain!
        XCTAssertEqual("canadacomputers.com", actual)
    }

    func testMultipleSuffixesInsideURL() {
        let url = "http://com:org@m.canadacomputers.co.uk".asURL!
        let actual = url.baseDomain!
        XCTAssertEqual("canadacomputers.co.uk", actual)
    }

    func testNormalBaseDomainWithManySubdomains() {
        // TLD Entry: co.uk
        let url = "http://a.b.c.d.bbc.co.uk".asURL!
        let expected = url.publicSuffix!
        XCTAssertEqual("co.uk", expected)
    }

    func testWildCardDomainWithSingleSubdomain() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.kawasaki.jp".asURL!
        let expected = url.publicSuffix!
        XCTAssertEqual("a.kawasaki.jp", expected)
    }

    func testWildCardDomainWithManySubdomains() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.b.c.d.kawasaki.jp".asURL!
        let expected = url.publicSuffix!
        XCTAssertEqual("d.kawasaki.jp", expected)
    }

    func testExceptionDomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = "http://city.kawasaki.jp".asURL!
        let expected = url.publicSuffix!
        XCTAssertEqual("kawasaki.jp", expected)
    }

    //MARK: Base Domain
    func testNormalBaseSubdomain() {
        // TLD Entry: co.uk
        let url = "http://bbc.co.uk".asURL!
        let expected = url.baseDomain!
        XCTAssertEqual("bbc.co.uk", expected)
    }

    func testNormalBaseSubdomainWithAdditionalSubdomain() {
        // TLD Entry: co.uk
        let url = "http://a.bbc.co.uk".asURL!
        let expected = url.baseDomain!
        XCTAssertEqual("bbc.co.uk", expected)
    }

    func testBaseDomainForWildcardDomain() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.b.kawasaki.jp".asURL!
        let expected = url.baseDomain!
        XCTAssertEqual("a.b.kawasaki.jp", expected)
    }

    func testBaseDomainForWildcardDomainWithAdditionalSubdomain() {
        // TLD Entry: *.kawasaki.jp
        let url = "http://a.b.c.kawasaki.jp".asURL!
        let expected = url.baseDomain!
        XCTAssertEqual("b.c.kawasaki.jp", expected)
    }

    func testBaseDomainForExceptionDomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = "http://city.kawasaki.jp".asURL!
        let expected = url.baseDomain!
        XCTAssertEqual("city.kawasaki.jp", expected)
    }

    func testBaseDomainForExceptionDomainWithAdditionalSubdomain() {
        // TLD Entry: !city.kawasaki.jp
        let url = "http://a.city.kawasaki.jp".asURL!
        let expected = url.baseDomain!
        XCTAssertEqual("city.kawasaki.jp", expected)
    }

    func testBugzillaURLDomain() {
        let url = "https://bugzilla.mozilla.org/enter_bug.cgi?format=guided#h=dupes|Data%20%26%20BI%20Services%20Team|"
        let nsURL = url.asURL
        XCTAssertNotNil(nsURL, "URL parses.")

        let host = nsURL!.normalizedHost
        XCTAssertEqual(host!, "bugzilla.mozilla.org")
        XCTAssertEqual(nsURL!.fragment!, "h=dupes%7CData%20%26%20BI%20Services%20Team%7C")
    }

    func testIPv6Domain() {
        let url = "http://[::1]/foo/bar".asURL!
        XCTAssertTrue(url.isIPv6)
        XCTAssertNil(url.baseDomain)
        XCTAssertEqual(url.normalizedHost!, "[::1]")
    }

    private func checkUrls(goodurls: [String], badurls: [String], checker: ((InternalURL) -> Bool)) {
        goodurls.forEach {
            var result = false
            if let url = InternalURL(URL(string:$0)!) { result = checker(url) }
            XCTAssertTrue(result)
        }
        badurls.forEach {
            var result = false
            if let url = InternalURL(URL(string:$0)!) { result = checker(url) }
            XCTAssertFalse(result)
        }
    }

    func testisAboutHomeURL() {
        let goodurls = [
            "\(InternalURL.baseUrl)/sessionrestore?url=\(InternalURL.baseUrl)/about/home%23panel%3D1",
            "\(InternalURL.baseUrl)/about/home#panel=0"
            ]
        let badurls = [
            "http://google.com",
            "http://localhost:\(AppInfo.webserverPort)/sessionrestore.html",
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html?url=http%3A//mozilla.com",
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html?url=http%3A//mozilla.com/about/home/%23panel%3D1",
            ]

        checkUrls(goodurls: goodurls, badurls: badurls, checker: { url in
            return url.isAboutHomeURL
        })
    }

    func testisAboutURL() {
        let goodurls = [
            "\(InternalURL.baseUrl)/about/home#panel=0",
            "\(InternalURL.baseUrl)/about/license"
        ]
        let badurls = [
            "http://google.com",
            "http://localhost:\(AppInfo.webserverPort)/sessionrestore.html",
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html?url=http%3A//mozilla.com",
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html?url=http%3A//mozilla.com/about/home/%23panel%3D1",
            ]

        checkUrls(goodurls: goodurls, badurls: badurls, checker: { url in
            return url.isAboutURL
        })
    }

    func testisErrorPage() {
        let goodurls = [
            "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//mozilla.com",
            ]
        let badurls = [
            "http://google.com",
            "http://localhost:\(AppInfo.webserverPort)/sessionrestore.html",
            "http://localhost:1234/about/home/#panel=0"
        ]

        checkUrls(goodurls: goodurls, badurls: badurls, checker: { url in
            return url.isErrorPage
        })
    }

    func testoriginalURLFromErrorURL() {
        let goodurls = [
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//mozilla.com", URL(string: "http://mozilla.com")),
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//localhost%3A\(AppInfo.webserverPort)/about/home/%23panel%3D1", URL(string: "http://localhost:\(AppInfo.webserverPort)/about/home/#panel=1")),
            ]

        goodurls.forEach {
            var result = false
            if let url = InternalURL(URL(string:$0.0)!) { result = (url.originalURLFromErrorPage == $0.1) }
            XCTAssertTrue(result)
        }
    }

    func testisReaderModeURL() {
        let goodurls = [
            "http://localhost:\(AppInfo.webserverPort)/reader-mode/page",
            "http://localhost:\(AppInfo.webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage",
            ]
        let badurls = [
            "http://google.com",
            "http://localhost:\(AppInfo.webserverPort)/sessionrestore.html",
            "http://localhost:1234/about/home/#panel=0"
        ]

        checkUrls(goodurls: goodurls, badurls: badurls) { url in
            return url.url.isReaderModeURL
        }
    }

    func testisSyncedReaderModeURL() {
        let goodurls = [
            "about:reader?url=",
            "about:reader?url=http://example.com",
            "about:reader?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage"
        ]
        let badurls = [
            "http://google.com",
            "http://localhost:\(AppInfo.webserverPort)/sessionrestore.html",
            "about:reader",
            "http://about:reader?url=http://example.com"
        ]

        goodurls.forEach { XCTAssertTrue(URL(string:$0)!.isSyncedReaderModeURL, $0) }
        badurls.forEach { XCTAssertFalse(URL(string:$0)!.isSyncedReaderModeURL, $0) }
    }

    func testdecodeReaderModeURL() {
        let goodurls = [
            ("http://localhost:\(AppInfo.webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage&uuidkey=AAAAA", URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")),
            ("about:reader?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage&uuidkey=AAAAA", URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")),
            ("about:reader?url=http%3A%2F%2Fexample%2Ecom%3Furl%3Dparam%26key%3Dvalue&uuidkey=AAAAA", URL(string: "http://example.com?url=param&key=value"))
        ]
        let badurls = [
            "http://google.com",
            "http://localhost:\(AppInfo.webserverPort)/sessionrestore.html",
            "http://localhost:1234/about/home/#panel=0",
            "http://localhost:\(AppInfo.webserverPort)/reader-mode/page",
            "about:reader?url="
        ]

        goodurls.forEach { XCTAssertEqual(URL(string:$0.0)!.decodeReaderModeURL, $0.1) }
        badurls.forEach { XCTAssertNil(URL(string:$0)!.decodeReaderModeURL, $0) }    }

    func testencodeReaderModeURL() {
        let ReaderURL = "http://localhost:\(AppInfo.webserverPort)/reader-mode/page"
        let goodurls = [
            ("https://en.m.wikipedia.org/wiki/Main_Page", URL(string: "http://localhost:\(AppInfo.webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage"))
            ]
        goodurls.forEach { XCTAssertEqual(URL(string:$0.0)!.encodeReaderModeURL(ReaderURL), $0.1) }
    }

    func testhavingRemovedAuthorisationComponents() {
        let goodurls = [
            ("https://Aladdin:OpenSesame@www.example.com/index.html", "https://www.example.com/index.html"),
            ("https://www.example.com/noauth", "https://www.example.com/noauth")
        ]

        goodurls.forEach { XCTAssertEqual(URL(string:$0.0)!.havingRemovedAuthorisationComponents().absoluteString, $0.1) }
    }

    func testschemeIsValid() {
        let goodurls = [
            "http://localhost:\(AppInfo.webserverPort)/reader-mode/page",
            "https://google.com",
            "tel:6044044004"
            ]
        let badurls = [
            "blah://google.com",
            "hax://localhost:\(AppInfo.webserverPort)/sessionrestore.html",
            "leet://codes.com"
        ]

        goodurls.forEach { XCTAssertTrue(URL(string:$0)!.schemeIsValid, $0) }
        badurls.forEach { XCTAssertFalse(URL(string:$0)!.schemeIsValid, $0) }
    }

    func testisWebPage() {
        let goodurls = [
            "http://localhost:\(AppInfo.webserverPort)/reader-mode/page",
            "https://127.0.0.1:\(AppInfo.webserverPort)/sessionrestore.html",
            "data://:\(AppInfo.webserverPort)/sessionrestore.html"

        ]
        let badurls = [
            "about://google.com",
            "tel:6044044004",
            "hax://localhost:\(AppInfo.webserverPort)/about"
        ]

        goodurls.forEach { XCTAssertTrue(URL(string:$0)!.isWebPage(), $0) }
        badurls.forEach { XCTAssertFalse(URL(string:$0)!.isWebPage(), $0) }
    }

    func testdomainURL() {
        let urls = [
            ("https://www.example.com/index.html", "https://example.com/"),
            ("https://mail.example.com/index.html", "https://mail.example.com/"),
            ("https://mail.example.co.uk/index.html", "https://mail.example.co.uk/"),
        ]
        urls.forEach { XCTAssertEqual(URL(string:$0.0)!.domainURL.absoluteString, $0.1) }
    }

    func testdisplayURL() {
        let goodurls = [
            ("http://localhost:\(AppInfo.webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2F", "https://en.m.wikipedia.org/wiki/"),
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//mozilla.com", "http://mozilla.com"),
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//mozilla.com", "http://mozilla.com"),
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A%2F%2Flocalhost%3A\(AppInfo.webserverPort)%2Freader-mode%2Fpage%3Furl%3Dhttps%253A%252F%252Fen%252Em%252Ewikipedia%252Eorg%252Fwiki%252F", "https://en.m.wikipedia.org/wiki/"),
            ("https://mail.example.co.uk/index.html", "https://mail.example.co.uk/index.html"),
        ]
        let badurls = [
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html?url=http%3A//localhost%3A\(AppInfo.webserverPort)/about/home/%23panel%3D1",
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html",

        ]

        goodurls.forEach { XCTAssertEqual(URL(string:$0.0)!.displayURL?.absoluteString, $0.1) }
        badurls.forEach { XCTAssertNil(URL(string:$0)!.displayURL) }
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
            "http://:\(AppInfo.webserverPort)/about/home",
        ]

        goodurls.forEach { XCTAssertEqual(URL(string:$0.0)!.normalizedHostAndPath, $0.1) }
        badurls.forEach { XCTAssertNil(URL(string:$0)!.normalizedHostAndPath) }
    }

    func testShortDisplayString() {
        let urls = [
            ("https://www.example.com/index.html", "example"),
            ("https://m.foo.com/bar/baz?noo=abc#123", "foo"),
            ("https://user:pass@m.foo.com/bar/baz?noo=abc#123", "foo"),
            ("https://accounts.foo.com/bar/baz?noo=abc#123", "accounts.foo"),
            ("https://accounts.what.foo.co.za/bar/baz?noo=abc#123", "accounts.what.foo"),

        ]
        urls.forEach { XCTAssertEqual(URL(string:$0.0)!.shortDisplayString, $0.1) }
    }

    func testorigin() {
        let urls = [
            ("https://www.example.com/index.html", "https://www.example.com"),
            ("https://user:pass@m.foo.com/bar/baz?noo=abc#123", "https://m.foo.com"),
        ]

        let badurls = [
            "data://google.com"
        ]
        urls.forEach { XCTAssertEqual(URL(string:$0.0)!.origin, $0.1) }
        badurls.forEach { XCTAssertNil(URL(string:$0)!.origin) }
    }

    func testhostPort() {
        let urls = [
            ("https://www.example.com", "www.example.com"),
            ("https://user:pass@www.example.com", "www.example.com"),
            ("http://localhost:6000/blah", "localhost:6000")
        ]

        let badurls = [
            "blah",
            "http://"
        ]
        urls.forEach { XCTAssertEqual(URL(string:$0.0)!.hostPort, $0.1) }
        badurls.forEach { XCTAssertNil(URL(string:$0)!.hostPort) }
    }

    func testgetQuery() {
        let url = URL(string: "http://example.com/path?a=1&b=2&c=3")!
        let params = ["a": "1", "b": "2", "c": "3"]

        let urlParams = url.getQuery()
        params.forEach { XCTAssertEqual(urlParams[$0], $1, "The values in params should be the same in urlParams") }
    }

    func testwithQueryParams() {
        let url = URL(string: "http://example.com/path")!
        let params = ["a": "1", "b": "2", "c": "3"]

        let newURL = url.withQueryParams(params.map { URLQueryItem(name: $0, value: $1) })

        //make sure the new url has all the right params.
        let newURLParams = newURL.getQuery()
        params.forEach { XCTAssertEqual(newURLParams[$0], $1, "The values in params should be the same in newURLParams") }
    }

    func testWithQueryParam() {
        let urlA = URL(string: "http://foo.com/bar/")!
        let urlB = URL(string: "http://bar.com/noo")!
        let urlC = urlA.withQueryParam("ppp", value: "123")
        let urlD = urlB.withQueryParam("qqq", value: "123")
        let urlE = urlC.withQueryParam("rrr", value: "aaa")

        XCTAssertEqual("http://foo.com/bar/?ppp=123", urlC.absoluteString)
        XCTAssertEqual("http://bar.com/noo?qqq=123", urlD.absoluteString)
        XCTAssertEqual("http://foo.com/bar/?ppp=123&rrr=aaa", urlE.absoluteString)
    }

    func testHidingFromDataDetectors() {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            XCTFail()
            return
        }

        let urls = ["https://example.com", "example.com", "http://example.com"]
        for u in urls {
            let url = URL(string: u)!

            let original = url.absoluteDisplayString
            let matches = detector.matches(in: original, options: [], range: NSMakeRange(0, original.count))
            guard matches.count > 0 else {
                print("\(url) doesn't match as a URL")
                continue
            }

            let modified = url.absoluteDisplayExternalString
            XCTAssertNotEqual(original, modified)

            let newMatches = detector.matches(in: modified, options: [], range: NSMakeRange(0, modified.count))

            XCTAssertEqual(0, newMatches.count, "\(modified) is not a valid URL")
        }

    }

}
