// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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

    private func checkUrls(goodurls: [String], badurls: [String], checker: (InternalURL) -> Bool) {
        goodurls.forEach {
            var result = false
            if let url = InternalURL(URL(string: $0)!) { result = checker(url) }
            XCTAssertTrue(result)
        }
        badurls.forEach {
            var result = false
            if let url = InternalURL(URL(string: $0)!) { result = checker(url) }
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
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//localhost%3A\(AppInfo.webserverPort)/about/home/%23panel%3D1",
             URL(string: "http://localhost:\(AppInfo.webserverPort)/about/home/#panel=1")),
            ]

        goodurls.forEach {
            var result = false
            if let url = InternalURL(URL(string: $0.0)!) { result = (url.originalURLFromErrorPage == $0.1) }
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

    func testhavingRemovedAuthorisationComponents() {
        let goodurls = [
            ("https://Aladdin:OpenSesame@www.example.com/index.html", "https://www.example.com/index.html"),
            ("https://www.example.com/noauth", "https://www.example.com/noauth")
        ]

        goodurls.forEach {
            XCTAssertEqual(
                URL(string: $0.0)!.havingRemovedAuthorisationComponents().absoluteString,
                $0.1
            )
        }
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

        goodurls.forEach { XCTAssertTrue(URL(string: $0)!.schemeIsValid, $0) }
        badurls.forEach { XCTAssertFalse(URL(string: $0)!.schemeIsValid, $0) }
    }

    func testdisplayURL() {
        let goodurls = [
            ("http://localhost:\(AppInfo.webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2F",
             "https://en.m.wikipedia.org/wiki/"),
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//mozilla.com",
             "http://mozilla.com"),
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A//mozilla.com",
             "http://mozilla.com"),
            ("\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage)?url=http%3A%2F%2Flocalhost%3A\(AppInfo.webserverPort)%2Freader-mode%2Fpage%3Furl%3Dhttps%253A%252F%252Fen%252Em%252Ewikipedia%252Eorg%252Fwiki%252F",
             "https://en.m.wikipedia.org/wiki/"),
            ("https://mail.example.co.uk/index.html",
             "https://mail.example.co.uk/index.html"),
        ]
        let badurls = [
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html?url=http%3A//localhost%3A\(AppInfo.webserverPort)/about/home/%23panel%3D1",
            "http://localhost:\(AppInfo.webserverPort)/errors/error.html",
        ]

        goodurls.forEach { XCTAssertEqual(URL(string: $0.0)!.displayURL?.absoluteString, $0.1) }
        badurls.forEach { XCTAssertNil(URL(string: $0)!.displayURL) }
    }

    func testwithQueryParams() {
        let url = URL(string: "http://example.com/path")!
        let params = ["a": "1", "b": "2", "c": "3"]

        let newURL = url.withQueryParams(params.map { URLQueryItem(name: $0, value: $1) })

        // make sure the new url has all the right params.
        let newURLParams = newURL.getQuery()
        params.forEach {
            XCTAssertEqual(
                newURLParams[$0],
                $1,
                "The values in params should be the same in newURLParams"
            )
        }
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
            let matches = detector.matches(
                in: original,
                options: [],
                range: NSRange(location: 0, length: original.count)
            )
            guard !matches.isEmpty else {
                continue
            }

            let modified = url.absoluteDisplayExternalString
            XCTAssertNotEqual(original, modified)

            let newMatches = detector.matches(
                in: modified,
                options: [],
                range: NSRange(location: 0, length: modified.count)
            )

            XCTAssertEqual(0, newMatches.count, "\(modified) is not a valid URL")
        }
    }
}
