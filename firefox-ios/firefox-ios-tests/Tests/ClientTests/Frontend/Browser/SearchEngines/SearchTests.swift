// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import GCDWebServers
import UIKit
import XCTest

@testable import Client

class SearchTests: XCTestCase {
    func testURIFixup() {
        // Check valid URLs. We can load these after some fixup.
        checkValidURL("http://www.mozilla.org", afterFixup: "http://www.mozilla.org")
        checkValidURL("about:config", afterFixup: "about:config")
        checkValidURL("about: config", afterFixup: "about:%20config")
        checkValidURL("file:///f/o/o", afterFixup: "file:///f/o/o")
        checkValidURL("ftp://ftp.mozilla.org", afterFixup: "ftp://ftp.mozilla.org")
        checkValidURL("foo.bar", afterFixup: "http://foo.bar")
        checkValidURL(" foo.bar ", afterFixup: "http://foo.bar")
        checkValidURL("1.2.3", afterFixup: "http://1.2.3")

        // Check invalid URLs. These are passed along to the default search engine.
        checkInvalidURL("foobar")
        checkInvalidURL("foo bar")
        checkInvalidURL("mozilla. org")
        checkInvalidURL("123")
        checkInvalidURL("a/b")
        checkInvalidURL("创业咖啡")
        checkInvalidURL("创业咖啡 中国")
        checkInvalidURL("创业咖啡. 中国")
        checkInvalidURL("about:")
        checkInvalidURL("javascript:")
        checkInvalidURL("javascript:alert(%22hi%22)")
        checkInvalidURL("ftp:")
    }

    func testURIFixupPunyCode() {
        checkValidURL("http://创业咖啡.中国/", afterFixup: "http://xn--vhq70hq9bhxa.xn--fiqs8s/")
        checkValidURL("创业咖啡.中国", afterFixup: "http://xn--vhq70hq9bhxa.xn--fiqs8s")
        checkValidURL(" 创业咖啡.中国 ", afterFixup: "http://xn--vhq70hq9bhxa.xn--fiqs8s")
    }

    @MainActor
    func testSuggestClient() {
        let webServerBase = startMockSuggestServer()
        let engine = OpenSearchEngine(
            engineID: "mock",
            shortName: "Mock engine",
            telemetrySuffix: nil,
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "\(webServerBase)?q={searchTerms}",
            isCustomEngine: false)
        let client = SearchSuggestClient(searchEngine: engine, userAgent: "Fx-testSuggestClient")

        let query1 = self.expectation(description: "foo query")
        client.query("foo", callback: { response, error in
            withExtendedLifetime(client) {
                if error != nil {
                    XCTFail("Error: \(error?.description ?? "nil")")
                    query1.fulfill()
                    return
                }

                XCTAssertEqual(response![0], "foo")
                XCTAssertEqual(response![1], "foo2")
                XCTAssertEqual(response![2], "foo you")

                query1.fulfill()
            }
        })
        waitForExpectations(timeout: 10, handler: nil)

        let query2 = self.expectation(description: "foo bar query")
        client.query("foo bar", callback: { response, error in
            withExtendedLifetime(client) {
                if error != nil {
                    XCTFail("Error: \(error?.description ?? "nil")")
                    query2.fulfill()
                    return
                }

                XCTAssertEqual(response![0], "foo bar soap")
                XCTAssertEqual(response![1], "foo barstool")
                XCTAssertEqual(response![2], "foo bartender")

                query2.fulfill()
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
}

// MARK: - Helper
private extension SearchTests {
    func startMockSuggestServer() -> String {
        let webServer = GCDWebServer()

        webServer.addHandler(forMethod: "GET",
                             path: "/",
                             request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse? in
            var suggestions: [String]!
            let query = request.query!["q"]!
            switch query {
            case "foo":
                suggestions = ["foo", "foo2", "foo you"]
            case "foo bar":
                suggestions = ["foo bar soap", "foo barstool", "foo bartender"]
            default:
                XCTFail("Unexpected query: \(query)")
            }
            return GCDWebServerDataResponse(jsonObject: [query, suggestions as Any])
        }

        if !webServer.start(withPort: 0, bonjourName: nil) {
            XCTFail("Can't start the GCDWebServer")
        }

        return "http://localhost:\(webServer.port)"
    }

    func checkValidURL(_ beforeFixup: String, afterFixup: String) {
        XCTAssertEqual(URIFixup.getURL(beforeFixup)!.absoluteString, afterFixup)
    }

    func checkInvalidURL(_ beforeFixup: String) {
        XCTAssertNil(URIFixup.getURL(beforeFixup))
    }
}
